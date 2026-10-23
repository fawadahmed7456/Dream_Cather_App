import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/utils/size_utils.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(sl<AuthRepository>()),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    context.read<AuthCubit>().signIn(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.kBottomNavBar,
            (route) => false,
          );
        } else if (state.status == AuthStatus.needsEmailVerification) {
          Navigator.pushNamed(
            context,
            Routes.kEmailVerification,
            arguments: state.email ?? _emailController.text.trim(),
          );
        } else if (state.status == AuthStatus.needsOnboarding) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.kHouseRules,
            (route) => false,
          );
        } else if (state.status == AuthStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: context.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.h),
                    Text(
                      'Welcome back',
                      style: AppTextStyles.authTitle(context),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Sign in to your account with your email and password.',
                      style: AppTextStyles.authSubtitle(context),
                    ),
                    SizedBox(height: 36.h),

                    // Email input
                    Text(
                      'Email Address',
                      style: AppTextStyles.inputLabel(context),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.inputText(context),
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: AppTextStyles.inputHint(context),
                        filled: true,
                        fillColor: AppColors.lightBgInput,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(color: context.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(color: context.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(
                            color: context.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Password input
                    Text(
                      'Password',
                      style: AppTextStyles.inputLabel(context),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTextStyles.inputText(context),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: AppTextStyles.inputHint(context),
                        filled: true,
                        fillColor: AppColors.lightBgInput,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(color: context.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(color: context.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          borderSide: BorderSide(
                            color: context.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.lightTextSecondary,
                            size: 20.adaptSize,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 36.h),

                    // Sign In button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _onSignIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorScheme.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22.adaptSize,
                                height: 22.adaptSize,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Sign in',
                                style: AppTextStyles.primaryButton(context),
                              ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Don't have an account? Sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTextStyles.authSubtitle(context),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                                context, Routes.kSignUp);
                          },
                          child: Text(
                            'Sign up',
                            style: AppTextStyles.linkText(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
