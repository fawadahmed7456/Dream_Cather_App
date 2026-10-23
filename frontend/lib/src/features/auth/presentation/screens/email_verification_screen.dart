import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routes/routes_constants.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

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
    // Periodically poll auth state every 4 seconds to detect when user clicked verify link
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    try {
      final res = await Supabase.instance.client.auth.getUser();
      if (res.user?.emailConfirmedAt != null) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.kHouseRules,
            (route) => false,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _manualCheck() async {
    setState(() => _isChecking = true);
    await _checkVerification();
    if (mounted) {
      setState(() {
        _isChecking = false;
        _message = 'Email not yet verified. Please click the link in your email inbox.';
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
          _message = 'Verification email resent! Check your spam folder if needed.';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF289CEB),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We have sent a verification email to:',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF289CEB),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please click the link inside to verify your account and continue setting up your profile.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF767676),
                  height: 1.45,
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    _message!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Check button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _manualCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF289CEB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "I've Verified My Email",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Resend email button
              Center(
                child: TextButton(
                  onPressed: _isResending ? null : _resendEmail,
                  child: Text(
                    _isResending
                        ? 'Resending...'
                        : "Didn't receive an email? Resend",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF289CEB),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
