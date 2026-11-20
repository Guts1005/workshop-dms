import 'package:flutter/material.dart';

import '../../ui_kit/tokens/app_tokens.dart';

class MakeWordmarkChip extends StatelessWidget {
  final String make;
  final bool isSelected;
  final VoidCallback? onTap;

  const MakeWordmarkChip({
    super.key,
    required this.make,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34.0,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.inverse : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isSelected ? AppTokens.brandRed : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTokens.inverse.withValues(alpha: 0.15),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    color: AppTokens.brandRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6.0),
              ],
              Text(
                make.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTokens.textPrimary,
                  fontFamily: 'monospace',
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11.0,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
