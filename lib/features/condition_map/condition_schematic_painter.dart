import 'package:flutter/material.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'condition_map_models.dart';

/// 1px CAD Orthographic Schematic Painter for Vehicle Condition Inspection.
/// Features 5 distinct engineering views:
/// - Left Side Profile
/// - Right Side Profile
/// - Front Nose
/// - Rear Tail
/// - Top / Aerial Roof
class ConditionSchematicPainter extends CustomPainter {
  final ConditionViewDirection view;
  final bool isLocked;

  const ConditionSchematicPainter({required this.view, this.isLocked = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Background CAD Micro-Grid (24px spacing)
    _drawCadGrid(canvas, size);

    final linePaint = Paint()
      ..color = AppTokens.inverse.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final seamPaint = Paint()
      ..color = AppTokens.textSecondary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = AppTokens.surface.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    switch (view) {
      case ConditionViewDirection.sideLeft:
        _drawSideProfile(
          canvas,
          size,
          linePaint,
          seamPaint,
          fillPaint,
          isLeft: true,
        );
        break;
      case ConditionViewDirection.sideRight:
        _drawSideProfile(
          canvas,
          size,
          linePaint,
          seamPaint,
          fillPaint,
          isLeft: false,
        );
        break;
      case ConditionViewDirection.front:
        _drawFrontView(canvas, size, linePaint, seamPaint, fillPaint);
        break;
      case ConditionViewDirection.rear:
        _drawRearView(canvas, size, linePaint, seamPaint, fillPaint);
        break;
      case ConditionViewDirection.top:
        _drawTopView(canvas, size, linePaint, seamPaint, fillPaint);
        break;
    }
  }

  void _drawCadGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTokens.borderSolid.withOpacity(0.35)
      ..strokeWidth = 0.5;

    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawSideProfile(
    Canvas canvas,
    Size size,
    Paint line,
    Paint seam,
    Paint fill, {
    required bool isLeft,
  }) {
    final w = size.width;
    final h = size.height;

    // Ground reference baseline
    canvas.drawLine(
      Offset(w * 0.04, h * 0.82),
      Offset(w * 0.96, h * 0.82),
      seam,
    );

    final bodyPath = Path();
    if (isLeft) {
      // Left side: Nose pointing right, boot/tail on left
      bodyPath.moveTo(w * 0.08, h * 0.70); // Rear bumper bottom
      bodyPath.lineTo(w * 0.06, h * 0.52); // Rear bumper top
      bodyPath.lineTo(w * 0.20, h * 0.50); // Trunk deck
      bodyPath.lineTo(w * 0.32, h * 0.26); // Rear glass
      bodyPath.lineTo(w * 0.65, h * 0.26); // Roofline
      bodyPath.lineTo(w * 0.78, h * 0.48); // Windshield
      bodyPath.lineTo(w * 0.94, h * 0.52); // Bonnet nose
      bodyPath.lineTo(w * 0.94, h * 0.70); // Front bumper bottom
      bodyPath.lineTo(w * 0.78, h * 0.70); // Front wheel arch right
      bodyPath.arcToPoint(
        Offset(w * 0.66, h * 0.70),
        radius: Radius.circular(w * 0.06),
        clockwise: false,
      );
      bodyPath.lineTo(w * 0.38, h * 0.70); // Under-door rocker sill
      bodyPath.arcToPoint(
        Offset(w * 0.26, h * 0.70),
        radius: Radius.circular(w * 0.06),
        clockwise: false,
      );
      bodyPath.close();
    } else {
      // Right side: Nose pointing left, boot on right
      bodyPath.moveTo(w * 0.92, h * 0.70);
      bodyPath.lineTo(w * 0.94, h * 0.52);
      bodyPath.lineTo(w * 0.80, h * 0.50);
      bodyPath.lineTo(w * 0.68, h * 0.26);
      bodyPath.lineTo(w * 0.35, h * 0.26);
      bodyPath.lineTo(w * 0.22, h * 0.48);
      bodyPath.lineTo(w * 0.06, h * 0.52);
      bodyPath.lineTo(w * 0.06, h * 0.70);
      bodyPath.lineTo(w * 0.22, h * 0.70);
      bodyPath.arcToPoint(
        Offset(w * 0.34, h * 0.70),
        radius: Radius.circular(w * 0.06),
        clockwise: false,
      );
      bodyPath.lineTo(w * 0.62, h * 0.70);
      bodyPath.arcToPoint(
        Offset(w * 0.74, h * 0.70),
        radius: Radius.circular(w * 0.06),
        clockwise: false,
      );
      bodyPath.close();
    }

    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, line);

    // Wheels & Alloy Spokes
    final wheelRadius = h * 0.11;
    final wheelY = h * 0.71;
    final w1 = isLeft ? Offset(w * 0.32, wheelY) : Offset(w * 0.68, wheelY);
    final w2 = isLeft ? Offset(w * 0.72, wheelY) : Offset(w * 0.28, wheelY);

    canvas.drawCircle(w1, wheelRadius, line);
    canvas.drawCircle(w1, wheelRadius * 0.6, seam);
    canvas.drawCircle(w2, wheelRadius, line);
    canvas.drawCircle(w2, wheelRadius * 0.6, seam);

    // Window DLO & Door Cutlines
    if (isLeft) {
      // B-Pillar seam
      canvas.drawLine(
        Offset(w * 0.48, h * 0.26),
        Offset(w * 0.48, h * 0.70),
        seam,
      );
      // Front door seam
      canvas.drawLine(
        Offset(w * 0.65, h * 0.48),
        Offset(w * 0.65, h * 0.70),
        seam,
      );
      // Rear door seam
      canvas.drawLine(
        Offset(w * 0.33, h * 0.45),
        Offset(w * 0.33, h * 0.70),
        seam,
      );
      // Window frame
      final winPath = Path()
        ..moveTo(w * 0.34, h * 0.30)
        ..lineTo(w * 0.47, h * 0.30)
        ..lineTo(w * 0.47, h * 0.48)
        ..lineTo(w * 0.34, h * 0.48)
        ..close();
      canvas.drawPath(winPath, seam);

      final frontWinPath = Path()
        ..moveTo(w * 0.49, h * 0.30)
        ..lineTo(w * 0.63, h * 0.30)
        ..lineTo(w * 0.74, h * 0.48)
        ..lineTo(w * 0.49, h * 0.48)
        ..close();
      canvas.drawPath(frontWinPath, seam);
    } else {
      // Right side mirrors seams
      canvas.drawLine(
        Offset(w * 0.52, h * 0.26),
        Offset(w * 0.52, h * 0.70),
        seam,
      );
      canvas.drawLine(
        Offset(w * 0.35, h * 0.48),
        Offset(w * 0.35, h * 0.70),
        seam,
      );
      canvas.drawLine(
        Offset(w * 0.67, h * 0.45),
        Offset(w * 0.67, h * 0.70),
        seam,
      );

      final frontWinPath = Path()
        ..moveTo(w * 0.51, h * 0.30)
        ..lineTo(w * 0.37, h * 0.30)
        ..lineTo(w * 0.26, h * 0.48)
        ..lineTo(w * 0.51, h * 0.48)
        ..close();
      canvas.drawPath(frontWinPath, seam);
    }
  }

  void _drawFrontView(
    Canvas canvas,
    Size size,
    Paint line,
    Paint seam,
    Paint fill,
  ) {
    final w = size.width;
    final h = size.height;

    // Roof & Greenhouse
    final cabin = Path()
      ..moveTo(w * 0.30, h * 0.22)
      ..lineTo(w * 0.70, h * 0.22)
      ..lineTo(w * 0.82, h * 0.44)
      ..lineTo(w * 0.18, h * 0.44)
      ..close();
    canvas.drawPath(cabin, fill);
    canvas.drawPath(cabin, line);

    // Front Bumper & Fenders
    final bumperRect = Rect.fromLTWH(w * 0.15, h * 0.44, w * 0.70, h * 0.36);
    canvas.drawRect(bumperRect, fill);
    canvas.drawRect(bumperRect, line);

    // Headlights
    final leftLamp = Rect.fromLTWH(w * 0.17, h * 0.46, w * 0.14, h * 0.08);
    final rightLamp = Rect.fromLTWH(w * 0.69, h * 0.46, w * 0.14, h * 0.08);
    canvas.drawRect(leftLamp, seam);
    canvas.drawRect(rightLamp, seam);

    // Front Grille
    final grille = Rect.fromLTWH(w * 0.35, h * 0.48, w * 0.30, h * 0.14);
    canvas.drawRect(grille, seam);

    // Lower Air Dam & Fog Lamps
    final lowerDam = Rect.fromLTWH(w * 0.26, h * 0.67, w * 0.48, h * 0.08);
    canvas.drawRect(lowerDam, seam);

    // Tyres contact patches visible from front
    canvas.drawRect(
      Rect.fromLTWH(w * 0.13, h * 0.70, w * 0.07, h * 0.12),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.80, h * 0.70, w * 0.07, h * 0.12),
      line,
    );

    // Bonnet crease lines
    canvas.drawLine(
      Offset(w * 0.38, h * 0.44),
      Offset(w * 0.36, h * 0.25),
      seam,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.44),
      Offset(w * 0.64, h * 0.25),
      seam,
    );
  }

  void _drawRearView(
    Canvas canvas,
    Size size,
    Paint line,
    Paint seam,
    Paint fill,
  ) {
    final w = size.width;
    final h = size.height;

    // Roof & Rear Glass
    final cabin = Path()
      ..moveTo(w * 0.30, h * 0.22)
      ..lineTo(w * 0.70, h * 0.22)
      ..lineTo(w * 0.82, h * 0.44)
      ..lineTo(w * 0.18, h * 0.44)
      ..close();
    canvas.drawPath(cabin, fill);
    canvas.drawPath(cabin, line);

    // Rear Fascia & Bumper
    final bumperRect = Rect.fromLTWH(w * 0.15, h * 0.44, w * 0.70, h * 0.36);
    canvas.drawRect(bumperRect, fill);
    canvas.drawRect(bumperRect, line);

    // Taillights
    final leftLamp = Rect.fromLTWH(w * 0.17, h * 0.46, w * 0.14, h * 0.10);
    final rightLamp = Rect.fromLTWH(w * 0.69, h * 0.46, w * 0.14, h * 0.10);
    canvas.drawRect(leftLamp, seam);
    canvas.drawRect(rightLamp, seam);

    // Number Plate Recess
    final plateRecess = Rect.fromLTWH(w * 0.36, h * 0.58, w * 0.28, h * 0.10);
    canvas.drawRect(plateRecess, seam);

    // Boot Lid Seam
    canvas.drawLine(
      Offset(w * 0.22, h * 0.44),
      Offset(w * 0.22, h * 0.72),
      seam,
    );
    canvas.drawLine(
      Offset(w * 0.78, h * 0.44),
      Offset(w * 0.78, h * 0.72),
      seam,
    );
    canvas.drawLine(
      Offset(w * 0.22, h * 0.72),
      Offset(w * 0.78, h * 0.72),
      seam,
    );

    // Tyres contact patches
    canvas.drawRect(
      Rect.fromLTWH(w * 0.13, h * 0.70, w * 0.07, h * 0.12),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.80, h * 0.70, w * 0.07, h * 0.12),
      line,
    );
  }

  void _drawTopView(
    Canvas canvas,
    Size size,
    Paint line,
    Paint seam,
    Paint fill,
  ) {
    final w = size.width;
    final h = size.height;

    // Aerial Silhouette
    final topContour = Path()
      ..moveTo(w * 0.36, h * 0.08) // Front bumper center
      ..lineTo(w * 0.64, h * 0.08)
      ..lineTo(w * 0.74, h * 0.24) // Front fenders
      ..lineTo(w * 0.74, h * 0.78) // Doors & rear quarter
      ..lineTo(w * 0.68, h * 0.92) // Rear bumper
      ..lineTo(w * 0.32, h * 0.92)
      ..lineTo(w * 0.26, h * 0.78)
      ..lineTo(w * 0.26, h * 0.24)
      ..close();

    canvas.drawPath(topContour, fill);
    canvas.drawPath(topContour, line);

    // Windshield (Front Glass)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.28, w * 0.40, h * 0.14),
      seam,
    );

    // Roof & Sunroof Panel
    final roof = Rect.fromLTWH(w * 0.30, h * 0.42, w * 0.40, h * 0.28);
    canvas.drawRect(roof, seam);

    // Rear Windshield
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.70, w * 0.40, h * 0.12),
      seam,
    );

    // Bonnet Seams
    canvas.drawLine(
      Offset(w * 0.36, h * 0.08),
      Offset(w * 0.30, h * 0.28),
      seam,
    );
    canvas.drawLine(
      Offset(w * 0.64, h * 0.08),
      Offset(w * 0.70, h * 0.28),
      seam,
    );

    // Wing Mirrors
    canvas.drawRect(
      Rect.fromLTWH(w * 0.21, h * 0.29, w * 0.05, h * 0.04),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.74, h * 0.29, w * 0.05, h * 0.04),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant ConditionSchematicPainter oldDelegate) {
    return oldDelegate.view != view || oldDelegate.isLocked != isLocked;
  }
}
