import 'package:flutter/material.dart';
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
    return Container(
      color: AppTokens.base,
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppTokens.raised,
            borderRadius: AppTokens.zeroRadius,
            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                color: AppTokens.inverse,
                child: Text(
                  'STAGE GATED: PAGE $pageNumber',
                  style: const TextStyle(
                    color: AppTokens.textOnDark,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: AppTokens.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                height: 1.0,
                color: AppTokens.dividerPassive,
              ),
              const SizedBox(height: 12.0),
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16.0, color: AppTokens.redOrange),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'LOCKED UNTIL PRIOR PAGE SIGN-OFF IN BUILD_PROGRESS.MD',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.redOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
