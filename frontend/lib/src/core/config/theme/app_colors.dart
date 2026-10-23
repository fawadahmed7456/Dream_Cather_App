import 'package:flutter/material.dart';

/// This [AppColor] defines a set of colors used throughout the app.
/// A utility class that defines the color palette used throughout the application.
/// Each color is represented as a static constant with a descriptive name.
class AppColor {
  const AppColor._();

  /// Pure white color (#FFFFFF).
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black color (#000000).
  static const Color black = Color(0xFF000000);

  /// background color (#1B2126).
  static const Color background = Color(0xFF1B2126);

  /// Deep navy blue color (#192C83).
  static const Color navyBlue = Color(0xFF192C83);

  /// Dark gray color (#292B2D).
  static const Color darkGray = Color(0xFF292B2D);

  /// Bright teal color (#21E5B5).
  static const Color teal = Color(0xFF21E5B5);

  /// Light teal color (#D3FAF0).
  static const Color lightTeal = Color(0xFFD3FAF0);

  /// Vibrant emerald green color (#06E3A1).
  static const Color emerald = Color(0xFF06E3A1);

  /// Charcoal gray color (#1B2431).
  static const Color charcoal = Color(0xFF1B2431);

  /// Medium gray color (#757575).
  static const Color mediumGray = Color(0xFF757575);

  /// Light gray color (#E4E4E4).
  static const Color lightGray = Color(0xFFE4E4E4);

  /// Medium Light gray color (#B9B9B9).
  static const Color mediumLightGray = Color(0xFFB9B9B9);

  /// Green color (#00B69B).
  static const Color green = Color(0xFF00B69B);

  /// Very light gray color (#F5F6FA).
  static const Color veryLightGray = Color(0xFFF5F6FA);

  /// Bright red color (#EF3826).
  static const Color red = Color(0xFFEF3826);

  /// Light red color (#FEF4F5).
  static const Color lightRed = Color(0xFFFEF4F5);

  /// Cool gray color (#979797).
  static const Color coolGray = Color(0xFF979797);

  /// Silver gray color (#B1B1B1).
  static const Color silver = Color(0xFFB1B1B1);

  /// Pale gray color (#D5D5D5).
  static const Color paleGray = Color(0xFFD5D5D5);

  /// Off-white color (#FAFBFD).
  static const Color offWhite = Color(0xFFFAFBFD);

  /// Soft white color (#F9F9FB).
  static const Color softWhite = Color(0xFFF9F9FB);

  /// Bright pink color (#F93C65).
  static const Color pink = Color(0xFFF93C65);

  /// Slate blue-gray color (#313D4F).
  static const Color slate = Color(0xFF313D4F);

  /// Dark slate gray color (#565656).
  static const Color darkSlate = Color(0xFF565656);

  /// Muted gray color (#404040).
  static const Color mutedGray = Color(0xFF404040);

  /// Very pale gray color (#E0E0E0).
  static const Color veryPaleGray = Color(0xFFE0E0E0);

  /// Bright blue color (#4880FF).
  static const Color blue = Color(0xFF4880FF);
  static const Color info = blue;

  /// Royal blue color (#4379EE).
  static const Color royalBlue = Color(0xFF4379EE);

  /// Bright yellow color (#FEC53D).
  static const Color yellow = Color(0xFFFEC53D);

  /// Graphite gray color (#5C5C5C).
  static const Color graphite = Color(0xFF5C5C5C);

  /// Faint gray color (#F3F3F5).
  static const Color faintGray = Color(0xFFF3F3F5);

  /// Subtle gray color (#D9D9D9).
  static const Color subtleGray = Color(0xFFD9D9D9);

  /// Frosty gray color (#E9EDF0).
  static const Color frostyGray = Color(0xFFE9EDF0);

  /// Mid-tone gray color (#B5B5B5).
  static const Color midGray = Color(0xFFB5B5B5);

  /// Near-black color (#191919).
  static const Color nearBlack = Color(0xFF191919);

  /// Peach orange color (#FF9066).
  static const Color peach = Color(0xFFFF9066);

  /// Dark Primary color
  static const Color darkPrimary = Color(0xFF1B2126);

  /// orange color
  static const Color orange = Color(0xFFC96E00);

  /// Dark Scaffold background color
  static const Color darkScaffoldBackground = Color(0xFF131419);

  /// Semi-transparent white color
  static const Color semiGray = Color(0xB3FFFFFF);

  // ── Compatibility Aliases for AppColors (plural) ───────────────────────────
  static const Color primary = Color(0xFF2394DF); // Dream Catcher Vibrant Blue
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color accent = Color(0xFF2BA0F5);
  static const Color danger = red;
  static const Color success = green;
  static const Color warning = yellow;
  static const Color error = red;

  static const Color darkBgDeep = Color(0xFF0A1628);
  static const Color darkBgMain = Color(0xFF0F1D30);
  static const Color darkBgCard = Color(0xFF162A42);
  static const Color darkBgInput = Color(0xFF12233A);
  static const Color darkBgNav =
      Color(0xEB0F1D30); // 0.92 opacity approximation
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF8BA3BD);
  static const Color darkTextMuted = Color(0xFF5A7490);
  static const Color darkBorder = Color(0xFF1E3550);

  static const Color lightBgMain = white;
  static const Color lightBgCard = white;
  static const Color lightBgInput = Color(0xFFF7F8FA);
  static const Color lightBgNav = white;
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF767676);
  static const Color lightTextMuted = silver;
  static const Color lightBorder = Color(0xFFE5E7EB);

  static const Color scaffoldBackground = lightBgMain;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textLight = lightTextMuted;
  static const Color textWhite = white;
  static const Color starYellow = yellow;
  static const Color divider = lightBorder;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF26A0E5), Color(0xFF4AC2F7)],
  );

  static const LinearGradient gradientMain = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2394DF), Color(0xFF2BA0F5), Color(0xFF4AC2F7)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2BA0F5), Color(0xFF4AC2F7)],
  );

  static const LinearGradient findRideGradient = gradientMain;
  static const LinearGradient offerRideGradient = gradientMain;
  static const LinearGradient heroGradient = gradientMain;

  static const LinearGradient splashGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF26A0E5), Color(0xFF38B2F0), Color(0xFF52C6FA)],
  );

  static const LinearGradient splashGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F2B48), Color(0xFF1A4670), Color(0xFF0F2B48)],
  );

  // Backward-compat for plural AppColors references
  static const Color primaryGreen = primary;
  static const Color primaryBlue = accent;
  static const Color priceBadge = primary;
  static const Color verifiedBadge = accent;
  static const LinearGradient primaryGradient = gradientMain;
  static const LinearGradient horizontalGradient = gradientMain;
  static const Color shadow = Color(0x33000000);

  static const Color statsTripsBg = Color(0xFFD3FAF0);
  static const Color statsSavedBg = Color(0xFFFFF4E5);
  static const Color statsCO2Bg = Color(0xFFE8F5E9);
  static const Color statsTripsIcon = Color(0xFF0D7C66);
  static const Color statsSavedIcon = Color(0xFFE8913A);
  static const Color statsCO2Icon = Color(0xFF2ECC71);

  // Dark Stats Card Colors (Tinted)
  static const Color darkStatsTripsBg = Color(0xFF0D2D2A);
  static const Color darkStatsSavedBg = Color(0xFF2D2318);
  static const Color darkStatsCO2Bg = Color(0xFF152D1F);
}

// ── Plural Compatibility Alias ──
typedef AppColors = AppColor;
