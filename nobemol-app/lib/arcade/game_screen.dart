import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/achievements/achievement.dart';
import 'package:nobemol/arcade/arcade.dart';
import 'package:nobemol/arcade/arcade_screen.dart';
import 'package:nobemol/arcade/game.dart';
import 'package:nobemol/clock.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/note_keyboard.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Une image sur trente : la barre de temps avance sans à-coups.
const _frame = Duration(milliseconds: 33);

/// Partie d'arcade : une note, le clavier, et le temps qui file. La
/// correction se lit sur la cible et la touche, puis la note suivante
/// arrive seule : ni panneau ni explication.
///
/// La partie est enregistrée à sa fin. Quitter, retour du téléphone ou
/// appli en arrière-plan : d'abord la pause.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.game});

  final ArcadeGame game;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _ticker;
  late final AppLifecycleListener _lifecycle;

  /// Record d'avant la partie, pour dire s'il est battu.
  int? _previousRecord;

  /// Enregistrement de la partie finie : les succès qu'elle débloque.
  Future<SessionOutcome>? _outcome;

  ArcadeGame get _game => widget.game;
  ArcadeNotifier get _notifier => ref.read(arcadeProvider(_game).notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onInactive: () => _notifier.pause());
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _start() {
    _previousRecord = ref.read(progressProvider).records[_game.record];
    _ticker?.cancel();
    _ticker = Timer.periodic(_frame, (_) {
      _notifier.tick();
      // La barre de temps suit l'horloge, pas l'état.
      if (mounted) setState(() {});
    });
  }

  void _replay() {
    ref.invalidate(arcadeProvider(_game));
    _outcome = null;
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arcadeProvider(_game));
    ref.listen(arcadeProvider(_game), (previous, next) {
      if (previous?.phase == ArcadePhase.asking &&
          next.phase == ArcadePhase.flash &&
          ref.read(settingsProvider).haptics) {
        unawaited(
          next.answers.last.correct
              ? HapticFeedback.lightImpact()
              : HapticFeedback.vibrate(),
        );
      }
      if (previous?.finishedAt != null) return;
      if (next.finishedAt case final finishedAt?) {
        _ticker?.cancel();
        // Une partie sans réponse n'a rien à garder.
        if (next.answers.isEmpty) return;
        setState(() {
          _outcome = ref
              .read(progressProvider.notifier)
              .recordSession(
                lessonId: null,
                startedAt: next.startedAt,
                finishedAt: finishedAt,
                answers: next.answers,
                bestCombo: next.bestCombo,
                arcade: _game.record,
                score: next.score,
              );
        });
      }
    });
    final finished = state.phase == ArcadePhase.finished;

    return PopScope(
      // Retour du téléphone : la pause, qui propose de quitter.
      canPop: finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _notifier.pause();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: finished
              ? _End(
                  game: _game,
                  state: state,
                  previousRecord: _previousRecord,
                  outcome: _outcome,
                  onReplay: _replay,
                )
              : Stack(
                  children: [
                    _Play(game: _game, state: state),
                    if (state.paused)
                      Positioned.fill(
                        child: _Pause(
                          onResume: _notifier.resume,
                          onQuit: () => context.pop(),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Play extends ConsumerWidget {
  const _Play({required this.game, required this.state});

  final ArcadeGame game;
  final ArcadeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(arcadeProvider(game).notifier);
    final question = state.question;
    final flash = state.phase == ArcadePhase.flash;
    final right = flash && state.choice == question.answer;
    final (target, halo) = !flash
        ? (c.accent, c.accentSoft)
        : right
        ? (c.success, c.successSoft)
        : (c.danger, c.dangerSoft);
    final reserve = game.stages
        .map((params) => params.ledgerLines + 2.5)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(game: game, state: state, onPause: notifier.pause),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.xl, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l10n.arcadeScore(game.mode, state.score),
                  key: const ValueKey('arcade-score'),
                  style: AppText.titleScreen.copyWith(color: c.ink),
                ),
              ),
              if (state.combo >= 2)
                Text(
                  game.mode == ArcadeMode.chrono
                      ? '×${comboMultiplier(state.combo)}'
                      : '×${state.combo}',
                  style: AppText.metaLarge.copyWith(color: c.accentDeep),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Space.ml),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NotationView(
                  system: question.system,
                  staffSpace: StaffSpaces.exercise,
                  options: LayoutOptions(
                    reserveAbove: reserve,
                    reserveBelow: reserve,
                  ),
                  color: c.ink,
                  highlights: {question.target: target},
                  halos: {question.target: halo},
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
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
              child: NoteKeyboard(
                label: (name) =>
                    l10n.noteFullName(name, naming: settings.naming),
                whiteLabels: settings.keyLabels,
                onKey: state.phase == ArcadePhase.asking && !state.paused
                    ? notifier.answer
                    : null,
                accidentals: notifier.choices.length > NoteName.naturals.length,
                // Une erreur allume aussi la bonne touche.
                tones: {
                  if (flash) question.answer: AnswerTone.right,
                  if (flash && !right)
                    if (state.choice case final NoteName given)
                      given: AnswerTone.wrong,
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pause, temps restant (barre et chrono ou vies).
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.game,
    required this.state,
    required this.onPause,
  });

  final ArcadeGame game;
  final ArcadeState state;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    // Figée en pause, et pendant la correction à l'instant de la réponse.
    final now =
        state.pausedAt ??
        (state.phase == ArcadePhase.flash
            ? state.askedAt.add(state.answers.last.elapsed)
            : ref.read(clockProvider)());
    final (left, total) = switch (state) {
      ArcadeState(:final endsAt?) => (endsAt.difference(now), chronoLength),
      ArcadeState(:final deadline?) => (
        deadline.difference(now),
        noteTime(state.correct),
      ),
      _ => (Duration.zero, chronoLength),
    };
    // Entraînement : pas de temps, la barre suit les notes.
    final practice = game.mode == ArcadeMode.practice;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.ml, 0),
      child: Row(
        children: [
          SizedBox.square(
            dimension: Sizes.minTarget,
            child: IconButton(
              key: const ValueKey('pause'),
              tooltip: l10n.arcadePause,
              onPressed: onPause,
              icon: Icon(Icons.pause_rounded, color: c.ink),
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: ProgressBar(
              value: practice
                  ? state.answers.length / practiceLength
                  : (left.inMilliseconds / total.inMilliseconds).clamp(0, 1),
            ),
          ),
          const SizedBox(width: Space.s),
          if (game.mode == ArcadeMode.chrono)
            Text(
              formatDuration(
                Duration(seconds: (left.inMilliseconds / 1000).ceil()),
              ),
              style: AppText.metaLarge.copyWith(
                color: c.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          else if (practice)
            Text(
              l10n.arcadeProgress(state.answers.length, practiceLength),
              key: const ValueKey('practice-progress'),
              style: AppText.metaLarge.copyWith(
                color: c.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          else if (game.mode == ArcadeMode.survival)
            Row(
              key: const ValueKey('lives'),
              children: [
                for (var i = 0; i < survivalLives; i++)
                  Icon(
                    i < state.lives
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: c.danger,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// La note est cachée : la pause ne sert pas à la lire.
class _Pause extends StatelessWidget {
  const _Pause({required this.onResume, required this.onQuit});

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return ColoredBox(
      color: c.bg,
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.arcadePaused,
              textAlign: TextAlign.center,
              style: AppText.titleScreen.copyWith(color: c.ink),
            ),
            const SizedBox(height: Space.s),
            Text(
              l10n.arcadeQuitBody,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.xl),
            DepthButton(
              key: const ValueKey('resume'),
              label: l10n.arcadeResume,
              onPressed: onResume,
              large: true,
              expand: true,
            ),
            const SizedBox(height: Space.s),
            DepthButton(
              key: const ValueKey('quit'),
              label: l10n.arcadeQuit,
              variant: ButtonVariant.text,
              onPressed: onQuit,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fin de partie : le score et le record, puis le détail.
class _End extends StatelessWidget {
  const _End({
    required this.game,
    required this.state,
    required this.previousRecord,
    required this.outcome,
    required this.onReplay,
  });

  final ArcadeGame game;
  final ArcadeState state;
  final int? previousRecord;

  /// `null` pour une partie sans réponse, qui n'est pas gardée.
  final Future<SessionOutcome>? outcome;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final previous = previousRecord;
    // L'entraînement n'a pas de record : ses réglages changent tout.
    final ranked = game.mode != ArcadeMode.practice;
    final newRecord =
        ranked &&
        state.score > 0 &&
        (previous == null || state.score > previous);
    final answered = state.answers.length;
    final misses = answered - state.correct;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.body.copyWith(color: c.inkMuted)),
          ),
          Text(value, style: AppText.metaLarge.copyWith(color: c.ink)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xxl,
              Space.xl,
              Space.l,
            ),
            children: [
              Text(
                l10n.arcadeOver.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.ml),
              Text(
                l10n.arcadeScore(game.mode, state.score),
                textAlign: TextAlign.center,
                style: AppText.displayXl.copyWith(color: c.ink, fontSize: 48),
              ),
              // Sans record ni point, rien à dire.
              if (newRecord || ranked && previous != null) ...[
                const SizedBox(height: Space.m),
                Text(
                  newRecord
                      ? l10n.arcadeNewRecord
                      : l10n.arcadeRecord(
                          l10n.arcadeScore(game.mode, previous!),
                        ),
                  key: const ValueKey('arcade-record'),
                  textAlign: TextAlign.center,
                  style: AppText.titleCard.copyWith(
                    color: newRecord ? c.accentDeep : c.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: Space.xl),
              AppTile(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    row(l10n.arcadeCorrect, '${state.correct} / $answered'),
                    row(
                      l10n.arcadeAccuracy,
                      answered == 0
                          ? '–'
                          : '${(state.correct * 100 / answered).round()} %',
                    ),
                    row(l10n.arcadeTimePerNote, switch (state.timePerNote) {
                      final time? => l10n.arcadeSeconds(
                        (time.inMilliseconds / 1000)
                            .toStringAsFixed(1)
                            .replaceAll('.', ','),
                      ),
                      null => '–',
                    }),
                    Divider(color: c.line, height: Space.m),
                    row(l10n.resultXpTotal, l10n.resultXp(state.xp)),
                  ],
                ),
              ),
              if (misses > 0) ...[
                const SizedBox(height: Space.m),
                Text(
                  l10n.arcadeToReview(misses),
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: c.inkMuted),
                ),
              ],
              // Pas d'écran de palier après une partie : les succès sont ici.
              FutureBuilder(
                future: outcome,
                builder: (context, snapshot) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final achievement
                        in snapshot.data?.achievements ?? const <Achievement>[])
                      Padding(
                        padding: const EdgeInsets.only(top: Space.s),
                        child: AppTile(
                          key: ValueKey('achievement-${achievement.id}'),
                          highlighted: true,
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events_rounded, color: c.accent),
                              const SizedBox(width: Space.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.milestoneAchievement.toUpperCase(),
                                      style: AppText.meta.copyWith(
                                        color: c.accentDeep,
                                      ),
                                    ),
                                    const SizedBox(height: Space.xs),
                                    Text(
                                      achievement.title,
                                      style: AppText.titleCard.copyWith(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.s,
              Space.xl,
              Space.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DepthButton(
                  key: const ValueKey('arcade-replay'),
                  label: l10n.arcadeReplay,
                  onPressed: onReplay,
                  large: true,
                  expand: true,
                ),
                const SizedBox(height: Space.s),
                DepthButton(
                  key: const ValueKey('arcade-done'),
                  label: l10n.arcadeDone,
                  onPressed: () => context.pop(),
                  variant: ButtonVariant.outline,
                  large: true,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
