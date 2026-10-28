import 'package:flutter/widgets.dart';
import 'package:notation/notation.dart';

/// Un glyphe de la police musicale, à la taille de sa boîte : sans la
/// hauteur de ligne énorme que Bravura donne à un `Text`.
class GlyphView extends StatelessWidget {
  const GlyphView(
    this.glyph, {
    super.key,
    required this.staffSpace,
    this.color,
  });

  final Glyph glyph;

  /// Taille d'un interligne, en pixels (le em vaut 4 interlignes).
  final double staffSpace;

  /// Par défaut, la couleur du texte ambiant.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final (left, bottom) = glyph.bBoxSW;
    final (right, top) = glyph.bBoxNE;
    return CustomPaint(
      size: Size((right - left) * staffSpace, (top - bottom) * staffSpace),
      painter: _GlyphPainter(
        glyph,
        staffSpace: staffSpace,
        color:
            color ??
            DefaultTextStyle.of(context).style.color ??
            const Color(0xFF000000),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, {required this.staffSpace, required this.color});

  final Glyph glyph;
  final double staffSpace;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Origine SMuFL : bord gauche de la boîte, à la hauteur de son haut.
    drawGlyph(
      canvas,
      glyph,
      Offset(-glyph.bBoxSW.$1 * staffSpace, glyph.bBoxNE.$2 * staffSpace),
      staffSpace: staffSpace,
      color: color,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.staffSpace != staffSpace ||
      oldDelegate.color != color;
}
