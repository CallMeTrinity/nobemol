import 'package:flutter/painting.dart';

/// Famille de la police des textes, déclarée dans le pubspec du package.
const _fontFamily = 'Edwin';

/// Dessine [text] en italique, depuis [origin] sur la ligne de base, en
/// pixels. [fontSize] est la taille du em, en pixels.
///
/// Sans crénage ni ligatures : la largeur dessinée est celle que le layout
/// calcule à partir des chasses (`TextFont`).
void drawText(
  Canvas canvas,
  String text,
  Offset origin, {
  required double fontSize,
  required Color color,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _fontFamily,
        package: 'notation',
        fontStyle: FontStyle.italic,
        fontSize: fontSize,
        color: color,
        fontFeatures: const [
          FontFeature.disable('kern'),
          FontFeature.disable('liga'),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  // Même piège que drawGlyph : TextPainter peint depuis le haut de la ligne.
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  painter
    ..paint(canvas, origin - Offset(0, baseline))
    ..dispose();
}
