import 'dart:math' as math;

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
    this.halos = const {},
    this.decorationHalos = const {},
    this.labelStyle = const TextStyle(),
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

  /// Pastille de couleur derrière la tête de certains événements (cible).
  final Map<EventRef, Color> halos;

  /// Pastille de couleur derrière les décorations de certains événements.
  final Map<EventRef, Color> decorationHalos;

  /// Police et couleur des noms sous les notes, ceux de l'interface. Sa
  /// taille est celle du layout. Sans couleur, celle de la notation ; une
  /// note colorée colore aussi son nom.
  final TextStyle labelStyle;

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

    _paintHalos(canvas);
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
        case LabelCommand():
          _paintLabel(
            canvas,
            command,
            highlights[command.event] ?? labelStyle.color ?? this.color,
          );
      }
    }

    canvas.restore();
  }

  /// Halos, sous tout le reste, portée comprise : les lignes restent
  /// visibles à travers.
  void _paintHalos(Canvas canvas) {
    final s = staffSpace;
    final paint = Paint();
    for (final MapEntry(key: ref, value: color) in halos.entries) {
      final head = layout.heads[ref];
      if (head == null) continue;
      // Un cercle autour de la tête : décalé vers l'altération, s'il y en a
      // une, et assez grand pour la contenir.
      final radius = math.max(head.width, head.height) / 2 + _haloPadding * 2;
      canvas.drawCircle(
        Offset(
          (head.left + head.right) / 2 * s,
          (head.top + head.bottom) / 2 * s,
        ),
        radius * s,
        paint..color = color,
      );
    }
    for (final MapEntry(key: ref, value: color) in decorationHalos.entries) {
      final box = layout.commands
          .where((command) => command.decoration == ref)
          .map((command) => command.bounds)
          .fold<Box?>(null, (box, other) => box?.union(other) ?? other);
      if (box == null) continue;
      final halo = box.inflate(_haloPadding);
      canvas.drawRRect(
        RRect.fromLTRBR(
          halo.left * s,
          halo.top * s,
          halo.right * s,
          halo.bottom * s,
          const Radius.circular(_haloRadius) * s,
        ),
        paint..color = color,
      );
    }
  }

  void _paintLabel(Canvas canvas, LabelCommand label, Color color) {
    final s = staffSpace;
    final painter = TextPainter(
      text: TextSpan(
        text: label.text,
        style: labelStyle.copyWith(fontSize: label.size * s, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Même piège que drawGlyph : TextPainter peint depuis le haut de la
    // ligne.
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter
      ..paint(
        canvas,
        Offset(label.x * s - painter.width / 2, label.y * s - baseline),
      )
      ..dispose();
  }

  @override
  bool shouldRepaint(NotationPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.staffSpace != staffSpace ||
      oldDelegate.color != color ||
      !mapEquals(oldDelegate.highlights, highlights) ||
      !mapEquals(oldDelegate.decorationHighlights, decorationHighlights) ||
      !mapEquals(oldDelegate.halos, halos) ||
      !mapEquals(oldDelegate.decorationHalos, decorationHalos) ||
      oldDelegate.labelStyle != labelStyle;
}

/// Marge d'un halo autour d'une décoration, en interlignes. Le cercle d'une
/// tête en a le double.
const _haloPadding = 0.55;

/// Rayon des coins du halo d'une décoration, en interlignes.
const _haloRadius = 0.8;

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
