import 'package:flutter/material.dart';

import '../../ui_kit/tokens/app_tokens.dart';

enum VehicleBodyType {
  hatchback('HATCHBACK'),
  sedan('SEDAN'),
  sub4mSuv('SUB-4M SUV'),
  midFullSuv('MID/FULL SUV'),
  mpv('MPV'),
  pickupVan('PICKUP / VAN'),
  generic('OTHER');

  final String label;
  const VehicleBodyType(this.label);
}

class VehicleSilhouettePainter extends CustomPainter {
  final VehicleBodyType bodyType;
  final Color strokeColor;

  const VehicleSilhouettePainter({
    required this.bodyType,
    this.strokeColor = AppTokens.borderSolid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Standardized proportions: Ground line at 88% height
    final groundY = h * 0.88;
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY), paint);

    // Wheels at 25% and 75% width, radius 12% height
    final wheelRadius = h * 0.12;
    final frontWheelCenter = Offset(w * 0.75, groundY - wheelRadius);
    final rearWheelCenter = Offset(w * 0.25, groundY - wheelRadius);

    // Wheel wells / circles
    canvas.drawCircle(frontWheelCenter, wheelRadius, paint);
    canvas.drawCircle(rearWheelCenter, wheelRadius, paint);

    final path = Path();

    switch (bodyType) {
      case VehicleBodyType.hatchback:
        // Rear bumper
        path.moveTo(w * 0.05, groundY - wheelRadius * 0.5);
        path.lineTo(w * 0.05, h * 0.55);
        // Steep hatchback glass to roof
        path.lineTo(w * 0.22, h * 0.28);
        path.lineTo(w * 0.55, h * 0.28); // Compact roof
        // Windshield
        path.lineTo(w * 0.72, h * 0.52);
        // Short bonnet & front bumper
        path.lineTo(w * 0.95, h * 0.58);
        path.lineTo(w * 0.95, groundY - wheelRadius * 0.5);
        break;

      case VehicleBodyType.sedan:
        // Extended boot / rear deck
        path.moveTo(w * 0.02, groundY - wheelRadius * 0.5);
        path.lineTo(w * 0.02, h * 0.58);
        path.lineTo(w * 0.18, h * 0.55); // Boot lid
        // Raked rear glass
        path.lineTo(w * 0.32, h * 0.30);
        path.lineTo(w * 0.60, h * 0.30); // Aerodynamic roof
        // Raked front windshield
        path.lineTo(w * 0.74, h * 0.55);
        // Long bonnet & front bumper
        path.lineTo(w * 0.98, h * 0.60);
        path.lineTo(w * 0.98, groundY - wheelRadius * 0.5);
        break;

      case VehicleBodyType.sub4mSuv:
        // Upright muscular tailgate
        path.moveTo(w * 0.04, groundY - wheelRadius * 0.5);
        path.lineTo(w * 0.04, h * 0.48);
        // Upright rear glass
        path.lineTo(w * 0.16, h * 0.22);
        path.lineTo(w * 0.60, h * 0.22); // Tall roofline
        // Upright windshield
        path.lineTo(w * 0.74, h * 0.48);
        // Flat aggressive bonnet
        path.lineTo(w * 0.96, h * 0.50);
        path.lineTo(w * 0.96, groundY - wheelRadius * 0.5);
        break;

      case VehicleBodyType.midFullSuv:
        // Boxy rear estate/cargo
        path.moveTo(w * 0.02, groundY - wheelRadius * 0.5);
        path.lineTo(w * 0.02, h * 0.42);
        path.lineTo(w * 0.12, h * 0.18);
        path.lineTo(w * 0.65, h * 0.18); // Extended full-size roof
        // Windshield
        path.lineTo(w * 0.76, h * 0.45);
        // Bold heavy bonnet & tall grille
        path.lineTo(w * 0.98, h * 0.48);
        path.lineTo(w * 0.98, groundY - wheelRadius * 0.5);
        break;

      case VehicleBodyType.mpv:
        // Monovolume wedge profile
        path.moveTo(w * 0.02, groundY - wheelRadius * 0.5);
        path.lineTo(w * 0.02, h * 0.40);
        path.lineTo(w * 0.14, h * 0.20);
        path.lineTo(w * 0.62, h * 0.20); // Long flat roof for 3 rows
        // Steep aerodynamic nose line
        path.lineTo(w * 0.88, h * 0.54);
        path.lineTo(w * 0.96, h * 0.62);
        path.lineTo(w * 0.96, groundY - wheelRadius * 0.5);
        break;

      case VehicleBodyType.pickupVan:
        // Flat commercial bed / rear box
        path.moveTo(w * 0.02, groundY - wheelRadius * 0.5);
        path.lineTo(w * 0.02, h * 0.55);
        path.lineTo(w * 0.42, h * 0.55); // Open cargo bed
        // Vertical cab rear glass
        path.lineTo(w * 0.42, h * 0.22);
        path.lineTo(w * 0.66, h * 0.22); // Cab roof
        path.lineTo(w * 0.76, h * 0.50);
        path.lineTo(w * 0.96, h * 0.54);
        path.lineTo(w * 0.96, groundY - wheelRadius * 0.5);
        break;

      case VehicleBodyType.generic:
        // Universal clean contour
        path.moveTo(w * 0.05, groundY - wheelRadius * 0.5);
        path.lineTo(w * 0.05, h * 0.55);
        path.lineTo(w * 0.20, h * 0.30);
        path.lineTo(w * 0.60, h * 0.30);
        path.lineTo(w * 0.75, h * 0.55);
        path.lineTo(w * 0.95, h * 0.58);
        path.lineTo(w * 0.95, groundY - wheelRadius * 0.5);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant VehicleSilhouettePainter oldDelegate) {
    return oldDelegate.bodyType != bodyType ||
        oldDelegate.strokeColor != strokeColor;
  }
}

class VehicleSilhouetteWidget extends StatelessWidget {
  final VehicleBodyType bodyType;
  final double width;
  final double height;
  final Color strokeColor;

  const VehicleSilhouetteWidget({
    super.key,
    required this.bodyType,
    this.width = 160.0,
    this.height = 70.0,
    this.strokeColor = AppTokens.borderSolid,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: VehicleSilhouettePainter(
          bodyType: bodyType,
          strokeColor: strokeColor,
        ),
      ),
    );
  }
}
