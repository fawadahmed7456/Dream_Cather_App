import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger_utils.dart';
import '../models/user_profile.dart';

/// Repository handling authentication & profile persistence using Supabase.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String _tag = 'AuthRepository';

  /// Currently signed in Supabase user (if any).
  User? get currentAuthUser => _client.auth.currentUser;

  /// Whether a user is currently logged in.
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Checks if current user has confirmed their email.
  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  /// Sign up with email & password. Supabase sends a verification email automatically.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      Log.i(_tag, 'Signing up with email: $email');
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );
      Log.i(_tag, 'Sign up response: user=${res.user?.id}');
      return res;
    } on AuthException catch (e) {
      Log.e(_tag, 'SignUp AuthException: ${e.message}');
      throw e.message;
    } catch (e) {
      Log.e(_tag, 'SignUp unexpected error: $e');
      throw 'An error occurred during registration. Please try again.';
    }
  }

  /// Sign in with email & password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      Log.i(_tag, 'Signing in: $email');
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      Log.i(_tag, 'SignIn successful for user: ${res.user?.id}');
      return res;
    } on AuthException catch (e) {
      Log.e(_tag, 'SignIn AuthException: ${e.message}');
      throw e.message;
    } catch (e) {
      Log.e(_tag, 'SignIn unexpected error: $e');
      throw 'Failed to sign in. Please check your credentials.';
    }
  }

  /// Resends the signup email verification.
  Future<void> resendVerificationEmail(String email) async {
    try {
      Log.i(_tag, 'Resending verification email to $email');
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Failed to resend verification email.';
    }
  }

  /// Signs the user out.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      Log.e(_tag, 'SignOut error: $e');
    }
  }

  /// Checks whether a given username is already taken.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final trimmed = username.trim().toLowerCase();
      final res = await _client
          .from('users')
          .select('id')
          .eq('username', trimmed)
          .maybeSingle();
      return res == null;
    } catch (e) {
      Log.e(_tag, 'isUsernameAvailable check error: $e');
      // On error, let user proceed or recheck
      return true;
    }
  }

  /// Saves or updates the complete user profile into the `public.users` table.
  Future<UserProfile> saveUserProfile(UserProfile profile) async {
    try {
      Log.i(_tag, 'Saving user profile for ${profile.id} (@${profile.username})');
      final json = profile.toJson();
      final res = await _client
          .from('users')
          .upsert(json)
          .select()
          .single();
      Log.i(_tag, 'UserProfile saved successfully');
      return UserProfile.fromJson(res);
    } on PostgrestException catch (e) {
      Log.e(_tag, 'saveUserProfile Postgrest error: ${e.message} (${e.code})');
      throw e.message;
    } catch (e) {
      Log.e(_tag, 'saveUserProfile unexpected error: $e');
      throw 'Failed to save profile. Please try again.';
    }
  }

  /// Fetches a user profile by user UUID.
  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      final res = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return null;
      return UserProfile.fromJson(res);
    } catch (e) {
      Log.e(_tag, 'fetchUserProfile error: $e');
      return null;
    }
  }

  /// Checks whether the user has completed onboarding / profile creation.
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final profile = await fetchUserProfile(userId);
      return profile != null && profile.username.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
