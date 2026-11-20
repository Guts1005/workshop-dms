import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

enum StatusType { critical, dueSoon, ok, neutral }

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
        backgroundColor = AppTokens.brandRed;
        textColor = AppTokens.raised;
        border = null;
        break;
      case StatusType.dueSoon:
        backgroundColor = AppTokens.orange;
        textColor = AppTokens.inverse;
        border = null;
        break;
      case StatusType.ok:
        backgroundColor = AppTokens.green;
        textColor = AppTokens.raised;
        border = null;
        break;
      case StatusType.neutral:
        backgroundColor = AppTokens.surface;
        textColor = AppTokens.textPrimary;
        border = Border.all(color: AppTokens.borderSolid, width: 1.0);
        break;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 36.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTokens.zeroRadius,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18.0, color: textColor),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: type == StatusType.critical ? 18.0 : 16.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
