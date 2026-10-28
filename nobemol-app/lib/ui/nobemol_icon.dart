import 'package:flutter/widgets.dart';

/// Icône de l'appli (`nobemol-icone.svg`), redessinée : pas de dépendance
/// SVG pour deux formes.
class NobemolIcon extends StatelessWidget {
  const NobemolIcon({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _IconPainter());
}

class _IconPainter extends CustomPainter {
  const _IconPainter();

  static const _ink = Color(0xFF1C2033);
  static const _paper = Color(0xFFF4EEE2);
  static const _accent = Color(0xFFEF5B36);

  @override
  void paint(Canvas canvas, Size size) {
    // Coordonnées du SVG : carré de 512, dessin de 100 centré et agrandi
    // 3,5 fois.
    final unit = size.width / 512;
    Offset p(double x, double y) =>
        Offset(256 + 3.5 * (x - 50), 256 + 3.5 * (y - 51)) * unit;
    Path polygon(List<(double, double)> points) =>
        Path()..addPolygon([for (final (x, y) in points) p(x, y)], true);

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(115 * unit),
        ),
        Paint()..color = _ink,
      )
      ..drawPath(
        polygon([(62, 66), (72, 64), (72, 94), (62, 94)]),
        Paint()..color = _accent,
      )
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          polygon([
            (28, 8),
            (38, 8),
            (38, 36.182),
            (72, 30),
            (72, 70),
            (28, 78),
          ]),
          polygon([(38, 46.182), (62, 41.818), (62, 61.818), (38, 66.182)]),
        ),
        Paint()..color = _paper,
      );
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) => false;
}
