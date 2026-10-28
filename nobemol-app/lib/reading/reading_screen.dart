import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/reading/note_reading.dart';

const _rightColor = Color(0xFF2E7D32);

/// Écran de lecture de notes : une note (seule ou ciblée dans une phrase),
/// 7 boutons, score et chrono.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key, required this.exercise});

  final ReadingExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(exercise));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.readingTitle)),
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
                    ?session.question.target: _targetColor(
                      session,
                      theme.colorScheme,
                    ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              for (final step in DiatonicStep.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _NoteButton(
                      step: step,
                      session: session,
                      onPressed: () => notifier.answer(step),
                    ),
                  ),
                ),
            ],
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

class _NoteButton extends StatelessWidget {
  const _NoteButton({
    required this.step,
    required this.session,
    required this.onPressed,
  });

  final DiatonicStep step;
  final SessionState session;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final feedback = session.phase == SessionPhase.feedback;

    // Correction : la bonne réponse en vert, la mauvaise réponse en rouge.
    final Color? color = switch (step) {
      _ when feedback && step == session.question.answer => _rightColor,
      _ when feedback && step == session.choice => scheme.error,
      _ => null,
    };

    return FilledButton.tonal(
      key: ValueKey('note-${step.name}'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: EdgeInsets.zero,
        backgroundColor: color,
        foregroundColor: color == null ? null : Colors.white,
      ),
      child: Text(AppLocalizations.of(context).noteName(step)),
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
