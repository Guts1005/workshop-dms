import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum StatusType {
  critical,
  dueSoon,
  ok,
  neutral,
}

class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final StatusType type;

  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.type = StatusType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Border? border;

    switch (type) {
      case StatusType.critical:
        backgroundColor = AppTokens.redOrange;
        textColor = Colors.white;
        border = null;
        break;
      case StatusType.dueSoon:
        // Rule: #F8A348 is never text color, only fill with #1E1E1E text (8:1 ratio)
        backgroundColor = AppTokens.orange;
        textColor = AppTokens.textPrimary;
        border = null;
        break;
      case StatusType.ok:
        backgroundColor = AppTokens.green;
        textColor = Colors.white;
        border = null;
        break;
      case StatusType.neutral:
        backgroundColor = Colors.transparent;
        textColor = AppTokens.textPrimary;
        border = Border.all(color: AppTokens.borderSolid, width: 1.0);
        break;
    }

    return Container(
      height: 32.0,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTokens.zeroRadius,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14.0, color: textColor),
          const SizedBox(width: 6.0),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
