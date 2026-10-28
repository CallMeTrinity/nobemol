import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:notation/src/layout/draw_list.dart';
import 'package:notation/src/layout/layout.dart';
import 'package:notation/src/model/system.dart';
import 'package:notation/src/render/draw_glyph.dart';
import 'package:notation/src/render/draw_text.dart';

/// Dessine un [SystemLayout]. Seule conversion des interlignes en pixels.
class NotationPainter extends CustomPainter {
  /// Crée un painter. [staffSpace] est la taille d'un interligne en pixels.
  new(
    this.layout, {
    required this.staffSpace,
    required this.color,
    this.highlights = const {},
    this.decorationHighlights = const {},
  });

  /// Liste de dessin.
  final SystemLayout layout;

  /// Taille d'un interligne, en pixels.
  final double staffSpace;

  /// Couleur de la notation.
  final Color color;

  /// Couleur propre à certains événements (note ciblée, correction).
  final Map<EventRef, Color> highlights;

  /// Couleur propre aux décorations de certains événements (signe ciblé),
  /// sans leur note.
  final Map<EventRef, Color> decorationHighlights;

  /// Taille en pixels du dessin complet.
  Size get size =>
      Size(layout.bounds.width * staffSpace, layout.bounds.height * staffSpace);

  @override
  void paint(Canvas canvas, Size size) {
    final s = staffSpace;
    final line = Paint()..strokeCap = StrokeCap.butt;
    final fill = Paint();

    canvas
      ..save()
      ..translate(-layout.bounds.left * s, -layout.bounds.top * s);

    for (final command in layout.commands) {
      final color =
          highlights[command.event] ??
          decorationHighlights[command.decoration] ??
          this.color;
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
            line
              ..color = color
              ..strokeWidth = command.thickness * s,
          );
        case BeamCommand(:final x1, :final y1, :final x2, :final y2):
          final half = command.thickness / 2;
          canvas.drawPath(
            Path()
              ..moveTo(x1 * s, (y1 - half) * s)
              ..lineTo(x2 * s, (y2 - half) * s)
              ..lineTo(x2 * s, (y2 + half) * s)
              ..lineTo(x1 * s, (y1 + half) * s)
              ..close(),
            fill..color = color,
          );
        case TieCommand():
          canvas.drawPath(_tiePath(command, s), fill..color = color);
        case TextCommand():
          drawText(
            canvas,
            command.text,
            Offset(command.x * s, command.y * s),
            fontSize: command.size * s,
            color: color,
          );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(NotationPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.staffSpace != staffSpace ||
      oldDelegate.color != color ||
      !mapEquals(oldDelegate.highlights, highlights) ||
      !mapEquals(oldDelegate.decorationHighlights, decorationHighlights);
}

/// Contour d'une liaison : deux arcs de Bézier, l'extérieur puis
/// l'intérieur, écartés de l'épaisseur au milieu et aux bouts.
Path _tiePath(TieCommand tie, double s) {
  final sign = tie.height.sign;

  // Un arc cubique symétrique monte aux 3/4 de ses points de contrôle.
  void arc(Path path, double end, double peak, {required bool back}) {
    final control = tie.y + end + (peak - end) * 4 / 3;
    final (from, to) = back ? (tie.x2, tie.x1) : (tie.x1, tie.x2);
    final step = (to - from) / 4;
    path.cubicTo(
      (from + step) * s,
      control * s,
      (to - step) * s,
      control * s,
      to * s,
      (tie.y + end) * s,
    );
  }

  final end = tie.endThickness / 2;
  final mid = tie.midThickness / 2;
  final path = Path()..moveTo(tie.x1 * s, (tie.y + sign * end) * s);
  arc(path, sign * end, tie.height + sign * mid, back: false);
  path.lineTo(tie.x2 * s, (tie.y - sign * end) * s);
  arc(path, -sign * end, tie.height - sign * mid, back: true);
  return path..close();
}
