import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/routes_constants.dart';

class HouseRulesScreen extends StatelessWidget {
  const HouseRulesScreen({super.key});

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
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Welcome to ',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    TextSpan(
                      text: 'Ask Asap',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF289CEB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please follow these House Rules.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: ListView(
                  children: [
                    _buildRule(
                      title: 'Stay Safe',
                      body:
                          'Try to stay anonymous. Do not give out sensitive details such as your name, address, bank account, phone number, etc.',
                    ),
                    const SizedBox(height: 24),
                    _buildRule(
                      title: 'Respect Others',
                      body: 'Treat others how you want to be treated.',
                    ),
                    const SizedBox(height: 24),
                    _buildRule(
                      title: 'Be Vigilant',
                      body: 'Always report suspicious behaviour or activity.',
                    ),
                    const SizedBox(height: 24),
                    _buildRule(
                      title: 'Be Real',
                      body:
                          'Answer Ask Asap\'s questions honestly to ensure higher accuracy in matching.',
                    ),
                    const SizedBox(height: 28),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'More on ',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                          TextSpan(
                            text: 'community guidelines.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF289CEB),
                              fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.kOnboarding);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF289CEB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'I Agree',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildRule({required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF767676),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
