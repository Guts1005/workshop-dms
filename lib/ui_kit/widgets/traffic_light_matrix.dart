import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

enum DiagnosticStatus {
  pass('PASS', AppTokens.green, Icons.check_circle_outline),
  advisory('ADVISORY', AppTokens.orange, Icons.error_outline),
  critical('CRITICAL', AppTokens.brandRed, Icons.cancel_outlined);

  final String label;
  final Color color;
  final IconData icon;

  const DiagnosticStatus(this.label, this.color, this.icon);
}

/// Multi-Point Diagnostic Traffic Light Matrix (Bucket 1: Token Composition)
/// Standardized Red / Amber / Green inspection selector adhering to strict token colors.
class TrafficLightItemRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final DiagnosticStatus? status;
  final ValueChanged<DiagnosticStatus> onStatusChanged;
  final bool isReadOnly;

  const TrafficLightItemRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onStatusChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.buttonRadius,
        border: Border.all(
          color: status != null
              ? status!.color.withValues(alpha: 0.35)
              : AppTokens.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTokens.fontBody(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            subtitle,
            style: AppTokens.fontBody(
              fontSize: 11.0,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: DiagnosticStatus.values.map((s) {
              final isSelected = status == s;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: isReadOnly ? null : () => onStatusChanged(s),
                    borderRadius: BorderRadius.circular(8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 7.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? s.color : AppTokens.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isSelected ? s.color : AppTokens.borderLight,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            s.icon,
                            size: 13.0,
                            color: isSelected ? Colors.white : s.color,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            s.label,
                            style: AppTokens.fontMonospace(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppTokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
