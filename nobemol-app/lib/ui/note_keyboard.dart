import 'package:flutter/material.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// Touches blanches suivies d'une touche noire : do, ré, fa, sol, la.
const _blackAfter = [
  DiatonicStep.c,
  DiatonicStep.d,
  DiatonicStep.f,
  DiatonicStep.g,
  DiatonicStep.a,
];

/// Écart entre deux touches blanches.
const _gap = 5.0;

/// Clavier d'une octave : 7 touches blanches de do à si, 5 noires.
///
/// Les noires restent inactives tant que les altérations ne se jouent pas
/// au clavier (étape 8) : on ne peut pas les toucher, et un appui sur leur
/// zone tombe sur la blanche dessous.
class NoteKeyboard extends StatelessWidget {
  const NoteKeyboard({
    super.key,
    required this.label,
    required this.onKey,
    this.tones = const {},
    this.height = Sizes.keyHeight,
  });

  /// Nom affiché sur chaque touche blanche.
  final String Function(DiatonicStep step) label;

  /// Appui sur une touche blanche, `null` pour un clavier inactif.
  final ValueChanged<DiatonicStep>? onKey;

  /// Correction : touches justes et fausses. Les autres sont au repos.
  final Map<DiatonicStep, AnswerTone> tones;

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: height + Depths.key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final white = (width - _gap * 6) / 7;
          final black = width * 0.095;
          return Stack(
            children: [
              Row(
                children: [
                  for (final (index, step) in DiatonicStep.values.indexed) ...[
                    if (index > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: white,
                      child: _WhiteKey(
                        key: ValueKey('answer-${step.name}'),
                        label: label(step),
                        tone: tones[step] ?? AnswerTone.rest,
                        height: height,
                        onPressed: onKey == null ? null : () => onKey!(step),
                      ),
                    ),
                  ],
                ],
              ),
              for (final step in _blackAfter)
                Positioned(
                  // Centrée sur l'écart qui suit la blanche.
                  left:
                      (step.index + 1) * (white + _gap) - _gap / 2 - black / 2,
                  top: 0,
                  width: black,
                  height: height * 0.52,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.keyBlackOff,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                          bottom: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WhiteKey extends StatelessWidget {
  const _WhiteKey({
    super.key,
    required this.label,
    required this.tone,
    required this.height,
    required this.onPressed,
  });

  final String label;
  final AnswerTone tone;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colors = switch (tone) {
      AnswerTone.rest => DepthColors(
        background: c.keyWhite,
        foreground: onPressed == null ? c.keyShadow : c.keyLabel,
        shadow: c.keyShadow,
        border: c.keyBorder,
        pressed: c.keyPressed,
      ),
      _ => c.answer(tone),
    };
    return Pressable(
      colors: colors,
      onPressed: onPressed,
      depth: Depths.key,
      height: height,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(6),
        bottom: Radius.circular(Radii.key),
      ),
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: AppText.labelKey),
        ),
      ),
    );
  }
}
