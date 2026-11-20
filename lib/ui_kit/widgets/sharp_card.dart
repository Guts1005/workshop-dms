import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

/// Modern Automotive Telemetry Card with soft ambient elevation,
/// smooth rounded corners, and clean typography.
class SharpCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleTrailing;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const SharpCard({
    super.key,
    required this.child,
    this.title,
    this.titleTrailing,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.borderColor,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppTokens.cardRadius;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTokens.surface,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: borderColor ?? AppTokens.borderLight,
          width: 1.0,
        ),
        boxShadow: boxShadow ?? AppTokens.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: const BoxDecoration(
                color: AppTokens.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppTokens.dividerPassive,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 3.5,
                          height: 14.0,
                          decoration: const BoxDecoration(
                            color: AppTokens.brandRed,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            title!,
                            style: AppTokens.fontMonospace(
                              color: AppTokens.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16.0,
                              letterSpacing: 0.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?titleTrailing,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
