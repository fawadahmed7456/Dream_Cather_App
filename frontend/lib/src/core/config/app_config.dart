/// Centralised configuration for the Dream Catcher app.
///
/// All environment-specific values (Supabase URL, keys, etc.) live here
/// so they're easy to find and swap between dev / staging / prod.
class AppConfig {
  const AppConfig._();

  // ─── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseUrl =
      'https://twbsionwzwwuzldvfdar.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_oHdVMvlByvF4VamCwc39zQ_REiq2Tpn';

  // ─── App identity ─────────────────────────────────────────────────────────
  static const String appName = 'Dream Catcher';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.dreamcatcher.app';

  // ─── Post media ────────────────────────────────────────────────────────────
  /// Max file size for post media uploads (10 MB).
  static const int maxPostMediaBytes = 10 * 1024 * 1024;

  /// Storage bucket for post media (images/videos).
  static const String postMediaBucket = 'post_media';

  /// Storage bucket for user profile avatars.
  static const String avatarBucket = 'avatars';

  // ─── Pagination ────────────────────────────────────────────────────────────
  /// Number of posts to fetch per page in the social feed.
  static const int postsPerPage = 10;

  /// Number of comments to fetch per page.
  static const int commentsPerPage = 20;

  // ─── Trending algorithm ────────────────────────────────────────────────────
  /// Weights used by the trending algorithm to score posts.
  /// score = (likes × likeWeight) + (comments × commentWeight) + (shares × shareWeight)
  /// The score is then time-decayed based on post age.
  static const double likeWeight = 1.0;
  static const double commentWeight = 2.0;
  static const double shareWeight = 3.0;

  /// Half-life for time decay in hours. Posts older than this lose relevance.
  static const double trendingHalfLifeHours = 24.0;

  // ─── Support / contact ─────────────────────────────────────────────────────
  static const String supportEmail = 'support@dreamcatcher.app';
  static const String termsUrl = 'https://dreamcatcher.app/terms';
  static const String privacyUrl = 'https://dreamcatcher.app/privacy';
}
