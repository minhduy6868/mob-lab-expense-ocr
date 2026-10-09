import 'package:flutter/material.dart';

class VkuLogo extends StatelessWidget {
  final double size;

  const VkuLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/brand/icon.png',
        width: size,
        height: size,
        semanticLabel: 'VKU Ledger',
      ),
    );
  }
}
