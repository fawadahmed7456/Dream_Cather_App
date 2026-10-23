import 'package:flutter/material.dart';
import 'package:safar_share/src/core/utils/size_utils.dart';

import '../../config/layout/sizes.dart';
import '../../config/theme/app_colors.dart';
import '../../extensions/context_extension.dart';

/// Standard empty state for a successful fetch that returned no rows.
/// If [onRefresh] is provided the widget wraps itself in a
/// [RefreshIndicator] so pull-to-refresh works.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.ctaLabel,
    this.onCtaTap,
    this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurface.withValues(alpha: 0.5);
    final secondary = context.colorScheme.onSurface.withValues(alpha: 0.7);

    final body = ListView(
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
        if (message != null) ...[
          SizedBox(height: 6.h),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.fSize, color: secondary),
          ),
        ],
        if (ctaLabel != null && onCtaTap != null) ...[
          SizedBox(height: Sizes.paddingL.h),
          Center(
            child: ElevatedButton(
              onPressed: onCtaTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Sizes.radiusM.adaptSize)),
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
              ),
              child: Text(ctaLabel!),
            ),
          ),
        ],
      ],
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh!,
        child: body,
      );
    }
    return body;
  }
}
