import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SharpDivider extends StatelessWidget {
  final bool isPassive;
  final double height;

  const SharpDivider({
    super.key,
    this.isPassive = true,
    this.height = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: isPassive ? AppTokens.dividerPassive : AppTokens.borderSolid,
    );
  }
}
