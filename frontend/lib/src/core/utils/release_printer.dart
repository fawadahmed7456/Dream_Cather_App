import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// A utility class for logging messages in different build modes.
class AppLogger {
  /// Logs a message to the console or system log based on the build mode.
  static void log(String message, {String name = 'AppLogger'}) {
    if (kDebugMode) {
      // Debug mode → normal print
      // ignore: avoid_print
      print(message);
    } else {
      // Release/Profile mode → system log (survives tree-shaking)
      developer.log(message, name: name);
    }
  }
}
