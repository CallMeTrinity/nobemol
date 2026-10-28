import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/reading/note_reading.dart';

const _rightColor = Color(0xFF2E7D32);

/// Écran de lecture : une note (seule ou ciblée dans une phrase), un bouton
/// par réponse possible (nom de note ou durée), score et chrono.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key, required this.exercise});

  final ReadingExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(exercise));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (exercise) {
          IdentifyDurationExercise() => l10n.rhythmTitle,
          IdentifyMarkingExercise() => l10n.symbolsTitle,
          _ => l10n.readingTitle,
        }),
      ),
      body: SafeArea(
        child: session.phase == SessionPhase.finished
            ? _Results(exercise: exercise, session: session)
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
    final theme = Theme.of(context);
    final notifier = ref.read(sessionProvider(exercise).notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(value: session.answered / exercise.length),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.readingScore(session.correct)),
              const Spacer(),
              _Chrono(session: session),
            ],
          ),
          // SizedBox.expand : le FittedBox agrandit la portée jusqu'à
          // remplir la place, il ne fait pas que la réduire.
          Expanded(
            child: SizedBox.expand(
              child: FittedBox(
                child: NotationView(
                  system: session.question.system,
                  staffSpace: 24,
                  options: exercise.layoutOptions,
                  color: theme.colorScheme.onSurface,
                  highlights: {
                    for (final target in session.question.targets)
                      target: _targetColor(session, theme.colorScheme),
                  },
                  decorationHighlights: {
                    for (final target in session.question.decorationTargets)
                      target: _targetColor(session, theme.colorScheme),
                  },
                ),
              ),
            ),
          ),
          Text(
            l10n.readingProgress(
              session.answered + (session.phase == SessionPhase.asking ? 1 : 0),
              exercise.length,
            ),
            style: theme.textTheme.labelLarge,
          ),
          if (switch (exercise) {
                IdentifyDurationExercise() => l10n.rhythmQuestion,
                IdentifyMarkingExercise() => l10n.markingQuestion,
                _ => null,
              }
              case final question?) ...[
            const SizedBox(height: 8),
            Text(question, style: theme.textTheme.titleMedium),
          ],
          const SizedBox(height: 16),
          for (final row in _rows(
            exercise.choices,
            perRow: exercise is IdentifyMarkingExercise ? 2 : 7,
          ))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  for (final choice in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _AnswerButton(
                          choice: choice,
                          session: session,
                          onPressed: () => notifier.answer(choice),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Note ciblée : couleur d'accent pendant la question, puis verte ou rouge à
/// la correction. Pas `primary` : dans le thème de l'appli, c'est l'encre
/// des notes.
Color _targetColor(SessionState session, ColorScheme scheme) =>
    switch (session.phase) {
      SessionPhase.asking => scheme.secondary,
      _ when session.choice == session.question.answer => _rightColor,
      _ => scheme.error,
    };

/// Boutons répartis en lignes égales d'au plus [perRow] : les 7 notes sur
/// une ligne, les 8 durées sur deux, le sens des signes (des mots) par deux.
List<List<Enum>> _rows(List<Enum> choices, {required int perRow}) {
  final count = (choices.length + perRow - 1) ~/ perRow;
  final size = (choices.length + count - 1) ~/ count;
  return [
    for (var start = 0; start < choices.length; start += size)
      choices.sublist(start, min(start + size, choices.length)),
  ];
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.choice,
    required this.session,
    required this.onPressed,
  });

  final Enum choice;
  final SessionState session;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final feedback = session.phase == SessionPhase.feedback;

    // Correction : la bonne réponse en vert, la mauvaise réponse en rouge.
    final Color? color = switch (choice) {
      _ when feedback && choice == session.question.answer => _rightColor,
      _ when feedback && choice == session.choice => scheme.error,
      _ => null,
    };

    return FilledButton.tonal(
      key: ValueKey('answer-${choice.name}'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: EdgeInsets.zero,
        backgroundColor: color,
        foregroundColor: color == null ? null : Colors.white,
      ),
      child: Text(
        AppLocalizations.of(context).answerLabel(choice),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.exercise, required this.session});

  final ReadingExercise exercise;
  final SessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final elapsed = session.finishedAt!.difference(session.startedAt);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.resultTitle,
            style: text.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.resultScore(session.correct, exercise.length),
            style: text.displayMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.resultTime(formatDuration(elapsed)),
            style: text.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => ref.invalidate(sessionProvider(exercise)),
            child: Text(l10n.resultRestart),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: Text(l10n.resultChangeLevel),
          ),
        ],
      ),
    );
  }
}

/// Chrono de la session, rafraîchi chaque seconde jusqu'à la fin.
class _Chrono extends ConsumerStatefulWidget {
  const _Chrono({required this.session});

  final SessionState session;

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
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}

/// Durée au format m:ss.
String formatDuration(Duration duration) {
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '${duration.inMinutes}:$seconds';
}
