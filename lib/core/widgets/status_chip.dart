import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum StatusType {
  critical, // #DB4A2B fill, #FFFFFF text
  dueSoon,  // #F8A348 fill, #1E1E1E text
  ok,       // #2E6B3F fill, #FFFFFF text
  neutral,  // 1px #1E1E1E outline, #1E1E1E text
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
        borderRadius: BorderRadius.zero, // Strict invariant
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
