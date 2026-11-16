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
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.inverse : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? AppTokens.redOrange : const Color(0xFFCCCCCC),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6.0,
                height: 6.0,
                color: AppTokens.redOrange,
              ),
              const SizedBox(width: 6.0),
            ],
            Text(
              make.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : AppTokens.textPrimary,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Popular Indian Automobile Manufacturers (Alphabetical)
const List<String> kIndianVehicleMakes = [
  'MARUTI SUZUKI',
  'HYUNDAI',
  'TATA MOTORS',
  'MAHINDRA',
  'TOYOTA',
  'KIA',
  'HONDA',
  'MG MOTOR',
  'VOLKSWAGEN',
  'SKODA',
  'RENAULT',
  'NISSAN',
  'JEEP',
  'FORD',
  'BMW',
  'MERCEDES-BENZ',
  'AUDI',
  'VOLVO',
  'BYD',
  'FORCE MOTORS',
];
