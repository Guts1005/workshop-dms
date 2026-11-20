import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

class DataRowItem extends StatefulWidget {
  final String label;
  final String value;
  final bool isMonospace;
  final bool isBold;
  final Color? valueColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  const DataRowItem({
    super.key,
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.isBold = false,
    this.valueColor,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  State<DataRowItem> createState() => _DataRowItemState();
}

class _DataRowItemState extends State<DataRowItem> {
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isTappable = widget.onTap != null;

    Color bg;
    if (_isPressed && isTappable) {
      bg = AppTokens.pinkPressed; // Pink pressed fill rule with #1E1E1E text
    } else {
      bg = Colors.transparent;
    }

    Widget content = Container(
      constraints: const BoxConstraints(minHeight: AppTokens.minTableRowHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: bg,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              widget.label.toUpperCase(),
              style: const TextStyle(
                color: AppTokens.textSecondary,
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.minTouchGap),
          Expanded(
            flex: 3,
            child: Text(
              widget.value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: widget.valueColor ?? AppTokens.textPrimary,
                fontFamily: widget.isMonospace ? 'monospace' : null,
                fontSize: 14.0,
                fontWeight: widget.isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: AppTokens.minTouchGap),
            widget.trailing!,
          ],
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isTappable)
          FocusableActionDetector(
            onShowFocusHighlight: (v) => setState(() => _isFocused = v),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: content,
            ),
          )
        else
          content,
        if (widget.showDivider)
          Container(
            height: 1.0,
            color: isTappable
                ? AppTokens.borderSolid
                : AppTokens.dividerPassive,
          ),
      ],
    );
  }
}
