import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../src.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _ringController;
  late AnimationController _shineController;
  late AnimationController _pathController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

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

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _masterController,
          curve: Interval(0.0, 0.2, curve: Curves.easeOutBack)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _masterController,
          curve: const Interval(0.0, 0.2, curve: Curves.easeIn)),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _masterController,
          curve: const Interval(0.4, 0.6, curve: Curves.easeIn)),
    );

    _masterController.forward();

    // Start drawing path after logo appears
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _pathController.forward();
    });

    // Auto-navigate after animation
    Future.delayed(const Duration(milliseconds: 4500), _decideNextRoute);
  }

  Future<void> _decideNextRoute() async {
    if (!mounted) return;

    // Dev override: bridge already reports itself as signed-in.
    if (AppConfig.devAuthEnabled) {
      Log.i('Splash', 'Dev auth on → BottomNavBar');
      await StorageService.setLoggedIn(true);
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.kBottomNavBar);
      }
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      await StorageService.setLoggedIn(false);
      // First-launch users get the welcome carousel before hitting
      // Login. The carousel itself flips the Hive flag, so this branch
      // never fires twice on the same device.
      final next =
          StorageService.hasSeenOnboarding ? Routes.kLogin : Routes.kOnboarding;
      Log.d('Splash', 'No Firebase user → $next');
      if (mounted) {
        Navigator.pushReplacementNamed(context, next);
      }
      return;
    }

    // Firebase signed in — make sure the Supabase bridge session is live.
    // If it isn't (cold start, or row was missing last time), re-run the
    // bridge exchange. On failure, fall back to Login so the user can
    // re-authenticate cleanly rather than landing in a broken state.
    try {
      final bridge = SupabaseAuthBridge.instance;
      final userId = await bridge.refreshIfNeeded();
      if (userId == null || !bridge.isSignedIn) {
        Log.w('Splash', 'Firebase user present but bridge unavailable → Login');
        await StorageService.setLoggedIn(false);
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.kLogin);
        }
        return;
      }
      Log.i('Splash', 'Session restored → BottomNavBar');
      await StorageService.setLoggedIn(true);
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.kBottomNavBar);
      }
    } catch (e) {
      Log.e('Splash', 'Bridge refresh failed: $e → Login');
      await StorageService.setLoggedIn(false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.kLogin);
      }
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _ringController.dispose();
    _shineController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background Layer ────────────────────────────────────────────────
          const _SplashBackground(),

          // ── Content Layer ───────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _masterController,
                  builder: (context, child) => Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: child,
                    ),
                  ),
                  child: _AnimatedLogo(
                    ringController: _ringController,
                    shineController: _shineController,
                    pathController: _pathController,
                  ),
                ),

                SizedBox(height: 32.h),

                // Brand Name
                FadeTransition(
                  opacity: _contentOpacity,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Safar',
                            style: Styles.splashBrandingSafar(context),
                          ),
                          Text(
                            'Share',
                            style: Styles.splashBrandingShare(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Container(
                        height: 1.5.h,
                        width: 180.w,
                        color: const Color(0xFFE8913A),
                      ),
                      SizedBox(height: 16.h),
                      // Tagline
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _taglineText('SHARE RIDE'),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Icon(Icons.circle,
                                size: 4.adaptSize,
                                color: const Color(0xFFE8913A)),
                          ),
                          _taglineText('BEAT TRAFFIC'),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 100.h),

                // Wavy Progress Dots
                FadeTransition(
                  opacity: _contentOpacity,
                  child: Column(
                    children: [
                      _WavyDotsProgress(),
                      SizedBox(height: 16.h),
                      Text(
                        'VERSION 1.0.0',
                        style: Styles.text11Medium(context,
                                textColor: AppColors.mediumGray)
                            .copyWith(letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taglineText(String text) {
    return Text(
      text,
      style: Styles.text11Semibold(context, textColor: AppColors.mediumGray)
          .copyWith(letterSpacing: 2.5),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Subtle Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.25),
                radius: 1.5,
                colors: [
                  Colors.white.withValues(alpha: 0.8),
                  Colors.white.withValues(alpha: 1.0),
                ],
              ),
            ),
          ),
        ),
        // Map Grid Pattern
        Positioned.fill(
          child: CustomPaint(
            painter: _MapGridPainter(),
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD3FAF0).withValues(alpha: 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height * 0.38);

    // Draw concentric circles
    for (double i = 60; i < size.height; i += 60) {
      canvas.drawCircle(center, i, paint);
    }

    // Draw radial lines
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final x2 = center.dx + math.cos(angle) * size.height;
      final y2 = center.dy + math.sin(angle) * size.height;
      canvas.drawLine(center, Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}

class _AnimatedLogo extends StatelessWidget {
  final AnimationController ringController;
  final AnimationController shineController;
  final AnimationController pathController;

  const _AnimatedLogo({
    required this.ringController,
    required this.shineController,
    required this.pathController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing Glow
        _PulsingGlow(),

        // Rotating Ring
        RotationTransition(
          turns: ringController,
          child: Transform.rotate(
            angle: 12 * math.pi / 180, // 12 degrees static tilt
            child: Container(
              width: 120.adaptSize,
              height: 120.adaptSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.adaptSize),
                border: Border.all(color: Colors.transparent, width: 2),
              ),
              child: CustomPaint(
                painter: _GradientBorderPainter(
                  gradient: AppColors.gradientMain,
                  radius: 30.adaptSize,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),

        // Logo Body
        Container(
          width: 104.adaptSize,
          height: 104.adaptSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2ECC71), Color(0xFF0D7C66)],
            ),
            borderRadius: BorderRadius.circular(26.adaptSize),
            border: Border.all(color: Colors.white70, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.adaptSize),
            child: Stack(
              children: [
                // Shine Sweep
                _ShineSweep(controller: shineController),

                // Path Drawing (The Needle)
                Center(
                  child: AnimatedBuilder(
                    animation: pathController,
                    builder: (context, _) => CustomPaint(
                      painter: _PathPainter(progress: pathController.value),
                      size: const Size(60, 60),
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

class _PulsingGlow extends StatefulWidget {
  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.4, end: 0.8)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 180.adaptSize,
          height: 180.adaptSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: _opacity.value),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShineSweep extends StatelessWidget {
  final AnimationController controller;
  const _ShineSweep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Transform.translate(
        offset: Offset(
          (controller.value * 200) - 100,
          (controller.value * 200) - 100,
        ),
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: Container(
            width: 200.w,
            height: 40.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.15),
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

class _PathPainter extends CustomPainter {
  final double progress;
  _PathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.8,
      size.height * 0.2,
    );

    final pathMetrics = path.computeMetrics().first;
    final extractPath =
        pathMetrics.extractPath(0, pathMetrics.length * progress);

    // Draw shadow for depth
    canvas.drawPath(
        extractPath,
        Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    canvas.drawPath(extractPath, paint);

    if (progress > 0.1) {
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
          Offset(size.width * 0.2, size.height * 0.7), 4, dotPaint);

      final pulsePaint = Paint()..color = Colors.white38;
      canvas.drawCircle(
          Offset(size.width * 0.2, size.height * 0.7), 7, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.progress != progress;
}

class _WavyDotsProgress extends StatefulWidget {
  @override
  State<_WavyDotsProgress> createState() => _WavyDotsProgressState();
}

class _WavyDotsProgressState extends State<_WavyDotsProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _WavyDotsPainter(progress: _controller.value),
        size: Size(200.w, 30.h),
      ),
    );
  }
}

class _WavyDotsPainter extends CustomPainter {
  final double progress;
  _WavyDotsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.fill;

    const numDots = 10;
    final spacing = size.width / (numDots + 1);

    for (int i = 0; i < numDots; i++) {
      final x = spacing * (i + 1);
      // Sine wave for dot size
      final angle = (progress * 2 * math.pi) + (i * 0.8);
      final factor = (math.sin(angle) + 1) / 2; // 0.0 to 1.0
      final radius = 2.0 + factor * 4.0;

      final opacity = 0.3 + factor * 0.7;
      paint.color = const Color(0xFF2ECC71).withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WavyDotsPainter old) => old.progress != progress;
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
