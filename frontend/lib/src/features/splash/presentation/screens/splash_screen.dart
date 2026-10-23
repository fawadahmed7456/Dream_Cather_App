import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routes/routes_constants.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../../core/utils/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Decide navigation after animation
    Timer(const Duration(milliseconds: 2200), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    // Request all permissions at once after splash
    await PermissionHelper.requestAppPermissions();
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Check if user has completed onboarding profile
      try {
        final res = await Supabase.instance.client
            .from('users')
            .select('id, username')
            .eq('id', session.user.id)
            .maybeSingle();

        if (res != null && (res['username'] as String? ?? '').isNotEmpty) {
          await StorageService.setLoggedIn(true);
          if (mounted) {
            Navigator.pushReplacementNamed(context, Routes.kBottomNavBar);
            return;
          }
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, Routes.kHouseRules);
            return;
          }
        }
      } catch (_) {
        // If query fails, fall back to GetStarted
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.kGetStarted);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ask',
                    style: GoogleFonts.fredoka(
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 0.9,
                    ),
                  ),
                  Text(
                    'Asap',
                    style: GoogleFonts.fredoka(
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dream Catcher',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
