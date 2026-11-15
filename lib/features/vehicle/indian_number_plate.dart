import 'package:flutter/material.dart';
import '../../ui_kit/tokens/app_tokens.dart';

/// Authentic Indian High Security Registration Plate (HSRP) widget
/// Styled with sharp geometry, authentic blue 'IND' strip, and bold monospace font.
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
    final plateBg = isCommercial ? const Color(0xFFFFD54F) : AppTokens.raised;
    final plateText = registrationNumber.trim().isEmpty ? 'MH 01 AB 1234' : _formatPlate(registrationNumber);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: plateBg,
        border: Border.all(color: AppTokens.borderSolid, width: 2.0),
      ),
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
                const Icon(Icons.circle, size: 8.0, color: Color(0xFFFFCC00)), // Chakra representation
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
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  plateText,
                  style: AppTokens.fontMonospace(
                    color: AppTokens.textPrimary,
                    fontSize: height * 0.44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
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
    if (clean.length >= 8) {
      // Standard format: RJ 27 CA 1024
      final state = clean.substring(0, 2);
      final rto = clean.length >= 4 ? clean.substring(2, 4) : clean.substring(2);
      final rest = clean.length >= 4 ? clean.substring(4) : '';
      return '$state $rto $rest'.trim();
    }
    return raw.toUpperCase();
  }
}
