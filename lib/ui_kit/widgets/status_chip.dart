import 'package:flutter/material.dart';

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
        backgroundColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        border = Border.all(color: const Color(0xFFFCA5A5), width: 1.0);
        break;
      case StatusType.dueSoon:
        backgroundColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        border = Border.all(color: const Color(0xFFFDE68A), width: 1.0);
        break;
      case StatusType.ok:
        backgroundColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        border = Border.all(color: const Color(0xFF86EFAC), width: 1.0);
        break;
      case StatusType.neutral:
        backgroundColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        border = Border.all(color: const Color(0xFFE2E8F0), width: 1.0);
        break;
    }

    return Container(
      height: 28.0,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14.0),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13.0, color: textColor),
          const SizedBox(width: 5.0),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
