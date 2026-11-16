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
  final BorderRadius? borderRadius;

  const SharpButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = SharpButtonVariant.primary,
    this.onDark = false,
    this.width,
    this.height = AppTokens.minTouchTarget,
    this.borderRadius,
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
    final effectiveRadius = widget.borderRadius ?? AppTokens.buttonRadius;

    Color backgroundColor;
    Color textColor;
    Border? border;

    if (!isEnabled) {
      if (widget.onDark) {
        backgroundColor = const Color(0xFF23272F);
        textColor = const Color(0xFF6B7280);
        border = Border.all(color: const Color(0xFF374151), width: 1.0);
      } else {
        backgroundColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF94A3B8);
        border = Border.all(color: const Color(0xFFE2E8F0), width: 1.0);
      }
    } else if (_isPressed) {
      backgroundColor = widget.variant == SharpButtonVariant.destructive
          ? const Color(0xFFB91C1C)
          : const Color(0xFF1E293B);
      textColor = Colors.white;
      border = null;
    } else {
      switch (widget.variant) {
        case SharpButtonVariant.primary:
          backgroundColor = widget.onDark ? Colors.white : AppTokens.inverse;
          textColor = widget.onDark ? AppTokens.textPrimary : Colors.white;
          border = null;
          break;
        case SharpButtonVariant.secondary:
          backgroundColor = widget.onDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9);
          textColor = widget.onDark ? AppTokens.textOnDark : AppTokens.textPrimary;
          border = Border.all(
            color: widget.onDark ? const Color(0xFF374151) : AppTokens.borderLight,
            width: 1.0,
          );
          break;
        case SharpButtonVariant.destructive:
          backgroundColor = AppTokens.brandRed;
          textColor = Colors.white;
          border = null;
          break;
      }
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: isEnabled && widget.variant == SharpButtonVariant.primary
            ? [
                BoxShadow(
                  color: (widget.onDark ? Colors.black : AppTokens.inverse).withValues(alpha: 0.18),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
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
          borderRadius: effectiveRadius,
          border: Border.all(
            color: AppTokens.brandRed,
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
