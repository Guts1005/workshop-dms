import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

/// Calibrated Fuel Intake Gauge Slider (Bucket 1: Token Composition)
/// Allows workshop service advisors to record incoming vehicle fuel level:
/// 0% (E), 25% (1/4), 50% (1/2), 75% (3/4), 100% (F).
/// Built with strict token values: no custom gradients, no arbitrary colors.
class FuelIntakeSlider extends StatelessWidget {
  final double value; // 0.0 to 1.0 (snaps to 0.0, 0.25, 0.50, 0.75, 1.0)
  final ValueChanged<double> onChanged;
  final bool isReadOnly;
  final bool isConfirmed;

  const FuelIntakeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.isReadOnly = false,
    this.isConfirmed = true,
  });

  static const List<double> _steps = [0.0, 0.25, 0.50, 0.75, 1.0];
  static const List<String> _stepLabels = ['E', '1/4', '1/2', '3/4', 'F'];

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    final isLowFuel = isConfirmed && value <= 0.15;
    final displayValue = isConfirmed ? value.clamp(0.0, 1.0) : 0.0;
    final gaugeColor = isConfirmed
        ? (isLowFuel ? AppTokens.brandRed : AppTokens.inverse)
        : AppTokens.borderLight;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.borderLight),
        boxShadow: AppTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_gas_station_rounded,
                size: 16.0,
                color: isLowFuel ? AppTokens.brandRed : AppTokens.textPrimary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'FUEL LEVEL AT INTAKE',
                  style: AppTokens.fontMonospace(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: isLowFuel
                      ? const Color(0xFFFEE2E2)
                      : AppTokens.surfaceSubtle,
                  borderRadius: AppTokens.pillRadius,
                  border: Border.all(
                    color: isLowFuel
                        ? AppTokens.brandRed
                        : AppTokens.borderLight,
                  ),
                ),
                child: Text(
                  isConfirmed ? '$percent% TANK' : 'SELECT LEVEL',
                  style: AppTokens.fontMonospace(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: isLowFuel
                        ? AppTokens.brandRed
                        : AppTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Custom Discrete Step Bar
          LayoutBuilder(
            builder: (context, constraints) {
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8.0,
                  activeTrackColor: isLowFuel ? AppTokens.brandRed : gaugeColor,
                  inactiveTrackColor: AppTokens.surfaceSubtle,
                  thumbColor: isLowFuel ? AppTokens.brandRed : gaugeColor,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10.0,
                    elevation: 2.0,
                  ),
                  overlayColor: (isLowFuel ? AppTokens.brandRed : gaugeColor)
                      .withValues(alpha: 0.15),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 18.0,
                  ),
                  tickMarkShape: const RoundSliderTickMarkShape(
                    tickMarkRadius: 3.5,
                  ),
                  activeTickMarkColor: Colors.white,
                  inactiveTickMarkColor: AppTokens.borderSolid,
                ),
                child: Slider(
                  value: displayValue,
                  min: 0.0,
                  max: 1.0,
                  divisions: 4,
                  onChanged: isReadOnly ? null : onChanged,
                ),
              );
            },
          ),

          // Step Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_steps.length, (index) {
                final stepVal = _steps[index];
                final isSelected =
                    isConfirmed && (value - stepVal).abs() < 0.05;
                return InkWell(
                  onTap: isReadOnly ? null : () => onChanged(stepVal),
                  borderRadius: BorderRadius.circular(4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2.0,
                      horizontal: 4.0,
                    ),
                    child: Text(
                      _stepLabels[index],
                      style: AppTokens.fontMonospace(
                        fontSize: 9.5,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: isSelected
                            ? (isLowFuel && index == 0
                                  ? AppTokens.brandRed
                                  : AppTokens.textPrimary)
                            : AppTokens.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
