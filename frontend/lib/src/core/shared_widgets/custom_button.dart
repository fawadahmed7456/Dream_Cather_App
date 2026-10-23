import 'package:safar_share/src/src.dart';

/// A [CustomButton] widget that can be used throughout the app.
/// Supports solid colors and linear gradients.
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final bool enableBorder;
  final Color? borderColor;
  final Color? color;
  final bool useGradient;
  final LinearGradient? gradient;
  final Color? textColor;
  final double radius;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Widget? prefix;
  final Widget? suffix;
  final double? prefixSize;
  final double? suffixSize;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onTap,
    this.width,
    this.height = 48,
    this.radius = 12,
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.borderColor,
    this.color,
    this.useGradient = false,
    this.gradient,
    this.textColor = AppColors.white,
    this.enableBorder = false,
    this.prefix,
    this.suffix,
    this.prefixSize,
    this.suffixSize,
    this.isLoading = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final effectiveGradient = widget.useGradient
        ? (widget.gradient ?? AppColors.primaryGradient)
        : null;

    // Dynamically determine button color based on theme if not provided
    final effectiveColor = effectiveGradient == null
        ? (widget.color ??
            (isDark ? AppColors.primaryGreen : AppColors.primaryGreen))
        : null;

    // Determine text color for best contrast
    final effectiveTextColor = widget.textColor ?? AppColors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        padding: EdgeInsets.symmetric(horizontal: Sizes.paddingL.w),
        decoration: BoxDecoration(
          color: effectiveColor?.withValues(
            alpha: _isPressed ? 0.85 : 1.0,
          ),
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(widget.radius.adaptSize),
          border: widget.enableBorder
              ? Border.all(
                  color: widget.borderColor ?? context.colorScheme.outline,
                  width: 1.5,
                )
              : null,
          boxShadow: widget.onTap != null
              ? [
                  BoxShadow(
                    color: (effectiveGradient?.colors.first ??
                            effectiveColor ??
                            context.colorScheme.primary)
                        .withValues(alpha: _isPressed ? 0.3 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: widget.isLoading
            ? Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(effectiveTextColor),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.prefix != null) ...[
                    SizedBox(
                      width: widget.prefixSize,
                      height: widget.prefixSize,
                      child: widget.prefix,
                    ),
                    SizedBox(width: Sizes.paddingS.w),
                  ],
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.text,
                        style: Styles.text16Semibold(
                          context,
                          textColor: effectiveTextColor,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (widget.suffix != null) ...[
                    SizedBox(width: Sizes.paddingS.w),
                    SizedBox(
                      width: widget.suffixSize,
                      height: widget.suffixSize,
                      child: widget.suffix,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
