import 'package:flutter/material.dart';

import 'package:nobemol/theme/tokens.dart';

/// Barre de progression arrondie, de 0 à 1. Vert par défaut.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 10,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.all(Radius.circular(height / 2));
    return Container(
      height: height,
      decoration: BoxDecoration(color: c.line, borderRadius: radius),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? c.success,
            borderRadius: radius,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
