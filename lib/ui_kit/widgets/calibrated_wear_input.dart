import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

/// Quantitative Calibrated Measurement Input (Bucket 1: Token Composition)
/// For entering physical workshop measurements (e.g. Brake Pad mm, Tyre Tread mm, Battery Volts/CCA)
/// with instant visual threshold health feedback.
class CalibratedWearInput extends StatelessWidget {
  final String label;
  final String unit;
  final double? value;
  final double criticalThreshold;
  final double advisoryThreshold;
  final ValueChanged<double?> onChanged;
  final bool isReadOnly;

  const CalibratedWearInput({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.criticalThreshold,
    required this.advisoryThreshold,
    required this.onChanged,
    this.isReadOnly = false,
  });

  Color _getHealthColor() {
    if (value == null) return AppTokens.textSecondary;
    if (value! <= criticalThreshold) return AppTokens.brandRed;
    if (value! <= advisoryThreshold) return AppTokens.orange;
    return AppTokens.green;
  }

  String _getHealthBadge() {
    if (value == null) return 'PENDING';
    if (value! <= criticalThreshold) return 'CRITICAL WEAR';
    if (value! <= advisoryThreshold) return 'ADVISORY';
    return 'HEALTHY';
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.buttonRadius,
        border: Border.all(
          color: value != null
              ? healthColor.withValues(alpha: 0.35)
              : AppTokens.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTokens.fontBody(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Row(
                  children: [
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: healthColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      _getHealthBadge(),
                      style: AppTokens.fontMonospace(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: healthColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 110.0,
            height: 38.0,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: AppTokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: AppTokens.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: value != null ? value.toString() : '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: !isReadOnly,
                    style: AppTokens.fontMonospace(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w900,
                      color: AppTokens.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '0.0',
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      onChanged(parsed);
                    },
                  ),
                ),
                Text(
                  unit,
                  style: AppTokens.fontMonospace(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
