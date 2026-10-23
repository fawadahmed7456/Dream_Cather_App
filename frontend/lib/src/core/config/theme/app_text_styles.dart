import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
// Provides the real, device-aware `.fSize` extension (ResponsiveExtension).
// Replaces the previous no-op stub so all centralized text styles scale with
// the device once SizerUtils is mounted at the app root.
import '../../utils/size_utils.dart';

/// A utility class that defines text styles used throughout the application.
/// Each style specifies a font size and weight, with an optional color parameter.
/// If no color is provided, the style defaults to [AppColor.white] in dark mode
/// or [AppColor.black] in light mode based on the theme's brightness.
/// Styles are organized by font weight (Light, Normal, Medium, Semibold) and sorted by font size within each weight.
class Styles {
  const Styles._();

  // Light Weight (300)
  /// Text style with font size 12 and light weight (300).
  static TextStyle text12Light(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w300,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );
  // Normal Weight (400)
  /// Text style with font size 11 and normal weight (400).
  static TextStyle text11Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 11.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 10 and normal weight (400).
  static TextStyle text10Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 10.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 10 and medium weight (500).
  static TextStyle text10Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 10.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 12 and normal weight (400).
  static TextStyle text12Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 14 and normal weight (400).
  static TextStyle text14Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 14 and bold weight (700).
  static TextStyle text14Bold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w700,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 16 and normal weight (400).
  static TextStyle text16Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 20 and normal weight (400).
  static TextStyle text20Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 20 and bold weight (700).
  static TextStyle text20Bold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w700,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 24 and normal weight (400).
  static TextStyle text24Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 24.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 24 and bold weight (700).
  static TextStyle text24Bold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 24.fSize,
        fontWeight: FontWeight.w700,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 32 and normal weight (400).
  static TextStyle text32Normal(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 32.fSize,
        fontWeight: FontWeight.w400,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 42 and bold weight (700).
  static TextStyle text42Bold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 42.fSize,
        fontWeight: FontWeight.w700,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  // ── Branded Logo Styles ──────────────────────────────────────────────────
  /// Branded style for "Safar" in the splash logo.
  static TextStyle splashBrandingSafar(BuildContext context,
          {Color? textColor}) =>
      GoogleFonts.bebasNeue(
        fontSize: 44.fSize,
        fontWeight: FontWeight.w700,
        color: textColor ?? AppColors.nearBlack,
      );

  /// Branded style for "Share" in the splash logo.
  static TextStyle splashBrandingShare(BuildContext context,
          {Color? textColor}) =>
      GoogleFonts.bebasNeue(
        fontSize: 44.fSize,
        fontWeight: FontWeight.w700,
        color: textColor ?? AppColors.primary,
      );
  // Medium Weight (500)
  /// Text style with font size 12 and medium weight (500).
  static TextStyle text12Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 13 and medium weight (500).
  static TextStyle text13Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 13.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 14 and medium weight (500).
  static TextStyle text14Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 15 and medium weight (500).
  static TextStyle text15Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 15.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 11 and medium weight (500).
  static TextStyle text11Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 11.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 11 and semibold weight (600).
  static TextStyle text11Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 11.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 16 and medium weight (500).
  static TextStyle text16Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 19 and medium weight (500).
  static TextStyle text19Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 19.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 20 and medium weight (500).
  static TextStyle text20Medium(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w500,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );
  // Semibold Weight (600)

  /// Text style with font size 10 and semibold weight (600).
  static TextStyle text10Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 10.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 12 and semibold weight (600).
  static TextStyle text12Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 13 and semibold weight (600).
  static TextStyle text13Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 13.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 14 and semibold weight (600).
  static TextStyle text14Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 15 and semibold weight (600).
  static TextStyle text15Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 15.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 16 and semibold weight (600).
  static TextStyle text16Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 18 and semibold weight (600).
  static TextStyle text18Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 19 and semibold weight (600).
  static TextStyle text19Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 19.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 20 and semibold weight (600).
  static TextStyle text20Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.outfit(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 24 and semibold weight (600).
  static TextStyle text24Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 24.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Text style with font size 32 and semibold weight (600).
  static TextStyle text32Semibold(BuildContext context, {Color? textColor}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 32.fSize,
        fontWeight: FontWeight.w600,
        color: textColor ?? (Theme.of(context).colorScheme.onSurface),
      );

  /// Decoration for a containers linear gradient class.
  static LinearGradient linearGradient = LinearGradient(
    colors: [AppColor.teal.withValues(alpha: 0.20), AppColor.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0, 0.12],
  );

  // ── Compatibility Aliases for AppTextStyles (plural) ───────────────────────
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 32.fSize,
        fontWeight: FontWeight.w800,
      );
  static TextStyle get displayMedium => GoogleFonts.spaceGrotesk(
        fontSize: 26.fSize,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get headlineLarge => GoogleFonts.spaceGrotesk(
        fontSize: 22.fSize,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get headlineSmall => GoogleFonts.outfit(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get labelLarge => GoogleFonts.outfit(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelMedium => GoogleFonts.outfit(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 10.fSize,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 11.fSize,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
      );
}

typedef AppTextStyles = Styles;
