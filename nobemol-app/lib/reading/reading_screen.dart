import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/fit_words.dart';
import 'package:nobemol/ui/glyph_view.dart';
import 'package:nobemol/ui/note_keyboard.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Écran de lecture : une note (seule ou ciblée dans une phrase), et les
/// réponses possibles en bas : le clavier pour un nom de note, des tuiles
/// pour une durée, des cartes pour le sens d'un signe.
///
/// La session est enregistrée à la dernière réponse. Une session quittée
/// avant n'est pas gardée.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key, required this.exercise, this.lessonId});

  final ReadingExercise exercise;

  /// Leçon de l'exercice, `null` en lecture libre.
  final String? lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(exercise));
    ref.listen(sessionProvider(exercise), (previous, next) {
      if (previous?.finishedAt != null) return;
      if (next.finishedAt case final finishedAt?) {
        unawaited(
          ref
              .read(progressProvider.notifier)
              .recordSession(
                lessonId: lessonId,
                startedAt: next.startedAt,
                finishedAt: finishedAt,
                answers: next.answers,
                bestCombo: next.bestCombo,
              ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: session.phase == SessionPhase.finished
            ? _Results(
                exercise: exercise,
                session: session,
                fromLesson: lessonId != null,
              )
            : _Exercise(exercise: exercise, session: session),
      ),
    );
  }
}

class _Exercise extends ConsumerWidget {
  const _Exercise({required this.exercise, required this.session});

  final ReadingExercise exercise;
  final SessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final notifier = ref.read(sessionProvider(exercise).notifier);
    final (target, halo) = _targetColors(session, c);
    final question = session.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(progress: session.answered / exercise.length, session: session),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.xl, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n
                    .readingProgress(
                      session.answered +
                          (session.phase == SessionPhase.asking ? 1 : 0),
                      exercise.length,
                      session.correct,
                    )
                    .toUpperCase(),
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.s),
              Text(switch (exercise) {
                IdentifyDurationExercise() => l10n.rhythmQuestion,
                IdentifyMarkingExercise() => l10n.markingQuestion,
                _ => l10n.noteQuestion,
              }, style: AppText.titlePrompt.copyWith(color: c.ink)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Space.ml),
            child: Center(
              // scaleDown : la portée garde sa taille, sauf si elle déborde.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NotationView(
                  system: question.system,
                  staffSpace: exercise is NoteReadingParams
                      ? StaffSpaces.exercise
                      : StaffSpaces.phrase,
                  options: exercise.layoutOptions,
                  color: c.ink,
                  highlights: {for (final ref in question.targets) ref: target},
                  halos: {for (final ref in question.targets) ref: halo},
                  decorationHighlights: {
                    for (final ref in question.decorationTargets) ref: target,
                  },
                  decorationHalos: {
                    for (final ref in question.decorationTargets) ref: halo,
                  },
                ),
              ),
            ),
          ),
        ),
        _Dock(
          caption: switch (exercise) {
            NoteReadingParams(accidentals: true) => l10n.keyboardAccidentals,
            NoteReadingParams() => l10n.keyboardNaturals,
            IdentifyNoteExercise(:final system) when _hasAccidentals(system) =>
              l10n.keyboardAccidentals,
            IdentifyNoteExercise() => l10n.keyboardNaturals,
            IdentifyDurationExercise() => l10n.durationsHint,
            IdentifyMarkingExercise() => null,
          },
          child: _Answers(
            exercise: exercise,
            session: session,
            onAnswer: notifier.answer,
          ),
        ),
      ],
    );
  }
}

/// Vrai si une note de [system] porte une altération, écrite ou par
/// l'armure.
bool _hasAccidentals(System system) => system.staves.any(
  (staff) =>
      staff.key.fifths != 0 ||
      staff.notes.any((note) => note.pitch.accidental != null),
);

/// Couleur de la cible et de son halo : accent pendant la question, puis
/// vert ou rouge à la correction.
(Color, Color) _targetColors(SessionState session, NobemolColors c) =>
    switch (session.phase) {
      SessionPhase.asking => (c.accent, c.accentSoft),
      _ when session.choice == session.question.answer => (
        c.success,
        c.successSoft,
      ),
      _ => (c.danger, c.dangerSoft),
    };

/// Fermer, progression, chrono.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.progress, required this.session});

  final double progress;
  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.ml, 0),
      child: Row(
        children: [
          SizedBox.square(
            dimension: Sizes.minTarget,
            child: IconButton(
              key: const ValueKey('close'),
              tooltip: AppLocalizations.of(context).close,
              onPressed: () => context.pop(),
              icon: Icon(Icons.close_rounded, color: c.ink),
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(child: ProgressBar(value: progress)),
          const SizedBox(width: Space.s),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceInverse,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: _Chrono(
              session: session,
              style: AppText.metaLarge.copyWith(color: c.onSurfaceInverse),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bas de l'écran : une légende et les réponses.
class _Dock extends StatelessWidget {
  const _Dock({required this.caption, required this.child});

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
    );
  }
}

/// Réponses de l'exercice, colorées à la correction : la bonne en vert, la
/// mauvaise réponse donnée en rouge.
class _Answers extends StatelessWidget {
  const _Answers({
    required this.exercise,
    required this.session,
    required this.onAnswer,
  });

  final ReadingExercise exercise;
  final SessionState session;
  final ValueChanged<Enum> onAnswer;

  AnswerTone _tone(Enum choice) {
    if (session.phase != SessionPhase.feedback) return AnswerTone.rest;
    if (choice == session.question.answer) return AnswerTone.right;
    if (choice == session.choice) return AnswerTone.wrong;
    return AnswerTone.rest;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = exercise.choices;

    return switch (exercise) {
      NoteReadingParams() || IdentifyNoteExercise() => NoteKeyboard(
        label: l10n.noteName,
        onKey: onAnswer,
        tones: {
          for (final step in DiatonicStep.values)
            if (_tone(step) != AnswerTone.rest) step: _tone(step),
        },
      ),
      IdentifyDurationExercise() => _Grid(
        columns: 4,
        children: [
          for (final choice in choices)
            _AnswerTile(
              key: ValueKey('answer-${choice.name}'),
              tone: _tone(choice),
              height: Sizes.answerTile,
              onPressed: () => onAnswer(choice),
              child: Text(
                l10n.beatsLabel(choice as Beats),
                style: AppText.labelKey.copyWith(fontSize: 24),
              ),
            ),
        ],
      ),
      IdentifyMarkingExercise() => _Grid(
        columns: 3,
        children: [
          for (final choice in choices)
            _AnswerTile(
              key: ValueKey('answer-${choice.name}'),
              tone: _tone(choice),
              height: Sizes.markingCard,
              radius: Radii.buttonLg,
              onPressed: () => onAnswer(choice),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Le signe n'apparaît qu'à la correction : pendant la
                  // question, il suffirait de comparer les formes.
                  if (session.phase == SessionPhase.feedback) ...[
                    SizedBox(
                      height: 28,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _MarkingSign(choice as Marking),
                      ),
                    ),
                    const SizedBox(height: Space.s),
                  ],
                  FitWordsText(
                    l10n.markingLabel(choice as Marking),
                    textAlign: TextAlign.center,
                    style: AppText.labelCard,
                  ),
                ],
              ),
            ),
        ],
      ),
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
  final VoidCallback onPressed;
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

/// Le signe d'un sens : nuance, articulation, soufflet ou terme.
class _MarkingSign extends StatelessWidget {
  const _MarkingSign(this.marking);

  final Marking marking;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (marking) {
      Marking.pianississimo => Glyph.dynamicPPP,
      Marking.pianissimo => Glyph.dynamicPP,
      Marking.piano => Glyph.dynamicPiano,
      Marking.mezzoPiano => Glyph.dynamicMP,
      Marking.mezzoForte => Glyph.dynamicMF,
      Marking.forte => Glyph.dynamicForte,
      Marking.fortissimo => Glyph.dynamicFF,
      Marking.fortississimo => Glyph.dynamicFFF,
      Marking.staccato => Glyph.articStaccatoAbove,
      Marking.tenuto => Glyph.articTenutoAbove,
      Marking.accent => Glyph.articAccentAbove,
      Marking.fermata => Glyph.fermataAbove,
      _ => null,
    };
    if (glyph != null) return GlyphView(glyph, staffSpace: 9);

    final color = DefaultTextStyle.of(context).style.color!;
    return switch (marking) {
      Marking.crescendo || Marking.diminuendo => CustomPaint(
        size: const Size(40, 14),
        painter: _HairpinPainter(
          opening: marking == Marking.crescendo,
          color: color,
        ),
      ),
      _ => Text(
        switch (marking) {
          Marking.ritardando => 'rit.',
          Marking.accelerando => 'accel.',
          Marking.aTempo => 'a tempo',
          Marking.espressivo => 'espress.',
          _ => marking.name,
        },
        style: TextStyle(
          fontFamily: 'Edwin',
          package: 'notation',
          fontStyle: FontStyle.italic,
          fontSize: 18,
          height: 1,
          color: color,
        ),
      ),
    };
  }
}

class _HairpinPainter extends CustomPainter {
  _HairpinPainter({required this.opening, required this.color});

  /// Vrai pour un crescendo : s'ouvre vers la droite.
  final bool opening;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    final (tip, mouth) = opening ? (0.0, size.width) : (size.width, 0.0);
    final middle = size.height / 2;
    canvas
      ..drawLine(Offset(tip, middle), Offset(mouth, 0), paint)
      ..drawLine(Offset(tip, middle), Offset(mouth, size.height), paint);
  }

  @override
  bool shouldRepaint(_HairpinPainter oldDelegate) =>
      oldDelegate.opening != opening || oldDelegate.color != color;
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.exercise,
    required this.session,
    required this.fromLesson,
  });

  final ReadingExercise exercise;
  final SessionState session;
  final bool fromLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final elapsed = session.finishedAt!.difference(session.startedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            l10n.resultTitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppText.meta.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.ml),
          Text(
            l10n.resultScore(session.correct, exercise.length),
            textAlign: TextAlign.center,
            style: AppText.displayXl.copyWith(color: c.ink, fontSize: 64),
          ),
          const SizedBox(height: Space.m),
          Text(
            l10n.resultTime(formatDuration(elapsed)),
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.s),
          Text(
            l10n.resultXp(session.xp),
            textAlign: TextAlign.center,
            style: AppText.titleCard.copyWith(color: c.accentDeep),
          ),
          const Spacer(),
          DepthButton(
            label: l10n.resultRestart,
            onPressed: () => ref.invalidate(sessionProvider(exercise)),
            large: true,
            expand: true,
          ),
          const SizedBox(height: Space.s),
          DepthButton(
            label: fromLesson ? l10n.back : l10n.resultChangeLevel,
            onPressed: () => context.pop(),
            variant: ButtonVariant.outline,
            large: true,
            expand: true,
          ),
        ],
      ),
    );
  }
}

/// Chrono de la session, rafraîchi chaque seconde jusqu'à la fin.
class _Chrono extends ConsumerStatefulWidget {
  const _Chrono({required this.session, required this.style});

  final SessionState session;
  final TextStyle style;

  @override
  ConsumerState<_Chrono> createState() => _ChronoState();
}

class _ChronoState extends ConsumerState<_Chrono> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = widget.session.finishedAt ?? ref.read(clockProvider)();
    return Text(
      formatDuration(end.difference(widget.session.startedAt)),
      style: widget.style.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Durée au format m:ss.
String formatDuration(Duration duration) {
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '${duration.inMinutes}:$seconds';
}
