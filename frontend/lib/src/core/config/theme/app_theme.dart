import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/size_utils.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  // ── Shared helpers ──────────────────────────────────────────────────────────
  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.adaptSize),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBgMain,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.nearBlack,
        surfaceContainerHighest: AppColors.white,
        onSurfaceVariant: AppColors.slate,
        error: AppColors.danger,
        onError: AppColors.white,
        outline: AppColors.lightBorder,
      ),

      // ── Typography
      textTheme: GoogleFonts.outfitTextTheme()
          .copyWith(
            displayLarge: AppTextStyles.displayLarge,
            displayMedium: AppTextStyles.displayMedium,
            headlineLarge: AppTextStyles.headlineLarge,
            headlineMedium: AppTextStyles.headlineMedium,
            headlineSmall: AppTextStyles.headlineSmall,
            bodyLarge: AppTextStyles.bodyLarge,
            bodyMedium: AppTextStyles.bodyMedium,
            bodySmall: AppTextStyles.bodySmall,
            labelLarge: AppTextStyles.labelLarge,
            labelMedium: AppTextStyles.labelMedium,
            labelSmall: AppTextStyles.labelSmall,
          )
          .apply(
            bodyColor: AppColors.lightTextPrimary,
            displayColor: AppColors.lightTextPrimary,
          ),

      // ── App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBgMain,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),

      // ── Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.adaptSize),
          ),
          elevation: 0,
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.adaptSize),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Card
      cardTheme: CardThemeData(
        color: AppColors.lightBgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.adaptSize),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // ── Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBgInput,
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(AppColors.lightBorder),
        focusedBorder: _inputBorder(AppColors.primary),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.lightTextMuted,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
      ),

      // ── Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBgNav,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.lightTextMuted,
        ),
      ),

      // ── Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBgInput,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTextStyles.labelMedium,
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.adaptSize),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      ),

      // ── Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Icon
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.primary),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBgMain,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.white,
        surface: AppColors.darkBgCard,
        onSurface: AppColors.white,
        onSurfaceVariant: AppColors.darkTextSecondary,
        surfaceContainerHighest: AppColors.darkBgNav,
        error: AppColors.danger,
        onError: AppColors.white,
        outline: AppColors.darkBorder,
      ),

      // ── Typography
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: AppTextStyles.displayLarge,
            displayMedium: AppTextStyles.displayMedium,
            headlineLarge: AppTextStyles.headlineLarge,
            headlineMedium: AppTextStyles.headlineMedium,
            headlineSmall: AppTextStyles.headlineSmall,
            bodyLarge: AppTextStyles.bodyLarge,
            bodyMedium: AppTextStyles.bodyMedium,
            bodySmall: AppTextStyles.bodySmall,
            labelLarge: AppTextStyles.labelLarge,
            labelMedium: AppTextStyles.labelMedium,
            labelSmall: AppTextStyles.labelSmall,
          )
          .apply(
            bodyColor: AppColors.darkTextPrimary,
            displayColor: AppColors.darkTextPrimary,
          ),

      // ── App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBgMain,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),

      // ── Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.adaptSize),
          ),
          elevation: 0,
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.adaptSize),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Card
      cardTheme: CardThemeData(
        color: AppColors.darkBgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.adaptSize),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // ── Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBgInput,
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(AppColors.darkBorder),
        focusedBorder: _inputBorder(AppColors.primary),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextMuted,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),

      // ── Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBgNav,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.darkTextMuted,
        ),
      ),

      // ── Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBgInput,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.adaptSize),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      ),

      // ── Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Icon
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.primary),
    );
  }
}
