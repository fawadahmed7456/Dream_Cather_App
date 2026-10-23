import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/utils/size_utils.dart';

class EmailVerificationArgs {
  final String email;
  final String? password;

  const EmailVerificationArgs({
    required this.email,
    this.password,
  });
}

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? password;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.password,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-check every 5 seconds if password is available
    if (widget.password != null && widget.password!.isNotEmpty) {
      _timer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _checkVerificationSilently(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _attemptVerify() async {
    // 1. Try checking existing active session
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.emailConfirmedAt != null) {
        return true;
      }
    } catch (_) {}

    // 2. If password is available, try signing in to sync confirmation
    if (widget.password != null && widget.password!.isNotEmpty) {
      try {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: widget.email,
          password: widget.password!,
        );
        if (res.user?.emailConfirmedAt != null) {
          return true;
        }
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  Future<void> _checkVerificationSilently() async {
    final success = await _attemptVerify();
    if (success && mounted) {
      _timer?.cancel();
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.kHouseRules,
        (route) => false,
      );
    }
  }

  Future<void> _manualCheck() async {
    setState(() => _isChecking = true);
    final success = await _attemptVerify();
    if (!mounted) return;

    if (success) {
      _timer?.cancel();
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.kHouseRules,
        (route) => false,
      );
    } else {
      setState(() {
        _isChecking = false;
        _message =
            'Email not yet verified. Please tap the confirmation link in your email inbox, then try again.';
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (mounted) {
        setState(() {
          _isResending = false;
          _message = 'Verification email resent! Check your inbox or spam folder.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _message = 'Error resending: $e';
        });
      }
    }
  }

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
              SizedBox(height: 16.h),
              Container(
                width: 60.adaptSize,
                height: 60.adaptSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16.adaptSize),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: context.colorScheme.primary,
                  size: 32.adaptSize,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Verify your email',
                style: AppTextStyles.authTitle(context),
              ),
              SizedBox(height: 8.h),
              Text(
                'We have sent a verification link to:',
                style: AppTextStyles.authSubtitle(context),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.email,
                style: AppTextStyles.inputText(context).copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),

              // Informative note regarding the localhost redirect
              Container(
                padding: EdgeInsets.all(12.adaptSize),
                decoration: BoxDecoration(
                  color: AppColors.lightBgInput,
                  borderRadius: BorderRadius.circular(10.adaptSize),
                  border: Border.all(color: context.colorScheme.outline),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.colorScheme.primary,
                      size: 20.adaptSize,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Click "Confirm your email" in your inbox. Even if the browser shows "cannot connect to localhost", your email is confirmed! Then simply tap below.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.lightTextSecondary,
                          fontSize: 12.5.fSize,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_message != null) ...[
                SizedBox(height: 14.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.adaptSize),
                  decoration: BoxDecoration(
                    color: AppColors.lightTeal,
                    borderRadius: BorderRadius.circular(10.adaptSize),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Text(
                    _message!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.nearBlack,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Primary verification button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _manualCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                  ),
                  child: _isChecking
                      ? SizedBox(
                          width: 22.adaptSize,
                          height: 22.adaptSize,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "I've Verified My Email",
                          style: AppTextStyles.primaryButton(context),
                        ),
                ),
              ),
              SizedBox(height: 12.h),

              // Go to sign in button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pushReplacementNamed(context, Routes.kLogin);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
                    side: BorderSide(color: context.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                  ),
                  child: Text(
                    'Go to Sign In',
                    style: AppTextStyles.linkText(context),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Resend email button
              Center(
                child: TextButton(
                  onPressed: _isResending ? null : _resendEmail,
                  child: Text(
                    _isResending
                        ? 'Resending...'
                        : "Didn't receive an email? Resend",
                    style: AppTextStyles.authSubtitle(context),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
