import 'package:flutter/material.dart';
import 'package:safar_share/src/core/utils/size_utils.dart';

import '../../config/layout/sizes.dart';
import '../../config/theme/app_colors.dart';
import '../../extensions/context_extension.dart';

/// Solid-block placeholder used while data is loading. Cheap to render
/// and avoids the shimmer dependency. Use [LoadingSkeleton.listCard]
/// for list-style screens and [LoadingSkeleton.block] for one-off
/// content holes.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton._({
    required this.height,
    this.width,
    this.radius = 16,
  });

  final double height;
  final double? width;
  final double radius;

  factory LoadingSkeleton.block({
    double height = 80,
    double? width,
    double radius = 12,
  }) =>
      LoadingSkeleton._(height: height, width: width, radius: radius);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardTheme.color ?? context.colorScheme.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      height: height.h,
      width: width?.w,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius.adaptSize),
        border: Border.all(color: border),
      ),
    );
  }

  /// A vertically-padded list of placeholder cards. Drop into the body
  /// of a list screen while the first page is loading.
  static Widget listCard({int count = 4, double itemHeight = 180}) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Sizes.paddingXL.w, Sizes.paddingS.h,
          Sizes.paddingXL.w, Sizes.paddingXL.h),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: Sizes.paddingM.h),
      itemBuilder: (_, __) => LoadingSkeleton.block(height: itemHeight),
    );
  }
}
