import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Extension on `BuildContext` to simplify access to `MediaQuery` properties.
extension MediaQueryValues on BuildContext {
  /// Retrieves the `MediaQueryData` for the current context, which contains
  /// information about the device's screen and user preferences.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Retrieves the width of the screen.
  double get mediaWidth => mediaQuery.size.width;

  /// Retrieves the height of the screen.
  double get mediaHeight => mediaQuery.size.height;

  /// Checks if the device is considered a mobile device based on its width.
  /// Returns `true` if the screen width is less than 800 pixels.
  bool get isMobile => mediaWidth < 800;

  /// Checks if the device is considered a tablet based on its width.
  bool get isTablet => mediaWidth >= 600 && mediaWidth < 800;

  bool get isMobileDevice => mediaWidth < 600;

  /// Retrieves the size of the screen as a `Size` object.
  /// This includes both width and height.
  Size get size => mediaQuery.size;

  /// Retrieves the width of the screen from the `Size` object.
  double get width => size.width;

  /// Retrieves the height of the screen from the `Size` object.
  double get height => size.height;

  /// Retrieves the Target Platform.
  bool get isWebOrDesktop {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }
}
