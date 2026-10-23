import '../../src.dart';

class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: Sizes.buttonHeight.h,
      decoration: BoxDecoration(
        gradient: AppColors.horizontalGradient,
        borderRadius: BorderRadius.circular(Sizes.radiusM.adaptSize),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.radiusM.adaptSize),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}
