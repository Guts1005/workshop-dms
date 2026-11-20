import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

enum ShutterButtonState { resting, pressed, lockedReady, disabled }

/// Pure geometry concentric shutter button for bay camera capture.
/// - Outer ring: 72.0 pt diameter, 3.0 pt stroke width
/// - Inner core: 52.0 pt diameter
/// - Concentricity mathematically guaranteed via CustomPainter (0.0px offset)
/// - Only token colors from AppTokens
class ConcentricShutterButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final ShutterButtonState state;
  final double size;

  const ConcentricShutterButton({
    super.key,
    this.onPressed,
    this.state = ShutterButtonState.resting,
    this.size = 72.0,
  });

  @override
  State<ConcentricShutterButton> createState() =>
      _ConcentricShutterButtonState();
}

class _ConcentricShutterButtonState extends State<ConcentricShutterButton> {
  bool _isInteracting = false;

  bool get _isEnabled =>
      widget.state != ShutterButtonState.disabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final effectiveState = !_isEnabled
        ? ShutterButtonState.disabled
        : (_isInteracting ? ShutterButtonState.pressed : widget.state);

    return GestureDetector(
      onTapDown: _isEnabled
          ? (_) => setState(() => _isInteracting = true)
          : null,
      onTapUp: _isEnabled
          ? (_) {
              setState(() => _isInteracting = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _isEnabled
          ? () => setState(() => _isInteracting = false)
          : null,
      child: Semantics(
        button: true,
        enabled: _isEnabled,
        label: 'Camera Shutter Button',
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ConcentricShutterPainter(state: effectiveState),
          ),
        ),
      ),
    );
  }
}

class _ConcentricShutterPainter extends CustomPainter {
  final ShutterButtonState state;

  const _ConcentricShutterPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final outerRadius = (size.width / 2.0) - 1.5; // Account for 3.0 stroke
    final innerRadius = (size.width * 52.0 / 72.0) / 2.0;

    Color ringColor;
    Color coreColor;

    switch (state) {
      case ShutterButtonState.resting:
        ringColor = AppTokens.textPrimary;
        coreColor = AppTokens.inverse;
        break;
      case ShutterButtonState.pressed:
        ringColor = AppTokens.brandRed;
        coreColor = AppTokens.brandRed;
        break;
      case ShutterButtonState.lockedReady:
        ringColor = AppTokens.green;
        coreColor = AppTokens.inverse;
        break;
      case ShutterButtonState.disabled:
        ringColor = AppTokens.borderLight;
        coreColor = AppTokens.textTertiary;
        break;
    }

    // Outer Ring
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..isAntiAlias = true;

    canvas.drawCircle(center, outerRadius, ringPaint);

    // Inner Core
    final corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, innerRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant _ConcentricShutterPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
