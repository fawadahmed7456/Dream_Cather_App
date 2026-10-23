import 'package:flutter/services.dart';

class AppInputFormatters {
  const AppInputFormatters._();

  /// Blocks characters not common in names (numbers, most symbols).
  /// Allows: letters, spaces, dots, and hyphens.
  static final name =
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s.-]"));

  /// Restricts to digits only.
  static final phone = FilteringTextInputFormatter.digitsOnly;

  /// Restricts to digits only (generic).
  static final numeric = FilteringTextInputFormatter.digitsOnly;

  /// Standard email character set.
  static final email =
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9@._-]"));

  /// Alphanumeric with spaces and hyphens.
  static final alphanumeric =
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s-]"));

  /// Standard phone number length limit (excluding country code).
  static const int phoneLimit = 10;
}

/// Simple formatter to force uppercase input.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
