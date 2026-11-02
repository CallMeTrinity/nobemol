import 'package:flutter/material.dart';

import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/motion.dart';

/// Barre de progression arrondie, de 0 à 1. Vert par défaut.
///
/// Elle glisse vers sa nouvelle valeur en [duration], et part de [from] à
/// sa première image (`null` : directement à [value]).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 10,
    this.from,
    this.duration = Motion.base,
  });

  final double value;
  final Color? color;
  final double height;
  final double? from;

  /// Zéro pour une barre qui suit déjà une horloge (temps de l'arcade).
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.all(Radius.circular(height / 2));
    final end = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(color: c.line, borderRadius: radius),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: from?.clamp(0.0, 1.0) ?? end, end: end),
        duration: Motion.of(context, duration),
        curve: Motion.enter,
        builder: (context, shown, child) =>
            FractionallySizedBox(widthFactor: shown, child: child),
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
