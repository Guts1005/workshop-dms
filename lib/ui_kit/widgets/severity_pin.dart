import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

enum DefectSeverityLevel {
  l1('L1', 'Minor Scratch / Chip', AppTokens.orange),
  l2('L2', 'Panel Dent / Scrape', Color(0xFFEA580C)),
  l3('L3', 'Tear / Structural / Glass', AppTokens.brandRed);

  final String code;
  final String label;
  final Color color;

  const DefectSeverityLevel(this.code, this.label, this.color);
}

/// Symmetrical geometric severity pin for vehicle condition mapping.
/// - Exact circle with white border and drop shadow
/// - Symmetrical downward pointer
/// - Clean high-contrast typography
/// - Zero distorted paths or asymmetric artifacts
class SeverityPinWidget extends StatelessWidget {
  final DefectSeverityLevel level;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const SeverityPinWidget({
    super.key,
    required this.level,
    this.isSelected = false,
    this.onTap,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: level.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: level.color.withValues(alpha: isSelected ? 0.45 : 0.25),
                blurRadius: isSelected ? 8.0 : 4.0,
                spreadRadius: isSelected ? 3.0 : 0.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            level.code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        // Symmetrical triangle tip
        CustomPaint(
          size: const Size(8.0, 5.0),
          painter: _TriangleTipPainter(color: level.color),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: pin,
      );
    }
    return pin;
  }
}

class _TriangleTipPainter extends CustomPainter {
  final Color color;
  const _TriangleTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleTipPainter oldDelegate) =>
      oldDelegate.color != color;
}
