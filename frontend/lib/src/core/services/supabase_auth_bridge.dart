import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides current Supabase auth session token and user ID.
class SupabaseAuthBridge {
  /// Singleton instance
  static final SupabaseAuthBridge instance = SupabaseAuthBridge._();
  SupabaseAuthBridge._();

  /// Current Supabase session access token
  String? get accessToken {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  /// Current user UUID in Supabase
  String? get userId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Refreshes token if needed (for storage service compatibility)
  Future<String?> refreshIfNeeded() async {
    return accessToken;
  }

  /// Whether current user is signed in
  bool get isSignedIn => userId != null;
}
