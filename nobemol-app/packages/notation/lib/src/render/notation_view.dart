import 'package:flutter/widgets.dart';
import 'package:notation/src/layout/layout.dart';
import 'package:notation/src/model/system.dart';
import 'package:notation/src/render/notation_painter.dart';

/// Affiche un [System] à taille fixe.
class NotationView extends StatelessWidget {
  /// Crée la vue. [color] vaut par défaut la couleur du texte ambiant.
  const new({
    required this.system,
    this.staffSpace = 10,
    this.options = const LayoutOptions(),
    this.color,
    super.key,
  });

  /// Système à afficher.
  final System system;

  /// Taille d'un interligne, en pixels.
  final double staffSpace;

  /// Réglages du layout.
  final LayoutOptions options;

  /// Couleur de la notation.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final painter = NotationPainter(
      layoutSystem(system, options: options),
      staffSpace: staffSpace,
      color:
          color ??
          DefaultTextStyle.of(context).style.color ??
          const Color(0xFF000000),
    );
    return CustomPaint(size: painter.size, painter: painter);
  }
}
