import 'dart:math';

import 'package:flutter/widgets.dart';

/// Texte qui passe à la ligne entre les mots, jamais au milieu d'un mot :
/// si le mot le plus long ne tient pas sur la largeur, tout le texte
/// rapetisse (« supplémentaires » dans une tuile étroite).
class FitWordsText extends StatelessWidget {
  const FitWordsText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(this.style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        var widest = 0.0;
        for (final word in text.split(RegExp(r'\s+'))) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: style),
            textDirection: direction,
            textScaler: scaler,
          )..layout();
          widest = max(widest, painter.width);
          painter.dispose();
        }
        // Une marge d'un pixel : l'arrondi ne doit pas couper le mot.
        final available = constraints.maxWidth - 1;
        final fontSize = style.fontSize!;
        return Text(
          text,
          textAlign: textAlign,
          style: widest <= available
              ? style
              : style.copyWith(fontSize: fontSize * available / widest),
        );
      },
    );
  }
}
