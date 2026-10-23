import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/utils/size_utils.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  const PhoneInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgInput : AppColors.white,
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          // Country Flag (Stubbed with Text/Placeholder)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.adaptSize),
            ),
            child: Row(
              children: [
                Text('🇵🇰', style: TextStyle(fontSize: 18.fSize)),
                SizedBox(width: 8.w),
                Text(
                  '+92',
                  style: AppTextStyles.text16Semibold(context),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.text16Semibold(context),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '12312313131',
                hintStyle: AppTextStyles.text16Normal(
                  context,
                  textColor: AppColors.mediumGray.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Icon(Icons.phone_outlined,
              color: AppColors.primary, size: 20.adaptSize),
        ],
      ),
    );
  }
}

class AuthGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const AuthGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradientMain,
        borderRadius: BorderRadius.circular(16.adaptSize),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.adaptSize),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: AppTextStyles.button.copyWith(color: AppColors.white),
                ),
                if (icon != null) ...[
                  SizedBox(width: 8.w),
                  Icon(icon, color: AppColors.white, size: 20.adaptSize),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(color: AppColors.lightGray),
        color: isDark ? AppColors.darkBgCard : AppColors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.adaptSize),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20.adaptSize),
              SizedBox(width: 12.w),
              Text(
                label,
                style: AppTextStyles.text14Semibold(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const TrustBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgCard : AppColors.white,
        borderRadius: BorderRadius.circular(16.adaptSize),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24.adaptSize),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.text10Semibold(
              context,
              textColor:
                  isDark ? AppColors.darkTextSecondary : AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;

  const OtpInputField({
    super.key,
    this.length = 4,
    required this.onChanged,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    String code = _controllers.map((e) => e.text).join();
    widget.onChanged(code);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 70.w,
          height: 70.h,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTextStyles.text24Bold(
              context,
              textColor: isDark ? AppColors.white : AppColors.black,
            ),
            decoration: InputDecoration(
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.adaptSize),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightGray,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.adaptSize),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              fillColor: isDark
                  ? AppColors.darkBgInput
                  : AppColors.primary.withValues(alpha: 0.05),
              filled: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => _onChanged(value, index),
          ),
        );
      }),
    );
  }
}
