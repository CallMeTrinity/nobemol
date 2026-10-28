import 'dart:math' as math;

import 'package:notation/src/layout/glyph.g.dart';
import 'package:notation/src/layout/text_font.g.dart';
import 'package:notation/src/model/system.dart';

/// Rectangle en interlignes, axe y vers le bas.
class Box {
  /// Crée un rectangle.
  const new(this.left, this.top, this.right, this.bottom);

  /// Bord gauche.
  final double left;

  /// Bord haut.
  final double top;

  /// Bord droit.
  final double right;

  /// Bord bas.
  final double bottom;

  /// Largeur.
  double get width => right - left;

  /// Hauteur.
  double get height => bottom - top;

  /// Plus petit rectangle qui contient celui-ci et [other].
  Box union(Box other) => Box(
    math.min(left, other.left),
    math.min(top, other.top),
    math.max(right, other.right),
    math.max(bottom, other.bottom),
  );

  /// Rectangle agrandi de [delta] de chaque côté.
  Box inflate(double delta) =>
      Box(left - delta, top - delta, right + delta, bottom + delta);

  @override
  String toString() => 'Box($left, $top, $right, $bottom)';
}

/// Élément de la liste de dessin, en interlignes, axe y vers le bas.
sealed class DrawCommand {
  const new({this.event, this.decoration});

  /// Événement dessiné (tête, altération, hampe), `null` pour le reste. Permet
  /// de colorer une note.
  final EventRef? event;

  /// Événement dont la commande dessine une décoration (nuance, articulation,
  /// soufflet, texte), `null` pour le reste. Permet de colorer un signe sans
  /// sa note. Un soufflet appartient à sa première note.
  final EventRef? decoration;

  /// Rectangle occupé.
  Box get bounds;
}

/// Glyphe de la police musicale, posé sur son origine SMuFL.
class GlyphCommand extends DrawCommand {
  /// Crée un glyphe à l'origine ([x], [y]).
  const new(
    this.glyph,
    this.x,
    this.y, {
    this.scaleX = 1,
    this.scaleY = 1,
    super.event,
    super.decoration,
  });

  /// Glyphe.
  final Glyph glyph;

  /// Abscisse de l'origine.
  final double x;

  /// Ordonnée de l'origine (ligne de base).
  final double y;

  /// Étirement horizontal.
  final double scaleX;

  /// Étirement vertical.
  final double scaleY;

  @override
  Box get bounds => Box(
    x + glyph.bBoxSW.$1 * scaleX,
    y - glyph.bBoxNE.$2 * scaleY,
    x + glyph.bBoxNE.$1 * scaleX,
    y - glyph.bBoxSW.$2 * scaleY,
  );
}

/// Segment droit à bouts carrés (lignes de portée, barres).
class LineCommand extends DrawCommand {
  /// Crée un segment de ([x1], [y1]) à ([x2], [y2]).
  const new(
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.thickness, {
    super.event,
    super.decoration,
  });

  /// Abscisse de départ.
  final double x1;

  /// Ordonnée de départ.
  final double y1;

  /// Abscisse d'arrivée.
  final double x2;

  /// Ordonnée d'arrivée.
  final double y2;

  /// Épaisseur.
  final double thickness;

  @override
  Box get bounds => Box(
    math.min(x1, x2),
    math.min(y1, y2),
    math.max(x1, x2),
    math.max(y1, y2),
  ).inflate(thickness / 2);
}

/// Ligature : parallélogramme dont les côtés gauche et droit sont verticaux.
class BeamCommand extends DrawCommand {
  /// Crée une ligature dont la ligne médiane va de ([x1], [y1]) à ([x2],
  /// [y2]).
  const new(this.x1, this.y1, this.x2, this.y2, this.thickness);

  /// Abscisse du bord gauche.
  final double x1;

  /// Ordonnée de la ligne médiane, à gauche.
  final double y1;

  /// Abscisse du bord droit.
  final double x2;

  /// Ordonnée de la ligne médiane, à droite.
  final double y2;

  /// Épaisseur, mesurée verticalement.
  final double thickness;

  @override
  Box get bounds => Box(
    x1,
    math.min(y1, y2) - thickness / 2,
    x2,
    math.max(y1, y2) + thickness / 2,
  );
}

/// Liaison de prolongation : un arc plein, effilé aux deux bouts, entre deux
/// notes de même hauteur.
class TieCommand extends DrawCommand {
  /// Crée une liaison de ([x1], [y]) à ([x2], [y]), dont le milieu s'écarte
  /// de [height] : négatif vers le haut, positif vers le bas.
  const new(
    this.x1,
    this.x2,
    this.y, {
    required this.height,
    required this.endThickness,
    required this.midThickness,
    super.event,
  });

  /// Abscisse de départ.
  final double x1;

  /// Abscisse d'arrivée.
  final double x2;

  /// Ordonnée des deux bouts.
  final double y;

  /// Écart du milieu de l'arc par rapport à [y].
  final double height;

  /// Épaisseur aux bouts.
  final double endThickness;

  /// Épaisseur au milieu.
  final double midThickness;

  @override
  Box get bounds {
    final peak = y + height + height.sign * midThickness / 2;
    return Box(
      x1,
      math.min(y - endThickness / 2, peak),
      x2,
      math.max(y + endThickness / 2, peak),
    );
  }
}

/// Texte en italique, dans la police des textes ([TextFont]), posé sur sa
/// ligne de base. Sans crénage : sa largeur est la somme des chasses.
class TextCommand extends DrawCommand {
  /// Crée un texte qui commence en [x], sur la ligne de base [y].
  const new(this.text, this.x, this.y, {required this.size, super.decoration});

  /// Texte.
  final String text;

  /// Abscisse du début.
  final double x;

  /// Ordonnée de la ligne de base.
  final double y;

  /// Taille du em, en interlignes.
  final double size;

  /// Largeur. Un caractère absent des métriques compte comme un « n ».
  double get width =>
      text.runes.fold<double>(
        0,
        (width, code) =>
            width + (TextFont.advances[code] ?? TextFont.advances[0x6E]!),
      ) *
      size;

  @override
  Box get bounds => Box(
    x,
    y - TextFont.ascender * size,
    x + width,
    y + TextFont.descender * size,
  );
}
