import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

/// Industrial Sharp Card with 90° corners, 1px border, and optional titanium header.
/// Follows Rivian technical telemetry guidelines and Digital Health Passport theme.
class SharpCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleTrailing;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const SharpCard({
    super.key,
    required this.child,
    this.title,
    this.titleTrailing,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTokens.raised,
        border: Border.all(color: borderColor ?? AppTokens.borderSolid, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: const BoxDecoration(
                color: AppTokens.inverse,
                border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 1.0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTokens.fontMonospace(
                        color: AppTokens.textOnDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.0,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ?titleTrailing,
                ],
              ),
            ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
