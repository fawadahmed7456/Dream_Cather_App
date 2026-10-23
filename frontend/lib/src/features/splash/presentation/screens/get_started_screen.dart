import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/utils/size_utils.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top curved brand section
          Expanded(
            flex: 5,
            child: ClipPath(
              clipper: _BottomCurveClipper(),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2CA8F5),
                      Color(0xFF289CEB),
                      Color(0xFF228BE0),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ask',
                          style: AppTextStyles.brandHero(context),
                        ),
                        Text(
                          'Asap',
                          style: AppTextStyles.brandHero(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom action section
          Expanded(
            flex: 4,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      'Anytime, Anywhere, Anyone',
                      style: AppTextStyles.text16Medium(
                        context,
                        textColor: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF4A4A4A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 28.h),

                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.kSignUp);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                          ),
                        ),
                        child: Text(
                          'Sign up',
                          style: AppTextStyles.primaryButton(context),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Already joined? Sign in
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already joined? ',
                          style: AppTextStyles.text14Normal(
                            context,
                            textColor: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, Routes.kLogin);
                          },
                          child: Text(
                            'Sign in',
                            style: AppTextStyles.linkText(context),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Terms & Privacy disclaimer
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Text(
                        'Tapping "Sign up" Or "Sign in" means you understand and accept Ask Asap\'s Privacy Policy and Terms of Service.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.text11Normal(
                          context,
                          textColor: isDark
                              ? AppColors.darkTextMuted
                              : const Color(0xFF8E8E93),
                        ).copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Curved shape clipper for the bottom of the top brand container
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 70.h);

    // Deep smooth curve upward then downward
    final firstControlPoint = Offset(size.width * 0.5, size.height + 40.h);
    final firstEndPoint = Offset(size.width, size.height - 70.h);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
