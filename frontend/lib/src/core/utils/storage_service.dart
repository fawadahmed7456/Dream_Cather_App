import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _boxName = 'settings';
  static const String _themeKey = 'is_dark_theme';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userDataKey = 'user_data';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _supabaseTokenKey = 'supabase_token';
  static const String _supabaseUserIdKey = 'supabase_user_id';
  static const String _supabaseExpiryKey = 'supabase_expiry';
  static const String _readNotificationsKey = 'read_notification_ids';
  static const String _cachedUserNameKey = 'cached_user_name';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  // Theme management
  static bool? get isDarkTheme => _box.get(_themeKey) as bool?;

  static Future<void> setDarkTheme(bool isDark) async {
    await _box.put(_themeKey, isDark);
  }

  // Login status management
  static bool get isLoggedIn =>
      _box.get(_isLoggedInKey, defaultValue: false) as bool;

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await _box.put(_isLoggedInKey, isLoggedIn);
  }

  // User data management
  static Map<String, dynamic>? get userData {
    final data = _box.get(_userDataKey);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  static Future<void> setUserData(Map<String, dynamic> data) async {
    await _box.put(_userDataKey, data);
  }

  static Future<void> clearUserData() async {
    await _box.delete(_userDataKey);
    await _box.delete(_supabaseTokenKey);
    await _box.delete(_supabaseUserIdKey);
    await _box.delete(_supabaseExpiryKey);
    await _box.delete(_readNotificationsKey);
    await _box.delete(_cachedUserNameKey);
    await _box.put(_isLoggedInKey, false);
  }

  // Supabase Auth Bridge persistence
  static String? get supabaseToken => _box.get(_supabaseTokenKey) as String?;
  static String? get supabaseUserId => _box.get(_supabaseUserIdKey) as String?;
  static DateTime? get supabaseExpiry {
    final ms = _box.get(_supabaseExpiryKey) as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static Future<void> saveSupabaseSession({
    required String token,
    required String userId,
    required DateTime expiresAt,
  }) async {
    await _box.put(_supabaseTokenKey, token);
    await _box.put(_supabaseUserIdKey, userId);
    await _box.put(_supabaseExpiryKey, expiresAt.millisecondsSinceEpoch);
  }

  // Onboarding flag — true once the user has dismissed the welcome
  // carousel. Survives logout: the intro is a one-time first-launch
  // thing, not tied to the auth lifecycle.
  static bool get hasSeenOnboarding =>
      _box.get(_hasSeenOnboardingKey, defaultValue: false) as bool;

  static Future<void> setHasSeenOnboarding(bool value) async {
    await _box.put(_hasSeenOnboardingKey, value);
  }

  // Read-state for the (derived) notifications feed. We persist the ids the
  // user has already opened so the unread dot / counts survive restarts.
  static Set<String> get readNotificationIds {
    final raw = _box.get(_readNotificationsKey);
    if (raw is List) return raw.map((e) => e.toString()).toSet();
    return <String>{};
  }

  static Future<void> addReadNotifications(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final updated = readNotificationIds..addAll(ids);
    await _box.put(_readNotificationsKey, updated.toList());
  }

  // The signed-in user's display name, cached so the home greeting shows
  // their real name immediately on launch instead of flashing a placeholder
  // while the profile loads. Refreshed whenever the profile is fetched.
  static String? get cachedUserName => _box.get(_cachedUserNameKey) as String?;

  static Future<void> setCachedUserName(String name) async {
    await _box.put(_cachedUserNameKey, name);
  }

  // Clear all data (logout)
  static Future<void> logout() async {
    await clearUserData();
  }
}
