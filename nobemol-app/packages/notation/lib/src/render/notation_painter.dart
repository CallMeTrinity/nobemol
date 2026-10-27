import 'package:flutter/rendering.dart';
import 'package:notation/src/layout/draw_list.dart';
import 'package:notation/src/layout/layout.dart';
import 'package:notation/src/render/draw_glyph.dart';

/// Dessine un [SystemLayout]. Seule conversion des interlignes en pixels.
class NotationPainter extends CustomPainter {
  /// Crée un painter. [staffSpace] est la taille d'un interligne en pixels.
  new(this.layout, {required this.staffSpace, required this.color});

  /// Liste de dessin.
  final SystemLayout layout;

  /// Taille d'un interligne, en pixels.
  final double staffSpace;

  /// Couleur de la notation.
  final Color color;

  /// Taille en pixels du dessin complet.
  Size get size =>
      Size(layout.bounds.width * staffSpace, layout.bounds.height * staffSpace);

  @override
  void paint(Canvas canvas, Size size) {
    final s = staffSpace;
    final line = Paint()
      ..color = color
      ..strokeCap = StrokeCap.butt;

    canvas
      ..save()
      ..translate(-layout.bounds.left * s, -layout.bounds.top * s);

    for (final command in layout.commands) {
      switch (command) {
        case GlyphCommand():
          drawGlyph(
            canvas,
            command.glyph,
            Offset(command.x * s, command.y * s),
            staffSpace: s,
            color: color,
            scaleX: command.scaleX,
            scaleY: command.scaleY,
          );
        case LineCommand():
          canvas.drawLine(
            Offset(command.x1 * s, command.y1 * s),
            Offset(command.x2 * s, command.y2 * s),
            line..strokeWidth = command.thickness * s,
          );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(NotationPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.staffSpace != staffSpace ||
      oldDelegate.color != color;
}
