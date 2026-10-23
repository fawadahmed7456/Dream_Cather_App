import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:safar_share/src/src.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(AuthRepository()),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _countryCode = '92';
  late AnimationController _controller;
  late AnimationController _ringController;
  late AnimationController _shineController;
  late AnimationController _pathController;
  String? _errorText;
  // Guards against pushing a second OTP screen when the shared cubit
  // re-emits `unauthenticated` (e.g. on Resend). Reset when the OTP screen
  // is popped so a fresh send navigates again.
  bool _otpScreenOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _pathController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _controller.dispose();
    _ringController.dispose();
    _shineController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgDeep => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard =>
      Theme.of(context).cardTheme.color ??
      Theme.of(context).colorScheme.surface;
  Color get _txtPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _txtSecondary => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _txtMuted =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
  Color get _btnColor => Theme.of(context).colorScheme.primary;
  Color get _inputBg =>
      Theme.of(context).inputDecorationTheme.fillColor ??
      (_isDark ? AppColors.darkBgInput : const Color(0xFFF1F5F9));
  Color get _borderColor =>
      Theme.of(context).dividerTheme.color ??
      (_isDark ? AppColors.darkBorder : AppColors.lightGray);

  void _onContinue(BuildContext context) {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorText = 'Please enter your full name');
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorText = 'Please enter a valid phone number');
      return;
    }

    setState(() => _errorText = null);
    final fullPhone = '+$_countryCode$phone';
    context.read<AuthCubit>().sendOtp(fullPhone, fullName: name);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state.status == AppStateStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'An error occurred'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
        // Navigate to the OTP screen exactly once. The same cubit drives both
        // this screen and the OTP screen, and Resend re-emits
        // `unauthenticated`, so without this guard every resend pushed a fresh
        // OTP screen on top of the current one.
        if (state.status == AppStateStatus.unauthenticated && !_otpScreenOpen) {
          _otpScreenOpen = true;
          await Navigator.pushNamed(
            context,
            Routes.kVerifyOTP,
            arguments: VerifyOTPArgs(
              phoneNumber: state.phoneNumber!,
              cubit: context.read<AuthCubit>(),
            ),
          );
          _otpScreenOpen = false;
        }
      },
      child: Scaffold(
        backgroundColor: _bgDeep,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: Sizes.paddingXL.w),
            child: Column(
              children: [
                SizedBox(height: 50.h),
                _buildBranding(),
                SizedBox(height: 40.h),
                _buildCreateAccountCard(),
                SizedBox(height: 30.h),
                _buildTermsFooter(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        _AnimatedLogoLogin(
          ringController: _ringController,
          shineController: _shineController,
          pathController: _pathController,
        ),
        SizedBox(height: 16.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 26.fSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
            children: [
              TextSpan(text: 'Safar', style: TextStyle(color: _txtPrimary)),
              TextSpan(text: 'Share', style: TextStyle(color: _btnColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(28.adaptSize),
        border:
            Border.all(color: _borderColor.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _btnColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.adaptSize),
                ),
                child: Icon(Icons.person_add_alt_1_rounded,
                    size: 22.adaptSize, color: _btnColor),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                          fontSize: 19.fSize,
                          fontWeight: FontWeight.w700,
                          color: _txtPrimary),
                    ),
                    Text(
                      'Join thousands of riders across Pakistan',
                      style:
                          TextStyle(fontSize: 12.fSize, color: _txtSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 28.h),
          _buildFieldLabel('FULL NAME'),
          SizedBox(height: 8.h),
          _buildTextField(
            controller: _nameController,
            hint: 'e.g. Ahmed Khan',
            icon: null,
          ),
          SizedBox(height: 20.h),
          _buildFieldLabel('PHONE NUMBER'),
          SizedBox(height: 8.h),
          _buildPhoneField(),
          if (_errorText != null) ...[
            SizedBox(height: 10.h),
            Text(_errorText!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.w500)),
          ],
          SizedBox(height: 32.h),
          _buildContinueButton(),
          SizedBox(height: 20.h),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 14.adaptSize, color: _txtMuted),
                SizedBox(width: 6.w),
                Text(
                  'Secured with end-to-end encryption',
                  style: TextStyle(
                      fontSize: 11.fSize,
                      color: _txtMuted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.fSize,
        fontWeight: FontWeight.w700,
        color: _txtMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12.adaptSize),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
            fontSize: 15.fSize,
            fontWeight: FontWeight.w600,
            color: _txtPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: _txtMuted.withValues(alpha: 0.6),
              fontSize: 14.fSize,
              fontWeight: FontWeight.w500),
          prefixIcon: icon != null
              ? Icon(icon, size: 18.adaptSize, color: _txtMuted)
              : null,
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
        ),
        inputFormatters: [AppInputFormatters.name],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12.adaptSize),
      ),
      child: IntlPhoneField(
        controller: _phoneController,
        initialCountryCode: 'PK',
        showCountryFlag: true,
        showDropdownIcon: true,
        dropdownIcon: Icon(Icons.arrow_drop_down_rounded, color: _txtMuted),
        dropdownIconPosition: IconPosition.trailing,
        flagsButtonPadding: EdgeInsets.only(left: 14.w),
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
            fontSize: 15.fSize,
            fontWeight: FontWeight.w600,
            color: _txtPrimary,
            letterSpacing: 1),
        dropdownTextStyle: TextStyle(
            fontSize: 15.fSize,
            fontWeight: FontWeight.w700,
            color: _txtPrimary),
        decoration: InputDecoration(
          hintText: '3XX XXXXXXX',
          hintStyle: TextStyle(
              color: _txtMuted.withValues(alpha: 0.6),
              fontSize: 14.fSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5),
          border: InputBorder.none,
          counterText: '',
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
        ),
        inputFormatters: [
          AppInputFormatters.phone,
          LengthLimitingTextInputFormatter(AppInputFormatters.phoneLimit),
        ],
        onChanged: (phone) {
          setState(() {
            _countryCode = phone.countryCode.replaceAll('+', '');
          });
        },
        onCountryChanged: (country) {
          setState(() {
            _countryCode = country.dialCode;
          });
        },
      ),
    );
  }

  Widget _buildContinueButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AppStateStatus.loading;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isLoading ? null : () => _onContinue(context),
          child: Container(
            width: double.infinity,
            height: 54.h,
            decoration: BoxDecoration(
              color: _btnColor,
              borderRadius: BorderRadius.circular(16.adaptSize),
              boxShadow: [
                BoxShadow(
                  color: _btnColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.h,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.fSize,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18.adaptSize),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
              fontSize: 12.fSize,
              color: _txtSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms',
              style: TextStyle(color: _btnColor, fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(color: _btnColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLogoLogin extends StatelessWidget {
  final AnimationController ringController;
  final AnimationController shineController;
  final AnimationController pathController;

  const _AnimatedLogoLogin({
    required this.ringController,
    required this.shineController,
    required this.pathController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Scaling ring down and using theme colors
        RotationTransition(
          turns: ringController,
          child: Transform.rotate(
            angle: 12 * 3.14159 / 180,
            child: Container(
              width: 90.w,
              height: 90.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.adaptSize),
                border: Border.all(color: Colors.transparent, width: 1.5),
              ),
              child: CustomPaint(
                painter: _GradientBorderPainter(
                  gradient: AppColors.gradientMain,
                  radius: 20.adaptSize,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Logo Body scaled to 42x42
        Container(
          width: 65.w,
          height: 65.h,
          decoration: BoxDecoration(
            gradient: AppColors.gradientMain,
            borderRadius: BorderRadius.circular(12.adaptSize),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.adaptSize),
            child: Stack(
              children: [
                _ShineSweepLogin(controller: shineController),
                Center(
                  child: AnimatedBuilder(
                    animation: pathController,
                    builder: (context, _) => CustomPaint(
                      painter: _PathPainterLogin(
                        progress: pathController.value,
                        accentColor: Theme.of(context).colorScheme.secondary,
                      ),
                      size: Size(40.w, 40.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShineSweepLogin extends StatelessWidget {
  final AnimationController controller;
  const _ShineSweepLogin({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Transform.translate(
        offset: Offset(
          (controller.value * 100) - 50,
          (controller.value * 100) - 50,
        ),
        child: Transform.rotate(
          angle: -3.14159 / 4,
          child: Container(
            width: 100.w,
            height: 20.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PathPainterLogin extends CustomPainter {
  final double progress;
  final Color accentColor;
  _PathPainterLogin({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.8,
      size.height * 0.2,
    );

    final pathMetrics = path.computeMetrics().first;
    final extractPath =
        pathMetrics.extractPath(0, pathMetrics.length * progress);

    canvas.drawPath(extractPath, paint);

    if (progress > 0.95) {
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
          Offset(size.width * 0.2, size.height * 0.8), 2, dotPaint);

      final pulsePaint = Paint()..color = accentColor;
      canvas.drawCircle(
          Offset(size.width * 0.8, size.height * 0.2), 2, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(_PathPainterLogin old) => old.progress != progress;
}

class _GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double radius;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.gradient,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) => false;
}
