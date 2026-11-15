import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum SharpButtonVariant {
  primary,
  secondary,
  destructive,
}

class SharpButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final SharpButtonVariant variant;
  final bool onDark;
  final double? width;
  final double height;

  const SharpButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = SharpButtonVariant.primary,
    this.onDark = false,
    this.width,
    this.height = AppTokens.minTouchTarget,
  });

  @override
  State<SharpButton> createState() => _SharpButtonState();
}

class _SharpButtonState extends State<SharpButton> {
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    Color backgroundColor;
    Color textColor;
    Border? border;

    if (!isEnabled) {
      if (widget.onDark) {
        backgroundColor = const Color(0xFF2A2A2A);
        textColor = const Color(0xFF777777);
        border = Border.all(color: const Color(0xFF444444), width: 1.0);
      } else {
        backgroundColor = AppTokens.surface;
        textColor = AppTokens.textSecondary;
        border = Border.all(color: AppTokens.dividerPassive, width: 1.0);
      }
    } else if (_isPressed) {
      // Pressed specification: #FFFFFF fill, #DB4A2B text
      backgroundColor = AppTokens.raised;
      textColor = AppTokens.redOrange;
      border = Border.all(color: AppTokens.borderSolid, width: 1.0);
    } else {
      switch (widget.variant) {
        case SharpButtonVariant.primary:
          backgroundColor = widget.onDark ? AppTokens.raised : AppTokens.inverse;
          textColor = widget.onDark ? AppTokens.textPrimary : AppTokens.textOnDark;
          border = widget.onDark ? Border.all(color: AppTokens.borderSolid, width: 1.0) : null;
          break;
        case SharpButtonVariant.secondary:
          backgroundColor = Colors.transparent;
          textColor = widget.onDark ? AppTokens.textOnDark : AppTokens.textPrimary;
          border = Border.all(
            color: widget.onDark ? AppTokens.textOnDark : AppTokens.borderSolid,
            width: 1.0,
          );
          break;
        case SharpButtonVariant.destructive:
          backgroundColor = AppTokens.redOrange;
          textColor = Colors.white;
          border = null;
          break;
      }
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTokens.zeroRadius,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18.0, color: textColor),
            const SizedBox(width: AppTokens.minTouchGap),
          ],
          Flexible(
            child: Text(
              widget.label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );

    if (_isFocused) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: AppTokens.zeroRadius,
          border: Border.all(
            color: AppTokens.borderSolid,
            width: AppTokens.focusRingWidth,
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.focusRingOffset),
        child: content,
      );
    }

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onPressed,
        child: content,
      ),
    );
  }
}
