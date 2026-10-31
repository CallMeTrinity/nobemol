import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/arcade/arcade.dart';
import 'package:nobemol/clock.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/review/card.dart';

/// Couleur de la correction sur la cible, puis la note suivante. Une
/// erreur reste plus longtemps : la bonne touche s'allume.
const rightFlash = Duration(milliseconds: 150);
const wrongFlash = Duration(milliseconds: 600);

/// Partie d'arcade en cours.
final arcadeProvider = NotifierProvider.autoDispose
    .family<ArcadeNotifier, ArcadeState, ArcadeGame>(ArcadeNotifier.new);

enum ArcadePhase {
  /// En attente d'une réponse.
  asking,

  /// La cible est colorée, la note suivante arrive seule.
  flash,

  /// Temps écoulé, erreur de trop ou plus de vies.
  finished,
}

class ArcadeState {
  const ArcadeState({
    required this.question,
    required this.startedAt,
    required this.askedAt,
    this.phase = ArcadePhase.asking,
    this.answers = const [],
    this.combo = 0,
    this.bestCombo = 0,
    this.score = 0,
    this.lives = survivalLives,
    this.stage = 0,
    this.endsAt,
    this.deadline,
    this.flashUntil,
    this.choice,
    this.pausedAt,
    this.finishedAt,
  });

  final NoteQuestion question;
  final ArcadePhase phase;
  final List<AnswerRecord> answers;
  final int combo;
  final int bestCombo;

  /// Points en chrono, notes justes ailleurs.
  final int score;

  /// Vies restantes en survie.
  final int lives;

  /// Étapes ouvertes en survie, à partir de 0 : une clé de plus à chacune.
  final int stage;

  final DateTime startedAt;
  final DateTime askedAt;

  /// Fin du chrono.
  final DateTime? endsAt;

  /// Fin du temps de la note en cours, en sans fin et en survie.
  final DateTime? deadline;

  /// Fin de la correction en cours.
  final DateTime? flashUntil;

  /// Réponse donnée à la note en cours, `null` en attente.
  final Enum? choice;

  /// Début de la pause en cours, `null` en jeu.
  final DateTime? pausedAt;
  final DateTime? finishedAt;

  bool get paused => pausedAt != null;
  int get correct => answers.where((answer) => answer.correct).length;
  int get xp => answers.fold(0, (sum, answer) => sum + answer.xp);

  /// Temps moyen d'une réponse, `null` sans réponse.
  Duration? get timePerNote => answers.isEmpty
      ? null
      : answers.fold(Duration.zero, (sum, answer) => sum + answer.elapsed) ~/
            answers.length;

  ArcadeState copyWith({
    NoteQuestion? question,
    ArcadePhase? phase,
    List<AnswerRecord>? answers,
    int? combo,
    int? bestCombo,
    int? score,
    int? lives,
    int? stage,
    DateTime? startedAt,
    DateTime? askedAt,
    DateTime? Function()? endsAt,
    DateTime? Function()? deadline,
    DateTime? Function()? flashUntil,
    Enum? Function()? choice,
    DateTime? Function()? pausedAt,
    DateTime? Function()? finishedAt,
  }) => ArcadeState(
    question: question ?? this.question,
    phase: phase ?? this.phase,
    answers: answers ?? this.answers,
    combo: combo ?? this.combo,
    bestCombo: bestCombo ?? this.bestCombo,
    score: score ?? this.score,
    lives: lives ?? this.lives,
    stage: stage ?? this.stage,
    startedAt: startedAt ?? this.startedAt,
    askedAt: askedAt ?? this.askedAt,
    endsAt: endsAt == null ? this.endsAt : endsAt(),
    deadline: deadline == null ? this.deadline : deadline(),
    flashUntil: flashUntil == null ? this.flashUntil : flashUntil(),
    choice: choice == null ? this.choice : choice(),
    pausedAt: pausedAt == null ? this.pausedAt : pausedAt(),
    finishedAt: finishedAt == null ? this.finishedAt : finishedAt(),
  );
}

/// Une partie, avancée par [tick] : l'écran l'appelle à chaque image, et
/// tout se mesure à l'horloge de l'appli (remplaçable en test).
class ArcadeNotifier extends Notifier<ArcadeState> {
  ArcadeNotifier(this.game);

  final ArcadeGame game;

  late Random _random;

  /// Un générateur par étape.
  late List<NoteGenerator> _generators;

  DateTime _now() => ref.read(clockProvider)();

  @override
  ArcadeState build() {
    _random = ref.watch(randomProvider);
    _generators = [
      for (final params in game.stages) NoteGenerator(params, _random),
    ];
    final now = _now();
    return ArcadeState(
      question: _draw(0, null),
      startedAt: now,
      askedAt: now,
      endsAt: game.mode == ArcadeMode.chrono ? now.add(chronoLength) : null,
      deadline: game.mode == ArcadeMode.chrono ? null : now.add(noteTime(0)),
    );
  }

  /// Une note d'une des étapes ouvertes, au hasard.
  NoteQuestion _draw(int stage, NoteQuestion? previous) =>
      _generators[_random.nextInt(stage + 1)].next(previous: previous);

  /// Touches noires ouvertes dès qu'une étape a des altérations.
  List<NoteName> get choices => game.stages.any((params) => params.accidentals)
      ? NoteName.values
      : NoteName.naturals;

  void answer(NoteName choice) {
    if (state.phase != ArcadePhase.asking || state.paused) return;
    _answer(choice);
  }

  void _answer(Enum choice) {
    final current = state;
    final now = _now();
    final right = choice == current.question.answer;
    final combo = right ? current.combo + 1 : 0;
    state = current.copyWith(
      phase: ArcadePhase.flash,
      answers: [
        ...current.answers,
        AnswerRecord(
          expected: current.question.answer,
          given: choice,
          elapsed: now.difference(current.askedAt),
          xp: right ? arcadeXpPerNote : 0,
          card: cardOf(current.question),
        ),
      ],
      combo: combo,
      bestCombo: max(combo, current.bestCombo),
      score: !right
          ? current.score
          : game.mode == ArcadeMode.chrono
          ? current.score + chronoPoints * comboMultiplier(combo)
          : current.score + 1,
      lives: right || game.mode != ArcadeMode.survival
          ? current.lives
          : current.lives - 1,
      choice: () => choice,
      flashUntil: () => now.add(right ? rightFlash : wrongFlash),
    );
  }

  /// Avance la partie à l'heure de l'horloge : fin du chrono, temps de la
  /// note écoulé, fin de la correction.
  void tick() {
    final current = state;
    if (current.paused || current.phase == ArcadePhase.finished) return;
    final now = _now();

    if (current.endsAt case final endsAt? when !now.isBefore(endsAt)) {
      return _finish(endsAt);
    }
    switch (current.phase) {
      case ArcadePhase.asking:
        if (current.deadline case final deadline?
            when !now.isBefore(deadline)) {
          _answer(NoAnswer.timeout);
        }
      case ArcadePhase.flash:
        if (now.isBefore(current.flashUntil!)) return;
        if (_over(current)) return _finish(now);
        final stage = min(
          current.correct ~/ survivalStage,
          game.stages.length - 1,
        );
        state = current.copyWith(
          question: _draw(stage, current.question),
          phase: ArcadePhase.asking,
          stage: stage,
          askedAt: now,
          deadline: () => game.mode == ArcadeMode.chrono
              ? null
              : now.add(noteTime(current.correct)),
          flashUntil: () => null,
          choice: () => null,
        );
      case ArcadePhase.finished:
    }
  }

  /// Une erreur en sans fin, plus de vies en survie.
  bool _over(ArcadeState current) => switch (game.mode) {
    ArcadeMode.chrono => false,
    ArcadeMode.endless => !current.answers.last.correct,
    ArcadeMode.survival => current.lives == 0,
  };

  void _finish(DateTime at) {
    state = state.copyWith(
      phase: ArcadePhase.finished,
      finishedAt: () => at,
      deadline: () => null,
      flashUntil: () => null,
    );
  }

  void pause() {
    if (state.paused || state.phase == ArcadePhase.finished) return;
    state = state.copyWith(pausedAt: _now);
  }

  /// Reprend la partie là où elle était : les échéances se décalent de la
  /// durée de la pause, le temps de réponse ne la compte pas.
  void resume() {
    final pausedAt = state.pausedAt;
    if (pausedAt == null) return;
    final pause = _now().difference(pausedAt);
    DateTime? shift(DateTime? time) => time?.add(pause);
    state = state.copyWith(
      startedAt: state.startedAt.add(pause),
      askedAt: state.askedAt.add(pause),
      endsAt: () => shift(state.endsAt),
      deadline: () => shift(state.deadline),
      flashUntil: () => shift(state.flashUntil),
      pausedAt: () => null,
    );
  }
}
