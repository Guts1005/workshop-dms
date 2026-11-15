import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'bay_capture_models.dart';

/// Intuitive, CAD-grade vehicle & component alignment guides for Workshop Check-in.
/// Designed for workshop owners and service advisors:
/// - Realistic vehicle outlines and silhouettes
/// - Animated framing scanline and reticle pulse
/// - Instant visual feedback: Amber when positioning, Neon Green when locked & in frame
class BayCameraGuidePainter extends CustomPainter {
  final CheckInShotType shotType;
  final bool isLocked;
  final double scanProgress; // 0.0 to 1.0 from AnimationController

  const BayCameraGuidePainter({
    required this.shotType,
    this.isLocked = false,
    this.scanProgress = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activeColor = isLocked ? const Color(0xFF00E676) : const Color(0xFFF8A348);
    final guideColor = isLocked ? const Color(0xFF00E676).withOpacity(0.85) : Colors.white.withOpacity(0.75);

    final strokePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLocked ? 2.2 : 1.6;

    final accentPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLocked ? 3.0 : 2.0;

    final fillPaint = Paint()
      ..color = activeColor.withOpacity(isLocked ? 0.08 : 0.03)
      ..style = PaintingStyle.fill;

    switch (shotType) {
      case CheckInShotType.frontLeft45:
        _drawCornerSilhouette(canvas, size, strokePaint, accentPaint, fillPaint, isFront: true, isLeft: true);
        break;
      case CheckInShotType.frontRight45:
        _drawCornerSilhouette(canvas, size, strokePaint, accentPaint, fillPaint, isFront: true, isLeft: false);
        break;
      case CheckInShotType.rearLeft45:
        _drawCornerSilhouette(canvas, size, strokePaint, accentPaint, fillPaint, isFront: false, isLeft: true);
        break;
      case CheckInShotType.rearRight45:
        _drawCornerSilhouette(canvas, size, strokePaint, accentPaint, fillPaint, isFront: false, isLeft: false);
        break;
      case CheckInShotType.plateCloseup:
        _drawNumberPlateGuide(canvas, size, strokePaint, accentPaint, fillPaint);
        break;
      case CheckInShotType.odometerReading:
      case CheckInShotType.dashboardCluster:
        _drawOdometerClusterGuide(canvas, size, strokePaint, accentPaint, fillPaint);
        break;
      case CheckInShotType.vinPlate:
        _drawVinPlateGuide(canvas, size, strokePaint, accentPaint, fillPaint);
        break;
    }

    // Draw active scanning beam & corner targeting reticles
    _drawFramingReticles(canvas, size, accentPaint);
  }

  /// Draws an intuitive 45° perspective car silhouette with the target corner clearly highlighted
  void _drawCornerSilhouette(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accent,
    Paint fill, {
    required bool isFront,
    required bool isLeft,
  }) {
    final w = size.width;
    final h = size.height;

    // Framing Zone Box (76% width, 68% height)
    final boxRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.82,
      height: h * 0.72,
    );

    canvas.drawRect(boxRect, fill);

    // Car Body 3/4 Perspective Silhouette Path
    final path = Path();
    if (isFront && isLeft) {
      // Front-Left 45°: Nose on bottom-left, roof center-right, trunk far right
      path.moveTo(boxRect.left + boxRect.width * 0.08, boxRect.bottom - boxRect.height * 0.22); // Front bumper
      path.lineTo(boxRect.left + boxRect.width * 0.28, boxRect.bottom - boxRect.height * 0.32); // Hood slope
      path.lineTo(boxRect.left + boxRect.width * 0.45, boxRect.top + boxRect.height * 0.22);    // Windshield
      path.lineTo(boxRect.left + boxRect.width * 0.75, boxRect.top + boxRect.height * 0.22);    // Roofline
      path.lineTo(boxRect.left + boxRect.width * 0.90, boxRect.bottom - boxRect.height * 0.35); // Rear glass & boot
      path.lineTo(boxRect.left + boxRect.width * 0.82, boxRect.bottom - boxRect.height * 0.18); // Rear bumper
      path.lineTo(boxRect.left + boxRect.width * 0.40, boxRect.bottom - boxRect.height * 0.18); // Side sill
      path.close();
    } else if (isFront && !isLeft) {
      // Front-Right 45°: Nose on bottom-right, roof center-left, trunk far left
      path.moveTo(boxRect.right - boxRect.width * 0.08, boxRect.bottom - boxRect.height * 0.22);
      path.lineTo(boxRect.right - boxRect.width * 0.28, boxRect.bottom - boxRect.height * 0.32);
      path.lineTo(boxRect.right - boxRect.width * 0.45, boxRect.top + boxRect.height * 0.22);
      path.lineTo(boxRect.right - boxRect.width * 0.75, boxRect.top + boxRect.height * 0.22);
      path.lineTo(boxRect.right - boxRect.width * 0.90, boxRect.bottom - boxRect.height * 0.35);
      path.lineTo(boxRect.right - boxRect.width * 0.82, boxRect.bottom - boxRect.height * 0.18);
      path.lineTo(boxRect.right - boxRect.width * 0.40, boxRect.bottom - boxRect.height * 0.18);
      path.close();
    } else if (!isFront && isLeft) {
      // Rear-Left 45°: Trunk on bottom-left, roof center-right, hood far right
      path.moveTo(boxRect.left + boxRect.width * 0.08, boxRect.bottom - boxRect.height * 0.24); // Rear bumper
      path.lineTo(boxRect.left + boxRect.width * 0.26, boxRect.bottom - boxRect.height * 0.36); // Rear tailgate
      path.lineTo(boxRect.left + boxRect.width * 0.44, boxRect.top + boxRect.height * 0.22);    // Rear glass
      path.lineTo(boxRect.left + boxRect.width * 0.72, boxRect.top + boxRect.height * 0.22);    // Roof
      path.lineTo(boxRect.left + boxRect.width * 0.90, boxRect.bottom - boxRect.height * 0.30); // Front hood
      path.lineTo(boxRect.left + boxRect.width * 0.80, boxRect.bottom - boxRect.height * 0.18); // Front bumper
      path.lineTo(boxRect.left + boxRect.width * 0.38, boxRect.bottom - boxRect.height * 0.18); // Side sill
      path.close();
    } else {
      // Rear-Right 45°
      path.moveTo(boxRect.right - boxRect.width * 0.08, boxRect.bottom - boxRect.height * 0.24);
      path.lineTo(boxRect.right - boxRect.width * 0.26, boxRect.bottom - boxRect.height * 0.36);
      path.lineTo(boxRect.right - boxRect.width * 0.44, boxRect.top + boxRect.height * 0.22);
      path.lineTo(boxRect.right - boxRect.width * 0.72, boxRect.top + boxRect.height * 0.22);
      path.lineTo(boxRect.right - boxRect.width * 0.90, boxRect.bottom - boxRect.height * 0.30);
      path.lineTo(boxRect.right - boxRect.width * 0.80, boxRect.bottom - boxRect.height * 0.18);
      path.lineTo(boxRect.right - boxRect.width * 0.38, boxRect.bottom - boxRect.height * 0.18);
      path.close();
    }

    canvas.drawPath(path, stroke);

    // Wheel arches & ground contact cues
    final wheelY = boxRect.bottom - boxRect.height * 0.18;
    final primaryWheelX = isLeft
        ? boxRect.left + boxRect.width * (isFront ? 0.22 : 0.24)
        : boxRect.right - boxRect.width * (isFront ? 0.22 : 0.24);
    final secondaryWheelX = isLeft
        ? boxRect.left + boxRect.width * 0.75
        : boxRect.right - boxRect.width * 0.75;

    canvas.drawCircle(Offset(primaryWheelX, wheelY), boxRect.height * 0.09, stroke);
    canvas.drawCircle(Offset(secondaryWheelX, wheelY), boxRect.height * 0.07, stroke);

    // Ground Baseline
    canvas.drawLine(
      Offset(boxRect.left, wheelY + boxRect.height * 0.09),
      Offset(boxRect.right, wheelY + boxRect.height * 0.09),
      Paint()..color = Colors.white.withOpacity(0.35)..strokeWidth = 1.0,
    );

    // TARGET CORNER FOCUS RETICLE & ARROW
    // Pinpoints the exact corner the owner needs to center in camera
    final targetX = isLeft ? boxRect.left + boxRect.width * 0.15 : boxRect.right - boxRect.width * 0.15;
    final targetY = boxRect.bottom - boxRect.height * 0.22;
    final targetOffset = Offset(targetX, targetY);

    // Target corner circle with animated pulse
    final pulseRadius = (boxRect.height * 0.14) + (isLocked ? 4.0 * math.sin(scanProgress * math.pi * 2) : 0);
    canvas.drawCircle(targetOffset, pulseRadius, accent);

    // Crosshair on target corner
    canvas.drawLine(targetOffset - const Offset(20, 0), targetOffset + const Offset(20, 0), accent);
    canvas.drawLine(targetOffset - const Offset(0, 20), targetOffset + const Offset(0, 20), accent);
  }

  /// Draws a realistic Indian HSRP Number Plate guide with IND band and character slots
  void _drawNumberPlateGuide(Canvas canvas, Size size, Paint stroke, Paint accent, Paint fill) {
    final w = size.width;
    final h = size.height;

    // HSRP Standard Aspect Ratio roughly 4:1 (500mm x 120mm)
    final plateW = w * 0.85;
    final plateH = math.min(plateW * 0.28, h * 0.40);

    final plateRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: plateW,
      height: plateH,
    );

    canvas.drawRect(plateRect, fill);
    canvas.drawRect(plateRect, stroke);

    // Blue IND Band on Left (12% of plate width)
    final indBandRect = Rect.fromLTWH(plateRect.left, plateRect.top, plateW * 0.13, plateH);
    canvas.drawRect(
      indBandRect,
      Paint()..color = const Color(0xFF003399).withOpacity(0.4)..style = PaintingStyle.fill,
    );
    canvas.drawRect(indBandRect, stroke);

    // Chakra / Emblem circle indicator inside IND band
    canvas.drawCircle(
      Offset(indBandRect.center.dx, plateRect.top + plateH * 0.35),
      plateH * 0.14,
      Paint()..color = Colors.white.withOpacity(0.7)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    // Corner screw/bolt holes
    const boltRadius = 4.0;
    const inset = 8.0;
    final boltPaint = Paint()..color = Colors.white.withOpacity(0.6)..style = PaintingStyle.fill;
    canvas.drawCircle(plateRect.topLeft + const Offset(inset, inset), boltRadius, boltPaint);
    canvas.drawCircle(plateRect.topRight + const Offset(-inset, inset), boltRadius, boltPaint);
    canvas.drawCircle(plateRect.bottomLeft + const Offset(inset, -inset), boltRadius, boltPaint);
    canvas.drawCircle(plateRect.bottomRight + const Offset(-inset, -inset), boltRadius, boltPaint);

    // Ghosted Plate Number Slots (e.g. MH 02 AB 1234)
    final charBoxWidth = (plateW * 0.82) / 10;
    final charBoxHeight = plateH * 0.55;
    final startX = indBandRect.right + (plateW * 0.03);
    final startY = plateRect.center.dy - (charBoxHeight / 2);

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 10; i++) {
      if (i == 2 || i == 4 || i == 6) continue; // Spaces between RTO code & numbers
      final charRect = Rect.fromLTWH(startX + (i * charBoxWidth), startY, charBoxWidth * 0.75, charBoxHeight);
      canvas.drawRect(charRect, dashPaint);
    }
  }

  /// Draws a clear speedometer gauge and digital odometer counter box
  void _drawOdometerClusterGuide(Canvas canvas, Size size, Paint stroke, Paint accent, Paint fill) {
    final w = size.width;
    final h = size.height;

    final clusterW = w * 0.85;
    final clusterH = math.min(clusterW * 0.60, h * 0.65);

    final clusterRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: clusterW,
      height: clusterH,
    );

    canvas.drawRect(clusterRect, fill);
    canvas.drawRect(clusterRect, stroke);

    // Speedometer Dial Arc
    final dialCenter = Offset(w * 0.5, clusterRect.top + clusterH * 0.42);
    final dialRadius = clusterH * 0.32;
    canvas.drawArc(
      Rect.fromCircle(center: dialCenter, radius: dialRadius),
      math.pi * 0.8,
      math.pi * 1.4,
      false,
      stroke,
    );

    // Dial Needle indicator
    canvas.drawLine(
      dialCenter,
      dialCenter + Offset(math.cos(math.pi * 1.3) * dialRadius * 0.75, math.sin(math.pi * 1.3) * dialRadius * 0.75),
      accent,
    );

    // Digital Odometer Box
    final odoW = clusterW * 0.65;
    final odoH = clusterH * 0.24;
    final odoRect = Rect.fromCenter(
      center: Offset(w * 0.5, clusterRect.bottom - clusterH * 0.22),
      width: odoW,
      height: odoH,
    );

    canvas.drawRect(odoRect, accent);

    // 6 Odometer Digit Dividers [ 0 | 4 | 2 | 8 | 9 | 0 ]
    final digitWidth = odoW / 6;
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(odoRect.left + (i * digitWidth), odoRect.top),
        Offset(odoRect.left + (i * digitWidth), odoRect.bottom),
        stroke,
      );
    }
  }

  /// Draws a clean VIN chassis barcode plaque guide
  void _drawVinPlateGuide(Canvas canvas, Size size, Paint stroke, Paint accent, Paint fill) {
    final w = size.width;
    final h = size.height;

    final vinW = w * 0.88;
    final vinH = math.min(vinW * 0.35, h * 0.42);

    final vinRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: vinW,
      height: vinH,
    );

    canvas.drawRect(vinRect, fill);
    canvas.drawRect(vinRect, stroke);

    // Barcode simulated lines
    final barcodeY = vinRect.top + vinH * 0.25;
    final barcodeH = vinH * 0.30;
    final linePaint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 2.0;

    for (double x = vinRect.left + 16.0; x < vinRect.right - 16.0; x += 8.0) {
      canvas.drawLine(Offset(x, barcodeY), Offset(x, barcodeY + barcodeH), linePaint);
    }

    // 17 Character boxes baseline
    canvas.drawLine(
      Offset(vinRect.left + 16.0, vinRect.bottom - vinH * 0.22),
      Offset(vinRect.right - 16.0, vinRect.bottom - vinH * 0.22),
      accent,
    );
  }

  /// Draws high-tech animated corner brackets and scanning beam across the frame
  void _drawFramingReticles(Canvas canvas, Size size, Paint accent) {
    final w = size.width;
    final h = size.height;

    final boxW = w * 0.88;
    final boxH = h * 0.78;
    final frameRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: boxW,
      height: boxH,
    );

    const cornerSize = 28.0;

    // 4 Corner Targeting Brackets
    // Top-Left
    canvas.drawLine(frameRect.topLeft, frameRect.topLeft + const Offset(cornerSize, 0), accent);
    canvas.drawLine(frameRect.topLeft, frameRect.topLeft + const Offset(0, cornerSize), accent);
    // Top-Right
    canvas.drawLine(frameRect.topRight, frameRect.topRight + const Offset(-cornerSize, 0), accent);
    canvas.drawLine(frameRect.topRight, frameRect.topRight + const Offset(0, cornerSize), accent);
    // Bottom-Left
    canvas.drawLine(frameRect.bottomLeft, frameRect.bottomLeft + const Offset(cornerSize, 0), accent);
    canvas.drawLine(frameRect.bottomLeft, frameRect.bottomLeft + const Offset(0, -cornerSize), accent);
    // Bottom-Right
    canvas.drawLine(frameRect.bottomRight, frameRect.bottomRight + const Offset(-cornerSize, 0), accent);
    canvas.drawLine(frameRect.bottomRight, frameRect.bottomRight + const Offset(0, -cornerSize), accent);

    // Active Scanning Laser Beam (Sweeps vertically when searching/aligning)
    if (!isLocked) {
      final scanY = frameRect.top + (frameRect.height * scanProgress);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFF8A348).withOpacity(0.0),
            const Color(0xFFF8A348).withOpacity(0.85),
            const Color(0xFFF8A348).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(frameRect.left, scanY - 1, frameRect.width, 3))
        ..strokeWidth = 2.0;

      canvas.drawLine(Offset(frameRect.left, scanY), Offset(frameRect.right, scanY), scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BayCameraGuidePainter oldDelegate) {
    return oldDelegate.shotType != shotType ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.scanProgress != scanProgress;
  }
}
