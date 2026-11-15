import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

class SwipeToConfirmSlider extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final double height;
  final Color trackColor;
  final Color thumbColor;
  final Color progressColor;

  const SwipeToConfirmSlider({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.height = 56.0,
    this.trackColor = AppTokens.surface,
    this.thumbColor = AppTokens.inverse,
    this.progressColor = AppTokens.orange,
  });

  @override
  State<SwipeToConfirmSlider> createState() => _SwipeToConfirmSliderState();
}

class _SwipeToConfirmSliderState extends State<SwipeToConfirmSlider> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    // Motion discipline: transitions under 150ms
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isConfirmed) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_isConfirmed) return;

    // Threshold: 85% drag completion confirms action
    if (_dragPosition >= maxDrag * 0.85) {
      setState(() {
        _dragPosition = maxDrag;
        _isConfirmed = true;
      });
      widget.onConfirmed();
    } else {
      // Spring back within 140ms
      _springAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOut),
      )..addListener(() {
          setState(() => _dragPosition = _springAnimation.value);
        });
      _springController.forward(from: 0.0);
    }
  }

  void reset() {
    setState(() {
      _dragPosition = 0.0;
      _isConfirmed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbWidth = widget.height;
        final maxDrag = (totalWidth - thumbWidth).clamp(0.0, double.infinity);

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.trackColor,
            borderRadius: AppTokens.zeroRadius, // Strict invariant: 0px radius
            border: Border.all(color: AppTokens.borderSolid, width: 1.0),
          ),
          child: Stack(
            children: [
              // 1. Progress Fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + (thumbWidth / 2),
                child: Container(
                  color: widget.progressColor,
                ),
              ),

              // 2. Track Instruction Text
              Positioned.fill(
                child: Center(
                  child: Text(
                    _isConfirmed ? 'CONFIRMED' : widget.label.toUpperCase(),
                    style: const TextStyle(
                      color: AppTokens.textPrimary,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // 3. Sharp Rectangular Thumb (Zero Radius)
              Positioned(
                left: _dragPosition,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, maxDrag),
                  onHorizontalDragEnd: (d) => _onHorizontalDragEnd(d, maxDrag),
                  child: Container(
                    width: thumbWidth,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: _isConfirmed ? AppTokens.green : widget.thumbColor,
                      borderRadius: AppTokens.zeroRadius,
                      border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isConfirmed ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
