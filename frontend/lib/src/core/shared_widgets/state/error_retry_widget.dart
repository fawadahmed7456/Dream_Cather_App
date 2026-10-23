import 'package:flutter/material.dart';
import '../../utils/size_utils.dart';

import '../../config/layout/sizes.dart';
import '../../config/theme/app_colors.dart';
import '../../extensions/context_extension.dart';

/// Standard error state for a failed data fetch. Drop into the body of
/// a screen when [AppStateStatus.failure] is reached and there's no
/// stale data worth showing.
///
/// Wrapped in a scrollable so it composes with [RefreshIndicator]
/// without measurement issues.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.icon = Icons.error_outline_rounded,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurface.withValues(alpha: 0.5);
    final secondary = context.colorScheme.onSurface.withValues(alpha: 0.7);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
          horizontal: Sizes.paddingXL.w, vertical: Sizes.paddingXL.h),
      children: [
        SizedBox(height: 80.h),
        Icon(icon, size: 56.adaptSize, color: muted),
        SizedBox(height: Sizes.paddingM.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface),
        ),
        SizedBox(height: 6.h),
        Text(
          message ?? 'Please check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.fSize, color: secondary),
        ),
        SizedBox(height: Sizes.paddingL.h),
        Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: Text(retryLabel,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
