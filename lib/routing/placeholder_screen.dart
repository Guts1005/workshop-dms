import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui_kit/tokens/app_tokens.dart';

class PhasePlaceholderScreen extends StatelessWidget {
  final int pageNumber;
  final String title;
  final String description;

  const PhasePlaceholderScreen({
    super.key,
    required this.pageNumber,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580.0),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                boxShadow: AppTokens.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTokens.inverse,
                      borderRadius: AppTokens.inputRadius,
                    ),
                    child: Text(
                      'SERVICE WORKSPACE',
                      style: GoogleFonts.inter(
                        color: AppTokens.textOnDark,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900,
                      color: AppTokens.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppTokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Container(height: 1.0, color: AppTokens.borderLight),
                  const SizedBox(height: 14.0),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16.0,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'We’ll show updates here as your application progresses.',
                          style: GoogleFonts.inter(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/applications');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  size: 14.0,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  'BACK TO APPLICATIONS',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      InkWell(
                        borderRadius: BorderRadius.circular(8.0),
                        onTap: () => context.go('/'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'HOME HUB',
                            style: GoogleFonts.inter(
                              color: AppTokens.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
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
