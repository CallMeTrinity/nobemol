import 'package:flutter/painting.dart';
import 'package:notation/src/layout/glyph.g.dart';

/// Famille de la police musicale, déclarée dans le pubspec du package.
const _fontFamily = 'Bravura';

/// Dessine [glyph] avec son origine SMuFL en [origin], en pixels.
///
/// En SMuFL, un em vaut 4 interlignes : [staffSpace] fixe donc la taille de
/// police. Avec `drawText`, seul point du moteur qui passe par le texte.
void drawGlyph(
  Canvas canvas,
  Glyph glyph,
  Offset origin, {
  required double staffSpace,
  required Color color,
  double scaleX = 1,
  double scaleY = 1,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(glyph.codepoint),
      style: TextStyle(
        fontFamily: _fontFamily,
        package: 'notation',
        fontSize: staffSpace * 4,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  // Piège : TextPainter peint depuis le haut de la ligne de texte, pas depuis
  // la ligne de base. On remonte donc de la hauteur de la ligne de base.
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );

  canvas
    ..save()
    ..translate(origin.dx, origin.dy)
    ..scale(scaleX, scaleY);
  painter.paint(canvas, Offset(0, -baseline));
  canvas.restore();
  painter.dispose();
}
