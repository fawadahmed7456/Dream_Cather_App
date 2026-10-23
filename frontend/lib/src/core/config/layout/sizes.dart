/// Design-system spacing, border radii, icon and button sizes.
///
/// Border radius names match the HTML CSS custom properties:
///   --radius-sm: 10px  --radius-md: 16px  --radius-lg: 24px  --radius-xl: 30px
class Sizes {
  const Sizes._();

  // ── Padding / Spacing ───────────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;
  static const double paddingXXXL = 32.0;

  // ── Border Radius ───────────────────────────────────────────────────────────
  /// --radius-sm: 10px
  static const double radiusSm = 10.0;

  /// --radius-md: 16px
  static const double radiusMd = 16.0;

  /// --radius-lg: 24px
  static const double radiusLg = 24.0;

  /// --radius-xl: 30px
  static const double radiusXl = 30.0;

  /// Fully rounded pill
  static const double radiusFull = 100.0;

  // ── Legacy aliases (kept for backwards-compat while migrating screens) ──────
  static const double radiusS = radiusSm;
  static const double radiusM = 12.0;
  static const double radiusL = radiusMd;
  static const double radiusXL = 20.0;
  static const double radiusXXL = radiusLg;

  // ── Icon Sizes ──────────────────────────────────────────────────────────────
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 48.0;

  // ── Avatar Sizes ────────────────────────────────────────────────────────────
  static const double avatarS = 32.0;
  static const double avatarM = 40.0;
  static const double avatarL = 56.0;
  static const double avatarXL = 80.0;

  // ── Button Heights ──────────────────────────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;
}
