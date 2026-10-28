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
    this.highlights = const {},
    this.decorationHighlights = const {},
    this.halos = const {},
    this.decorationHalos = const {},
    this.labels = const {},
    this.labelStyle,
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

  /// Couleur propre à certains événements (note ciblée, correction).
  final Map<EventRef, Color> highlights;

  /// Couleur propre aux décorations de certains événements (signe ciblé),
  /// sans leur note.
  final Map<EventRef, Color> decorationHighlights;

  /// Pastille de couleur derrière la tête de certains événements (cible).
  final Map<EventRef, Color> halos;

  /// Pastille de couleur derrière les décorations de certains événements.
  final Map<EventRef, Color> decorationHalos;

  /// Nom écrit sous certaines notes (« fa, sol, la »).
  final Map<EventRef, String> labels;

  /// Police et couleur des noms, par défaut la police du texte ambiant et
  /// la couleur de la notation. Taille ignorée : celle du layout. Une note
  /// de [highlights] colore aussi son nom.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final painter = NotationPainter(
      layoutSystem(system, options: options, labels: labels),
      staffSpace: staffSpace,
      color:
          color ??
          DefaultTextStyle.of(context).style.color ??
          const Color(0xFF000000),
      highlights: highlights,
      decorationHighlights: decorationHighlights,
      halos: halos,
      decorationHalos: decorationHalos,
      labelStyle:
          labelStyle ??
          DefaultTextStyle.of(context).style.copyWith(color: color),
    );
    return CustomPaint(size: painter.size, painter: painter);
  }
}
