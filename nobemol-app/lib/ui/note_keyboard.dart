import 'package:flutter/material.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/reading/note_name.dart';
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

/// Largeur d'un bouton d'orthographe (« fa dièse »).
const _spellingWidth = 96.0;

/// Clavier d'une octave : 7 touches blanches de do à si, 5 noires.
///
/// Avec [accidentals], une touche noire ouvre une bulle : le dièse de la
/// blanche d'avant, ou le bémol de celle d'après. Sinon les noires restent
/// inactives : un appui sur leur zone tombe sur la blanche dessous.
class NoteKeyboard extends StatefulWidget {
  const NoteKeyboard({
    super.key,
    required this.label,
    required this.onKey,
    this.accidentals = false,
    this.tones = const {},
    this.height = Sizes.keyHeight,
  });

  /// Nom d'une note : sur les touches blanches et dans la bulle.
  final String Function(NoteName name) label;

  /// Nom choisi, `null` pour un clavier inactif.
  final ValueChanged<NoteName>? onKey;

  /// Touches noires actives.
  final bool accidentals;

  /// Correction : réponses justes et fausses. Une touche noire prend la
  /// couleur de ses deux noms.
  final Map<NoteName, AnswerTone> tones;

  final double height;

  @override
  State<NoteKeyboard> createState() => _NoteKeyboardState();
}

class _NoteKeyboardState extends State<NoteKeyboard> {
  /// Touche noire touchée, en attente de son orthographe.
  DiatonicStep? _open;

  @override
  void didUpdateWidget(NoteKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Une correction, ou un clavier inactif : la bulle se ferme.
    if (widget.onKey == null || widget.tones.isNotEmpty) _open = null;
  }

  void _choose(NoteName name) {
    setState(() => _open = null);
    widget.onKey?.call(name);
  }

  AnswerTone _blackTone(DiatonicStep after) {
    for (final MapEntry(key: name, value: tone) in widget.tones.entries) {
      if (name.blackKey == after) return tone;
    }
    return AnswerTone.rest;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = widget.height;
    final onKey = widget.onKey;
    final active = widget.accidentals && onKey != null;

    return SizedBox(
      height: height + Depths.key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final white = (width - _gap * 6) / 7;
          final black = width * 0.095;
          double blackLeft(DiatonicStep after) =>
              (after.index + 1) * (white + _gap) - _gap / 2 - black / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  for (final (index, name) in NoteName.naturals.indexed) ...[
                    if (index > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: white,
                      child: _WhiteKey(
                        key: ValueKey('answer-${name.name}'),
                        label: widget.label(name),
                        tone: widget.tones[name] ?? AnswerTone.rest,
                        height: height,
                        onPressed: onKey == null ? null : () => _choose(name),
                      ),
                    ),
                  ],
                ],
              ),
              for (final after in _blackAfter)
                Positioned(
                  // Centrée sur l'écart qui suit la blanche.
                  left: blackLeft(after),
                  top: 0,
                  width: black,
                  height: height * 0.52,
                  child: _BlackKey(
                    key: ValueKey('black-${after.name}'),
                    tone: _blackTone(after),
                    open: _open == after,
                    onPressed: active
                        ? () => setState(
                            () => _open = _open == after ? null : after,
                          )
                        : null,
                    color: widget.accidentals ? c.keyBlack : c.keyBlackOff,
                  ),
                ),
              if (_open case final after?)
                Positioned(
                  left: (blackLeft(after) + black / 2 - _spellingWidth - 3)
                      .clamp(0, width - 2 * _spellingWidth - 6),
                  top: height * 0.52 + Space.s,
                  child: _Spelling(
                    names: [
                      NoteName.of(after, Accidental.sharp)!,
                      NoteName.of(
                        DiatonicStep.values[after.index + 1],
                        Accidental.flat,
                      )!,
                    ],
                    label: widget.label,
                    onChoose: _choose,
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

/// Touche noire. Inactive, elle laisse passer l'appui vers la blanche
/// dessous.
class _BlackKey extends StatelessWidget {
  const _BlackKey({
    super.key,
    required this.tone,
    required this.open,
    required this.onPressed,
    required this.color,
  });

  final AnswerTone tone;

  /// Sa bulle est ouverte.
  final bool open;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final background = switch (tone) {
      AnswerTone.right => c.success,
      AnswerTone.wrong => c.danger,
      AnswerTone.rest => open ? c.accent : color,
    };
    final key = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(4),
          bottom: Radius.circular(8),
        ),
      ),
      child: const SizedBox.expand(),
    );
    if (onPressed == null) return IgnorePointer(child: key);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: key,
      ),
    );
  }
}

/// Bulle sous une touche noire : ses deux orthographes.
class _Spelling extends StatelessWidget {
  const _Spelling({
    required this.names,
    required this.label,
    required this.onChoose,
  });

  final List<NoteName> names;
  final String Function(NoteName name) label;
  final ValueChanged<NoteName> onChoose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, name) in names.indexed) ...[
          if (index > 0) const SizedBox(width: Space.xs),
          SizedBox(
            width: _spellingWidth,
            child: Pressable(
              key: ValueKey('answer-${name.name}'),
              colors: DepthColors(
                background: c.surfaceInverse,
                foreground: c.onSurfaceInverse,
                shadow: c.inkDeep,
              ),
              onPressed: () => onChoose(name),
              depth: Depths.tile,
              height: Sizes.chip + 8,
              borderRadius: BorderRadius.circular(Radii.sm),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label(name),
                    style: AppText.labelKey.copyWith(fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
