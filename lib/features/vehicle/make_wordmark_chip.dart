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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.inverse : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppTokens.borderSolid, width: 1.0),
        ),
        alignment: Alignment.center,
        child: Text(
          make.toUpperCase(),
          style: TextStyle(
            color: isSelected ? AppTokens.textOnDark : AppTokens.textPrimary,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 13.0,
            letterSpacing: 1.2,
          ),
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
