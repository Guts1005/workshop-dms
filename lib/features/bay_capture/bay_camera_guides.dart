import 'package:flutter/material.dart';
import 'bay_capture_models.dart';

class BayCameraGuidePainter extends CustomPainter {
  final CheckInShotType shotType;

  const BayCameraGuidePainter({required this.shotType});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dashPaint = Paint()
      ..color = const Color(0xFFF8A348).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    switch (shotType) {
      case CheckInShotType.frontLeft45:
      case CheckInShotType.frontRight45:
      case CheckInShotType.rearLeft45:
      case CheckInShotType.rearRight45:
        _drawCornerGuide(canvas, size, strokePaint, dashPaint);
        break;
      case CheckInShotType.plateCloseup:
        _drawPlateGuide(canvas, size, strokePaint, dashPaint);
        break;
      case CheckInShotType.odometerReading:
      case CheckInShotType.dashboardCluster:
        _drawClusterGuide(canvas, size, strokePaint, dashPaint);
        break;
      case CheckInShotType.vinPlate:
        _drawVinPlateGuide(canvas, size, strokePaint, dashPaint);
        break;
    }
  }

  void _drawCornerGuide(Canvas canvas, Size size, Paint stroke, Paint dash) {
    // 45 degree vehicle outline reference box
    final rect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.15,
      size.width * 0.8,
      size.height * 0.7,
    );

    // Bounding framing corners
    const cornerLen = 32.0;
    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), stroke);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLen), stroke);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLen, 0), stroke);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLen), stroke);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLen, 0), stroke);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLen), stroke);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLen, 0), stroke);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLen), stroke);

    // Ground perspective baseline guide
    final p1 = Offset(size.width * 0.15, size.height * 0.78);
    final p2 = Offset(size.width * 0.85, size.height * 0.78);
    canvas.drawLine(p1, p2, dash);

    // 45° angle guideline
    final isDriver = shotType == CheckInShotType.frontLeft45 || shotType == CheckInShotType.rearLeft45;
    if (isDriver) {
      canvas.drawLine(
        Offset(size.width * 0.25, size.height * 0.75),
        Offset(size.width * 0.65, size.height * 0.35),
        dash,
      );
    } else {
      canvas.drawLine(
        Offset(size.width * 0.75, size.height * 0.75),
        Offset(size.width * 0.35, size.height * 0.35),
        dash,
      );
    }
  }

  void _drawPlateGuide(Canvas canvas, Size size, Paint stroke, Paint dash) {
    // Standard Indian HSRP ratio roughly 500mm x 120mm (~4:1)
    final plateW = size.width * 0.75;
    final plateH = plateW * 0.32;
    final plateRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: plateW,
      height: plateH,
    );

    canvas.drawRect(plateRect, stroke);

    // Blue band guide on left side of plate
    final indBand = Rect.fromLTWH(plateRect.left, plateRect.top, plateW * 0.12, plateH);
    canvas.drawRect(indBand, dash);

    // Center crosshair
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(center - const Offset(16, 0), center + const Offset(16, 0), dash);
    canvas.drawLine(center - const Offset(0, 16), center + const Offset(0, 16), dash);
  }

  void _drawClusterGuide(Canvas canvas, Size size, Paint stroke, Paint dash) {
    // Cluster oval / display box
    final boxW = size.width * 0.7;
    final boxH = size.height * 0.45;
    final clusterRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: boxW,
      height: boxH,
    );

    final rrect = RRect.fromRectAndRadius(clusterRect, const Radius.circular(8.0));
    canvas.drawRRect(rrect, stroke);

    // Odometer digit box
    final odoRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.58),
      width: boxW * 0.6,
      height: 48.0,
    );
    canvas.drawRect(odoRect, dash);
  }

  void _drawVinPlateGuide(Canvas canvas, Size size, Paint stroke, Paint dash) {
    final vinW = size.width * 0.8;
    final vinH = size.height * 0.3;
    final vinRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: vinW,
      height: vinH,
    );
    canvas.drawRect(vinRect, stroke);
  }

  @override
  bool shouldRepaint(covariant BayCameraGuidePainter oldDelegate) {
    return oldDelegate.shotType != shotType;
  }
}
