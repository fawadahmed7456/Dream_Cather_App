import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// A [AssetImageWidget] that displays an image from the assets folder.
class AssetImageWidget extends StatelessWidget {
  ///path of the image in the assets folder.
  final String path;

  /// width of the image.
  final double? width;

  /// height of the image.
  final double? height;

  /// color of the image.
  final Color? color;

  /// fit of the image.
  final BoxFit? fit;

  /// semanticLabel of the image.
  final String? semanticLabel;

  /// margin of the image.
  final EdgeInsets? margin;

  /// onTap callback when the image is tapped.
  final VoidCallback? onTap;

  ///[AssetImageWidget] constructor.
  const AssetImageWidget({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.color,
    this.fit,
    this.semanticLabel,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: path.toLowerCase().endsWith('.svg')
            ? SvgPicture.asset(
                path,
                width: width,
                height: height,
                colorFilter: color != null
                    ? ColorFilter.mode(color!, BlendMode.srcIn)
                    : null,
                fit: fit ?? BoxFit.contain,
              )
            : Image.asset(
                path,
                width: width,
                height: height,
                color: color,
                fit: fit,
              ),
      ),
    );
  }
}
