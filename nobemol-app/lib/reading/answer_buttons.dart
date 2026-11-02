import 'package:flutter/material.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/intervals.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/fit_words.dart';
import 'package:nobemol/ui/note_keyboard.dart';

/// La question posée, au-dessus de la portée.
String questionTitle(AppLocalizations l10n, Question question) =>
    switch (question) {
      NoteQuestion() => l10n.noteQuestion,
      DurationQuestion() => l10n.rhythmQuestion,
      MarkingQuestion() => l10n.markingQuestion,
      IntervalQuestion(heard: true) => l10n.earIntervalQuestion,
      IntervalQuestion() => l10n.intervalQuestion,
      EarNoteQuestion() => l10n.earNoteQuestion,
      TapQuestion() => l10n.tapQuestion,
    };

/// Légende des réponses, `null` pour des cartes de signes, qui se lisent
/// seules. Un rythme tapé a la sienne, avec son tempo.
String? answerCaption(
  AppLocalizations l10n,
  Question question,
  List<Enum> choices,
) => switch (question) {
  NoteQuestion() =>
    opensBlackKeys(choices) ? l10n.keyboardAccidentals : l10n.keyboardNaturals,
  DurationQuestion() => l10n.durationsHint,
  MarkingQuestion() || TapQuestion() => null,
  IntervalQuestion() => l10n.intervalsHint,
  EarNoteQuestion() => l10n.keyboardNaturals,
};

/// Vrai si les touches noires du clavier sont ouvertes.
bool opensBlackKeys(List<Enum> choices) =>
    choices.any((choice) => choice is NoteName && choice.accidental != null);

/// Bas de l'écran : une légende, puis les réponses. Toujours au moins
/// [Sizes.answerDock] de haut : la place du panneau de correction.
class AnswerDock extends StatelessWidget {
  const AnswerDock({super.key, required this.caption, required this.child});

  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.sheet),
        ),
        boxShadow: [BoxShadow(color: c.line, offset: const Offset(0, -1))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.m,
            Space.ml,
            Space.m,
            Space.l,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.answerDock),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (caption case final caption?) ...[
                  Text(
                    caption.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppText.meta.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: Space.m),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Réponses à choisir : le clavier pour un nom de note, des tuiles pour une
/// durée ou un intervalle, des cartes pour le sens d'un signe. Chacune
/// prend la couleur que lui donne [tone]. Pas pour un rythme tapé, qui se
/// joue sur son propre bouton.
class AnswerButtons extends StatelessWidget {
  const AnswerButtons({
    super.key,
    required this.question,
    required this.choices,
    required this.tone,
    required this.onAnswer,
    required this.naming,
    required this.keyLabels,
  });

  final Question question;
  final List<Enum> choices;
  final AnswerTone Function(Enum choice) tone;

  /// `null` : les réponses ne répondent plus.
  final ValueChanged<Enum>? onAnswer;
  final NoteNaming naming;

  /// Noms sur les touches blanches.
  final bool keyLabels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onAnswer = this.onAnswer;
    VoidCallback? pressed(Enum choice) =>
        onAnswer == null ? null : () => onAnswer(choice);

    return switch (question) {
      NoteQuestion() || EarNoteQuestion() => NoteKeyboard(
        label: (name) => l10n.noteFullName(name, naming: naming),
        whiteLabels: keyLabels,
        onKey: onAnswer,
        accidentals: opensBlackKeys(choices),
        tones: {
          for (final name in NoteName.values)
            if (tone(name) != AnswerTone.rest) name: tone(name),
        },
      ),
      DurationQuestion() => _Grid(
        columns: 4,
        children: [
          for (final choice in choices)
            _AnswerTile(
              key: ValueKey('answer-${choice.name}'),
              tone: tone(choice),
              height: Sizes.answerTile,
              onPressed: pressed(choice),
              child: Text(
                l10n.beatsLabel(choice as Beats),
                style: AppText.labelKey.copyWith(fontSize: 24),
              ),
            ),
        ],
      ),
      IntervalQuestion() => _Grid(
        columns: 4,
        children: [
          for (final choice in choices)
            _AnswerTile(
              key: ValueKey('answer-${choice.name}'),
              tone: tone(choice),
              height: Sizes.answerTile,
              onPressed: pressed(choice),
              child: FitWordsText(
                l10n.intervalLabel(choice as IntervalNumber),
                textAlign: TextAlign.center,
                style: AppText.labelCard,
              ),
            ),
        ],
      ),
      MarkingQuestion() => _Grid(
        columns: 3,
        children: [
          for (final choice in choices)
            _AnswerTile(
              key: ValueKey('answer-${choice.name}'),
              tone: tone(choice),
              height: Sizes.markingCard,
              radius: Radii.buttonLg,
              onPressed: pressed(choice),
              // Le sens seul : le signe se montre dans la correction.
              child: FitWordsText(
                l10n.markingLabel(choice as Marking),
                textAlign: TextAlign.center,
                style: AppText.labelCard,
              ),
            ),
        ],
      ),
      TapQuestion() => const SizedBox.shrink(),
    };
  }
}

/// Grille de colonnes égales, remplie ligne par ligne.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += columns)
          Padding(
            padding: EdgeInsets.only(top: start == 0 ? 0 : Space.s),
            child: Row(
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) const SizedBox(width: Space.xs),
                  Expanded(
                    child: i < children.length
                        ? children[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    super.key,
    required this.tone,
    required this.height,
    required this.onPressed,
    required this.child,
    this.radius = Radii.button,
  });

  final AnswerTone tone;
  final double height;
  final double radius;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      colors: context.colors.answer(tone),
      onPressed: onPressed,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Center(child: child),
    );
  }
}
