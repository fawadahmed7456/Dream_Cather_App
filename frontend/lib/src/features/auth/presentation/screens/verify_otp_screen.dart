import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/layout/sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/enum/app_state_status_enum.dart';
import '../../../../core/utils/logger_utils.dart';
import '../../../../core/utils/size_utils.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

/// Arguments passed to [VerifyOTPScreen] via the router.
class VerifyOTPArgs {
  final String phoneNumber;
  // The SAME cubit that sent the OTP — carries the verificationId.
  final AuthCubit cubit;
  const VerifyOTPArgs({required this.phoneNumber, required this.cubit});
}

class VerifyOTPScreen extends StatelessWidget {
  final String phoneNumber;

  /// If supplied, this cubit is REUSED (carries the verificationId from the
  /// send-OTP step).  When null a fresh cubit is created as a fallback.
  final AuthCubit? existingCubit;

  const VerifyOTPScreen({
    super.key,
    required this.phoneNumber,
    this.existingCubit,
  });

  @override
  Widget build(BuildContext context) {
    if (existingCubit != null) {
      // Reuse the cubit that already holds the verificationId.
      return BlocProvider.value(
        value: existingCubit!,
        child: _VerifyOTPBody(phoneNumber: phoneNumber),
      );
    }
    // Fallback: use the DI singleton so we at least share the repository.
    return BlocProvider(
      create: (_) => AuthCubit(sl<AuthRepository>())..restorePhone(phoneNumber),
      child: _VerifyOTPBody(phoneNumber: phoneNumber),
    );
  }
}

class _VerifyOTPBody extends StatefulWidget {
  final String phoneNumber;
  const _VerifyOTPBody({required this.phoneNumber});

  @override
  State<_VerifyOTPBody> createState() => _VerifyOTPBodyState();
}

class _VerifyOTPBodyState extends State<_VerifyOTPBody>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  late AnimationController _anim;
  late Animation<double> _bounce;

  Timer? _timer;
  int _secs = 120;
  bool _verified = false, _loading = false, _error = false;
  bool _showBanner = true;
  int _resendCD = 0;

  String get _masked {
    final p = widget.phoneNumber;
    return p.length >= 7
        ? '${p.substring(0, 3)}****${p.substring(p.length - 4)}'
        : p;
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDeep => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard =>
      Theme.of(context).cardTheme.color ??
      Theme.of(context).colorScheme.surface;
  Color get _txt => Theme.of(context).colorScheme.onSurface;
  Color get _txtSec => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _txtMut =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
  Color get _brd =>
      Theme.of(context).dividerTheme.color ??
      (_isDark ? AppColors.darkBorder : AppColors.lightGray);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    _startTimer();
    _nodes[0].requestFocus();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _secs = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secs > 0) {
        if (mounted) setState(() => _secs--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _nodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _time =>
      '${_secs ~/ 60}:${(_secs % 60).toString().padLeft(2, '0')}';
  bool get _expired => _secs == 0;
  bool get _filled => _ctrls.every((c) => c.text.isNotEmpty);

  void _onDigit(int i, String v) {
    setState(() => _error = false);
    // Handle paste / SMS autofill — may receive all 6 digits at once.
    if (v.length > 1) {
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (int j = 0; j < digits.length && (i + j) < 6; j++) {
        _ctrls[i + j].text = digits[j];
      }
      // Move focus to last filled or last field.
      final lastIdx = (i + digits.length - 1).clamp(0, 5);
      _nodes[lastIdx].requestFocus();
      setState(() {});
      return;
    }
    if (v.length == 1 && i < 5) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
  }

  Future<String> _resolveNextRoute() async {
    try {
      final repo = sl<ProfileRepository>();
      final result = await repo.fetchCurrent();
      return result.fold(
        (_) => Routes.kBottomNavBar,
        (row) {
          final fullName = (row?['full_name'] as String?)?.trim() ?? '';
          if (row == null || fullName.isEmpty) {
            return Routes.kCompleteProfile;
          }
          return Routes.kBottomNavBar;
        },
      );
    } catch (e) {
      Log.w('VerifyOtp', 'New-user check failed: $e');
      return Routes.kBottomNavBar;
    }
  }

  void _verify(BuildContext context) {
    final otp = _ctrls.map((c) => c.text).join();
    if (otp.length == 6) {
      context.read<AuthCubit>().verifyOtp(otp);
    }
  }

  void _resend(BuildContext context) {
    if (_resendCD > 0) return;
    for (final c in _ctrls) {
      c.clear();
    }
    _nodes[0].requestFocus();
    context.read<AuthCubit>().resendOtp();
    _startTimer();
    setState(() {
      _error = false;
      _resendCD = 30;
      _showBanner = true;
    });
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCD > 0) {
        if (mounted) setState(() => _resendCD--);
      } else {
        t.cancel();
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state.status == AppStateStatus.success) {
          setState(() {
            _loading = false;
            _verified = true;
          });
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!context.mounted) return;

          // Decide where to land: new users (no row, or no full_name yet)
          // go through the one-time profile completion screen; everyone
          // else jumps straight to the bottom nav. A failed lookup
          // shouldn't block sign-in — fall back to bottom nav so the
          // user isn't stranded.
          final navigator = Navigator.of(context);
          final nextRoute = await _resolveNextRoute();
          if (!context.mounted) return;
          navigator.pushNamedAndRemoveUntil(nextRoute, (_) => false);
        }
        if (state.status == AppStateStatus.failure) {
          setState(() {
            _error = true;
            _loading = false;
          });
          if (!context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          final errorColor = Theme.of(context).colorScheme.error;
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Invalid OTP'),
              backgroundColor: errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bgDeep,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Sizes.paddingXL.w),
                child: Column(
                  children: [
                    SizedBox(height: Sizes.paddingS.h),
                    // Back
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38.w,
                          height: 38.h,
                          decoration: BoxDecoration(
                            color: _bgCard,
                            borderRadius: BorderRadius.circular(10.adaptSize),
                            border: Border.all(color: _brd),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16.adaptSize, color: _txt),
                        ),
                      ),
                    ),
                    SizedBox(height: Sizes.paddingL.h),
                    // Banner (auto-hides after 3s)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(
                          sizeFactor: anim,
                          axisAlignment: -1,
                          child: child,
                        ),
                      ),
                      child: _showBanner
                          ? Container(
                              key: const ValueKey('banner'),
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: Sizes.paddingL.w,
                                  vertical: Sizes.paddingM.h),
                              decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius:
                                      BorderRadius.circular(12.adaptSize)),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded,
                                      size: 18.adaptSize,
                                      color: AppColors.white),
                                  SizedBox(width: 8.w),
                                  Text('OTP sent to ${widget.phoneNumber}',
                                      style: TextStyle(
                                          fontSize: 13.fSize,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white)),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                    SizedBox(height: Sizes.paddingXXL.h),
                    // Shield
                    AnimatedBuilder(
                      animation: _bounce,
                      builder: (ctx, _) => Transform.translate(
                        offset: Offset(0, _bounce.value),
                        child: Container(
                          width: 56.w,
                          height: 56.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: Icon(Icons.shield_outlined,
                              size: 28.adaptSize, color: AppColors.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: Sizes.paddingXL.h),
                    Text('Verify OTP',
                        style: TextStyle(
                            fontSize: 22.fSize,
                            fontWeight: FontWeight.w700,
                            color: _txt)),
                    SizedBox(height: 6.h),
                    Text('We sent a 6-digit code to',
                        style: TextStyle(fontSize: 13.fSize, color: _txtSec)),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 14.adaptSize, color: _txtSec),
                        SizedBox(width: 4.w),
                        Text(_masked,
                            style: TextStyle(
                                fontSize: 14.fSize,
                                fontWeight: FontWeight.w600,
                                color: _txt)),
                      ],
                    ),
                    SizedBox(height: Sizes.paddingXXL.h),
                    // OTP Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, _buildField),
                    ),
                    SizedBox(height: Sizes.paddingL.h),
                    // Timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14.adaptSize,
                            color: _secs < 30 ? AppColors.accent : _txtMut),
                        SizedBox(width: 4.w),
                        Text(
                          _expired
                              ? 'Code expired. Request a new one.'
                              : 'OTP expires in $_time',
                          style: TextStyle(
                              fontSize: 12.fSize,
                              color: _secs < 30 ? AppColors.accent : _txtMut),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    SizedBox(height: Sizes.paddingXXL.h),
                    // Verify Btn
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        _loading = state.status == AppStateStatus.loading;
                        return _buildVerifyBtn(context);
                      },
                    ),
                    SizedBox(height: Sizes.paddingXXL.h),
                    Text("Didn't receive the code?",
                        style: TextStyle(fontSize: 13.fSize, color: _txtSec)),
                    SizedBox(height: Sizes.paddingS.h),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _resendCD == 0 ? () => _resend(context) : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 16.adaptSize,
                              color:
                                  _resendCD > 0 ? _txtMut : AppColors.primary),
                          SizedBox(width: 4.w),
                          Text(
                            _resendCD > 0
                                ? 'Resend in ${_resendCD}s'
                                : 'Resend OTP',
                            style: TextStyle(
                                fontSize: 13.fSize,
                                fontWeight: FontWeight.w600,
                                color: _resendCD > 0
                                    ? _txtMut
                                    : AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Sizes.paddingXL.h),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: Sizes.paddingL.w,
                            vertical: Sizes.paddingM.h),
                        decoration: BoxDecoration(
                          color: _bgCard,
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          border: Border.all(color: _brd),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('✏️', style: TextStyle(fontSize: 14.fSize)),
                            SizedBox(width: 6.w),
                            Text('Change phone number',
                                style: TextStyle(
                                    fontSize: 13.fSize,
                                    fontWeight: FontWeight.w500,
                                    color: _txtSec)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: Sizes.paddingXXXL.h),
                  ],
                ),
              ),
              if (_verified) _buildSuccess(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(int i) {
    final filled = _ctrls[i].text.isNotEmpty;
    // Flex each field so the six boxes always share the available row width
    // and never overflow on narrow devices (the box width auto-adapts).
    return Expanded(
      child: Container(
        height: 62.h,
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        child: TextField(
          controller: _ctrls[i],
          focusNode: _nodes[i],
          keyboardType: TextInputType.number,
          inputFormatters: [AppInputFormatters.numeric],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          maxLength: 1,
          style: TextStyle(
              fontSize: 26.fSize,
              fontWeight: FontWeight.w700,
              color: _error ? AppColors.white : _txt),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            contentPadding: EdgeInsets.zero,
            fillColor: _error
                ? AppColors.error.withValues(alpha: 0.8)
                : filled
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : _bgCard,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.adaptSize),
              borderSide: BorderSide(
                  color: _error
                      ? Theme.of(context).colorScheme.error
                      : (filled ? Theme.of(context).colorScheme.primary : _brd),
                  width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.adaptSize),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
          onChanged: (v) => _onDigit(i, v),
        ),
      ),
    );
  }

  Widget _buildVerifyBtn(BuildContext context) {
    final ok = _filled && !_expired && !_loading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ok ? () => _verify(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          gradient: ok ? AppColors.primaryGradient : null,
          color: ok ? null : _brd,
          borderRadius: BorderRadius.circular(14.adaptSize),
          boxShadow: ok
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white))
            else ...[
              Icon(Icons.shield_rounded,
                  size: 18.adaptSize, color: ok ? AppColors.white : _txtMut),
              SizedBox(width: 8.w),
              Text('Verify & Continue',
                  style: TextStyle(
                      fontSize: 14.fSize,
                      fontWeight: FontWeight.w600,
                      color: ok ? AppColors.white : _txtMut)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      color: Theme.of(context).shadowColor.withValues(alpha: 0.4),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (ctx, s, c) => Transform.scale(scale: s, child: c),
          child: Container(
            margin: EdgeInsets.all(40.w),
            padding: EdgeInsets.all(Sizes.paddingXXXL.w),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20.adaptSize),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_outline_rounded,
                      size: 40.adaptSize,
                      color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(height: Sizes.paddingXL.h),
                Text('Verified Successfully!',
                    style: TextStyle(
                        fontSize: 20.fSize,
                        fontWeight: FontWeight.w700,
                        color: _txt)),
                SizedBox(height: 6.h),
                Text('Welcome to SafarShare',
                    style: TextStyle(fontSize: 14.fSize, color: _txtSec)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
