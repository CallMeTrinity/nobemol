import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/note_reading.dart';

/// Durée d'affichage de la correction avant la note suivante.
const rightAnswerDelay = Duration(milliseconds: 400);
const wrongAnswerDelay = Duration(milliseconds: 1200);

/// Hasard des exercices, remplaçable en test.
final randomProvider = Provider<Random>((ref) => Random());

/// Session de lecture en cours pour un exercice (point de départ ou
/// leçon).
final sessionProvider = NotifierProvider.autoDispose
    .family<SessionNotifier, SessionState, ReadingExercise>(
      SessionNotifier.new,
    );

enum SessionPhase {
  /// En attente d'une réponse.
  asking,

  /// Correction affichée, la note suivante arrive.
  feedback,

  /// Toutes les notes ont été jouées.
  finished,
}

class SessionState {
  const SessionState({
    required this.question,
    required this.startedAt,
    required this.askedAt,
    this.phase = SessionPhase.asking,
    this.answers = const [],
    this.combo = 0,
    this.bestCombo = 0,
    this.choice,
    this.finishedAt,
  });

  final Question question;
  final SessionPhase phase;

  /// Réponses données, question en cours comprise.
  final List<AnswerRecord> answers;

  /// Bonnes réponses d'affilée, et la plus longue série de la session.
  final int combo;
  final int bestCombo;

  /// Réponse donnée à la question en cours, `null` en attente.
  final Enum? choice;

  final DateTime startedAt;

  /// Affichage de la question en cours.
  final DateTime askedAt;

  /// Fixé à la dernière réponse : arrête le chrono.
  final DateTime? finishedAt;

  int get answered => answers.length;
  int get correct => answers.where((answer) => answer.correct).length;
  int get xp => answers.fold(0, (sum, answer) => sum + answer.xp);
}

class SessionNotifier extends Notifier<SessionState> {
  SessionNotifier(this.exercise);

  final ReadingExercise exercise;

  late QuestionSource _questions;
  Timer? _timer;

  @override
  SessionState build() {
    _questions = exercise.questions(ref.watch(randomProvider));
    ref.onDispose(() => _timer?.cancel());
    final now = ref.read(clockProvider)();
    return SessionState(
      question: _questions.next(),
      startedAt: now,
      askedAt: now,
    );
  }

  void answer(Enum choice) {
    final current = state;
    if (current.phase != SessionPhase.asking) return;

    final now = ref.read(clockProvider)();
    final right = choice == current.question.answer;
    final combo = right ? current.combo + 1 : 0;
    final answers = [
      ...current.answers,
      AnswerRecord(
        expected: current.question.answer,
        given: choice,
        elapsed: now.difference(current.askedAt),
        xp: answerXp(combo),
      ),
    ];
    state = SessionState(
      question: current.question,
      phase: SessionPhase.feedback,
      answers: answers,
      combo: combo,
      bestCombo: max(combo, current.bestCombo),
      choice: choice,
      startedAt: current.startedAt,
      askedAt: current.askedAt,
      finishedAt: answers.length == exercise.length ? now : null,
    );
    _timer = Timer(right ? rightAnswerDelay : wrongAnswerDelay, _next);
  }

  void _next() {
    final current = state;
    final finished = current.finishedAt != null;
    state = SessionState(
      question: finished
          ? current.question
          : _questions.next(previous: current.question),
      phase: finished ? SessionPhase.finished : SessionPhase.asking,
      answers: current.answers,
      combo: current.combo,
      bestCombo: current.bestCombo,
      startedAt: current.startedAt,
      askedAt: finished ? current.askedAt : ref.read(clockProvider)(),
      finishedAt: current.finishedAt,
    );
  }
}
