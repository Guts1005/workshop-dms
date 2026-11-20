import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

class SharpBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    double? maxWidth = 640.0,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppTokens.raised,
              borderRadius: AppTokens.zeroRadius,
              border: Border.all(color: AppTokens.borderSolid, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Container(
                  height: 48.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  color: AppTokens.inverse,
                  child: Row(
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: AppTokens.textOnDark,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTokens.textOnDark,
                          size: 20.0,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32.0,
                          minHeight: 32.0,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                // Modal Body
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
