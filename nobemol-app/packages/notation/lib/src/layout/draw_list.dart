import 'dart:math' as math;

import 'package:notation/src/layout/glyph.g.dart';

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
  const new();

  /// Rectangle occupé.
  Box get bounds;
}

/// Glyphe de la police musicale, posé sur son origine SMuFL.
class GlyphCommand extends DrawCommand {
  /// Crée un glyphe à l'origine ([x], [y]).
  const new(this.glyph, this.x, this.y, {this.scaleX = 1, this.scaleY = 1});

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
  const new(this.x1, this.y1, this.x2, this.y2, this.thickness);

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
