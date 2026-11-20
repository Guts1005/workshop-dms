import 'package:flutter/material.dart';

import '../../ui_kit/tokens/app_tokens.dart';

/// Authentic Indian High Security Registration Plate (HSRP) widget
/// Styled with subtle automotive rounding, authentic blue 'IND' strip, and bold typography.
class IndianNumberPlate extends StatelessWidget {
  final String registrationNumber;
  final double height;
  final double? width;
  final bool isCommercial; // Yellow plate for commercial vehicles

  const IndianNumberPlate({
    super.key,
    required this.registrationNumber,
    this.height = 48.0,
    this.width,
    this.isCommercial = false,
  });

  @override
  Widget build(BuildContext context) {
    final plateBg = isCommercial ? const Color(0xFFFFD54F) : Colors.white;
    final plateText = registrationNumber.trim().isEmpty
        ? 'MH 01 AB 1234'
        : _formatPlate(registrationNumber);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: plateBg,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blue IND strip
          Container(
            width: height * 0.75,
            height: height,
            color: const Color(0xFF003399),
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.circle,
                  size: 7.0,
                  color: Color(0xFFFFCC00),
                ), // Chakra representation
                const SizedBox(height: 2.0),
                Text(
                  'IND',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: height * 0.22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Plate text
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  plateText,
                  style: AppTokens.fontMonospace(
                    color: AppTokens.textPrimary,
                    fontSize: height * 0.44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlate(String raw) {
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    final match = RegExp(r'^([A-Z]{2})(\d{1,2})([A-Z]{0,3})(\d{1,4})$')
        .firstMatch(clean);
    if (match != null) {
      final state = match.group(1)!;
      final rto = match.group(2)!.padLeft(2, '0');
      final series = match.group(3) ?? '';
      final num = match.group(4) ?? '';
      return '$state $rto $series $num'.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    if (clean.length >= 8) {
      final state = clean.substring(0, 2);
      final rto = clean.length >= 4
          ? clean.substring(2, 4)
          : clean.substring(2);
      final rest = clean.length >= 4 ? clean.substring(4) : '';
      return '$state $rto $rest'.trim();
    }
    return raw.toUpperCase();
  }
}
