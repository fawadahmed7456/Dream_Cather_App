import 'package:flutter/material.dart';
import 'package:safar_share/l10n/app_localizations.dart';

/// Extension on [BuildContext] to provide easy access to commonly used
/// theme, media query, and screen size properties.
extension ContextExtension on BuildContext {
  /// - [theme]: Accesses the `ThemeData` associated with the current context.
  ThemeData get theme => Theme.of(this);

  /// - `textTheme`: Retrieves the `TextTheme` from the current theme for text styling.
  TextTheme get textTheme => theme.textTheme;

  /// - [colorScheme]: Retrieves the `ColorScheme` of the current theme, providing access to colors.
  ColorScheme get colorScheme => theme.colorScheme;

  /// - [locale]: Retrieves the `AppLocalizations` instance for localization.
  AppLocalizations get locale => AppLocalizations.of(this)!;

  /// - [isDarkMode]: Quick check for dark mode status.
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// - [screenWidth]: Shorthand for MediaQuery.of(context).size.width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// - [screenHeight]: Shorthand for MediaQuery.of(context).size.height
  double get screenHeight => MediaQuery.of(this).size.height;
}
