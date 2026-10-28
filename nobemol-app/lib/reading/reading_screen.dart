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

/// Écran de lecture de notes : une note, 7 boutons, score et chrono.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key, required this.params});

  final NoteReadingParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(params));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.readingTitle)),
      body: SafeArea(
        child: session.phase == SessionPhase.finished
            ? _Results(params: params, session: session)
            : _Exercise(params: params, session: session),
      ),
    );
  }
}

class _Exercise extends ConsumerWidget {
  const _Exercise({required this.params, required this.session});

  final NoteReadingParams params;
  final SessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notifier = ref.read(sessionProvider(params).notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(value: session.answered / sessionLength),
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
                  options: params.layoutOptions,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Text(
            l10n.readingProgress(
              session.answered + (session.phase == SessionPhase.asking ? 1 : 0),
              sessionLength,
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
  const _Results({required this.params, required this.session});

  final NoteReadingParams params;
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
            l10n.resultScore(session.correct, sessionLength),
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
            onPressed: () => ref.invalidate(sessionProvider(params)),
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
