import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/logger_utils.dart';
import '../utils/storage_service.dart';

/// Exchanges a Firebase ID token for a Supabase JWT via the
/// `firebase-bridge` edge function. The returned JWT is what the rest of
/// the app uses as the Bearer token for Supabase Storage and REST calls,
/// so the storage/table RLS policies (keyed on auth.uid()) authorise the
/// request.
///
/// We intentionally do NOT call `Supabase.instance.client.auth.setSession`:
/// the Flutter SDK's setSession expects a refresh token, which the bridge
/// doesn't issue. Instead we cache the access token here and consumers
/// pass it to direct REST/Storage HTTP calls.
///
/// **Dev shortcut:** if [AppConfig.devAuthEnabled] is true, the bridge
/// short-circuits — it pretends a session already exists with the
/// hard-coded user id + token from AppConfig. No Firebase user is
/// needed in that mode.
class SupabaseAuthBridge {
  static const String _tag = 'AuthBridge';
  static const String _functionPath = '/functions/v1/firebase-bridge';

  /// Singleton instance — single source of truth for the cached session.
  static final SupabaseAuthBridge instance = SupabaseAuthBridge._();
  SupabaseAuthBridge._() {
    if (AppConfig.devAuthEnabled) {
      Log.w(_tag,
          'Dev auth ENABLED — bypassing Firebase OTP / bridge, using static token.');
    } else {
      // Restore cached session if any
      _accessToken = StorageService.supabaseToken;
      _userId = StorageService.supabaseUserId;
      _expiresAt = StorageService.supabaseExpiry;
      if (_accessToken != null) {
        Log.i(_tag,
            'Restored session for user=$_userId (expires at=$_expiresAt)');
      }
    }
  }

  String? _accessToken;
  String? _userId;
  DateTime? _expiresAt;

  /// Supabase access token (HS256 JWT minted by the bridge, OR the
  /// hard-coded one from AppConfig in dev mode). null until
  /// [signInAfterFirebase] runs at least once in prod mode.
  String? get accessToken {
    if (AppConfig.devAuthEnabled) return AppConfig.devSupabaseToken;
    final live = _expiresAt != null && _expiresAt!.isAfter(DateTime.now())
        ? _accessToken
        : null;
    return live;
  }

  /// public.users.id matching the JWT's sub claim. Use this as the
  /// storage path prefix and as the WHERE id = ... for users updates.
  String? get userId {
    if (AppConfig.devAuthEnabled) return AppConfig.devSupabaseUserId;
    return _userId;
  }

  bool get isSignedIn => accessToken != null && userId != null;

  /// Forces Firebase to mint a fresh ID token, exchanges it at the edge
  /// function, and caches the result. Throws on failure.
  ///
  /// In dev mode this is a no-op that returns the configured user id.
  Future<String> signInAfterFirebase() async {
    if (AppConfig.devAuthEnabled) {
      Log.i(_tag, 'signInAfterFirebase short-circuited (dev mode).');
      return AppConfig.devSupabaseUserId;
    }

    Log.i(_tag, 'signInAfterFirebase → exchanging Firebase ID token…');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Log.e(_tag, 'No Firebase user; call after signInWithCredential.');
      throw StateError('No Firebase user — call after signInWithCredential');
    }
    final firebaseToken = await user.getIdToken(true).timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw TimeoutException('Firebase getIdToken timed out after 30s'),
        );
    if (firebaseToken == null) {
      Log.e(_tag, 'Firebase returned a null ID token.');
      throw StateError('Firebase returned a null ID token');
    }

    final uri = Uri.parse('${AppConfig.supabaseUrl}$_functionPath');
    Log.d(_tag, 'POST $uri');
    final resp = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'firebase_id_token': firebaseToken}),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
            'firebase-bridge edge function timed out after 30s. '
            'Check network connectivity and Supabase edge function status.',
          ),
        );

    if (resp.statusCode != 200) {
      Log.e(_tag, 'Bridge failed (${resp.statusCode}): ${resp.body}');
      throw HttpException(
        'firebase-bridge failed (${resp.statusCode}): ${resp.body}',
      );
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = body['access_token'] as String?;
    final userId = body['user_id'] as String?;
    final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 3600;
    if (accessToken == null || userId == null) {
      Log.e(_tag, 'Bridge response missing access_token or user_id.');
      throw const FormatException('firebase-bridge response missing fields');
    }

    _accessToken = accessToken;
    _userId = userId;
    // Refresh 60s before real expiry to be safe.
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));

    await StorageService.saveSupabaseSession(
      token: _accessToken!,
      userId: _userId!,
      expiresAt: _expiresAt!,
    );

    Log.i(_tag, 'Bridge OK; user=$userId, token expires in ${expiresIn}s');
    return userId;
  }

  /// Refreshes the Supabase session by re-running the Firebase->bridge
  /// flow. Call when [accessToken] is null but the user is still
  /// authenticated with Firebase.
  Future<String?> refreshIfNeeded() async {
    if (AppConfig.devAuthEnabled) return AppConfig.devSupabaseUserId;
    if (accessToken != null) return _userId;
    if (FirebaseAuth.instance.currentUser == null) {
      Log.w(_tag, 'refreshIfNeeded: no Firebase user.');
      return null;
    }
    Log.d(_tag, 'refreshIfNeeded → re-running bridge exchange.');
    return signInAfterFirebase();
  }

  void clear() {
    Log.d(_tag, 'Clearing cached bridge session.');
    _accessToken = null;
    _userId = null;
    _expiresAt = null;
  }
}

class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
