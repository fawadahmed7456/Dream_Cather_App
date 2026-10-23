import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/utils/size_utils.dart';

class HouseRulesScreen extends StatelessWidget {
  const HouseRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.colorScheme.onSurface,
            size: 20.adaptSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Welcome to ',
                      style: AppTextStyles.authTitle(context),
                    ),
                    TextSpan(
                      text: 'Ask Asap',
                      style: AppTextStyles.authTitle(context).copyWith(
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please follow these House Rules.',
                style: AppTextStyles.authSubtitle(context),
              ),
              SizedBox(height: 32.h),

              Expanded(
                child: ListView(
                  children: [
                    _buildRule(
                      context,
                      title: 'Stay Safe',
                      body:
                          'Try to stay anonymous. Do not give out sensitive details such as your name, address, bank account, phone number, etc.',
                    ),
                    SizedBox(height: 24.h),
                    _buildRule(
                      context,
                      title: 'Respect Others',
                      body: 'Treat others how you want to be treated.',
                    ),
                    SizedBox(height: 24.h),
                    _buildRule(
                      context,
                      title: 'Be Vigilant',
                      body: 'Always report suspicious behaviour or activity.',
                    ),
                    SizedBox(height: 24.h),
                    _buildRule(
                      context,
                      title: 'Be Real',
                      body:
                          'Answer Ask Asap\'s questions honestly to ensure higher accuracy in matching.',
                    ),
                    SizedBox(height: 28.h),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'More on ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          TextSpan(
                            text: 'community guidelines.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // I Agree button
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.kOnboarding);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                    child: Text(
                      'I Agree',
                      style: AppTextStyles.primaryButton(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRule(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          body,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.lightTextSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
