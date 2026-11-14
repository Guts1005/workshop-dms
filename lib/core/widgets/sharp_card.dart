import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SharpCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool isHeader;

  const SharpCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
    this.isHeader = false,
  });

  @override
  State<SharpCard> createState() => _SharpCardState();
}

class _SharpCardState extends State<SharpCard> {
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isTappable = widget.onTap != null;

    Color bg;
    if (_isPressed && isTappable) {
      // User Accent Rule: Pink #FF89A9 pressed fill on rows and cards only, with #1E1E1E text
      bg = AppTokens.pinkPressed;
    } else {
      bg = widget.backgroundColor ?? (widget.isHeader ? AppTokens.surface : AppTokens.raised);
    }

    Widget content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      child: widget.child,
    );

    if (_isFocused) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppTokens.borderSolid,
            width: AppTokens.focusRingWidth,
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.focusRingOffset),
        child: content,
      );
    }

    if (!isTappable) return content;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}
