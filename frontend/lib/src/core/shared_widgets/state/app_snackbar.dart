import 'package:flutter/material.dart';
import '../../utils/size_utils.dart';

import '../../config/theme/app_colors.dart';

/// Consistent snackbar surface for transient feedback. Use [error] for
/// failures, [success] for confirmations, [info] for neutral notices.
/// All variants float, round, and replace the current snackbar to
/// avoid stacking.
class AppSnackbar {
  const AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    Color? background,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: background ?? AppColors.primary,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.adaptSize)),
    ));
  }

  static void error(BuildContext context, String message) =>
      show(context, message, background: AppColors.red);

  static void success(BuildContext context, String message) =>
      show(context, message, background: AppColors.primaryGreen);

  static void info(BuildContext context, String message) =>
      show(context, message);
}
