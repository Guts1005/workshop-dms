import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SharpTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isMonospace;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final String? suffixText;
  final bool readOnly;

  const SharpTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isMonospace = false,
    this.onChanged,
    this.prefixText,
    this.suffixText,
    this.readOnly = false,
  });

  @override
  State<SharpTextField> createState() => _SharpTextFieldState();
}

class _SharpTextFieldState extends State<SharpTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget inputField = Container(
      height: AppTokens.minTouchTarget,
      decoration: BoxDecoration(
        color: widget.readOnly ? AppTokens.surface : AppTokens.raised,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      alignment: Alignment.center,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: AppTokens.textPrimary,
          fontSize: 16.0,
          fontFamily: widget.isMonospace ? 'monospace' : null,
          fontWeight: widget.isMonospace ? FontWeight.w600 : FontWeight.w400,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: AppTokens.textSecondary,
            fontSize: 14.0,
          ),
          prefixText: widget.prefixText != null ? '${widget.prefixText} ' : null,
          prefixStyle: const TextStyle(
            color: AppTokens.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          suffixText: widget.suffixText,
          suffixStyle: const TextStyle(
            color: AppTokens.textSecondary,
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (_isFocused) {
      inputField = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppTokens.borderSolid,
            width: AppTokens.focusRingWidth,
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.focusRingOffset),
        child: inputField,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            color: AppTokens.textSecondary,
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        inputField,
      ],
    );
  }
}
