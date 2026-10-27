import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/reading/note_reading.dart';

/// Nombre de notes par session.
const sessionLength = 20;

/// Durée d'affichage de la correction avant la note suivante.
const rightAnswerDelay = Duration(milliseconds: 400);
const wrongAnswerDelay = Duration(milliseconds: 1200);

/// Hasard des exercices, remplaçable en test.
final randomProvider = Provider<Random>((ref) => Random());

/// Horloge du chrono, remplaçable en test.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Session de lecture en cours pour des paramètres d'exercice (point de
/// départ ou leçon).
final sessionProvider = NotifierProvider.autoDispose
    .family<SessionNotifier, SessionState, NoteReadingParams>(
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
    this.phase = SessionPhase.asking,
    this.answered = 0,
    this.correct = 0,
    this.choice,
    this.finishedAt,
  });

  final NoteQuestion question;
  final SessionPhase phase;

  /// Nombre de réponses données, question en cours comprise.
  final int answered;
  final int correct;

  /// Réponse donnée à la question en cours, `null` en attente.
  final DiatonicStep? choice;

  final DateTime startedAt;

  /// Fixé à la dernière réponse : arrête le chrono.
  final DateTime? finishedAt;
}

class SessionNotifier extends Notifier<SessionState> {
  SessionNotifier(this.params);

  final NoteReadingParams params;

  late NoteGenerator _generator;
  Timer? _timer;

  @override
  SessionState build() {
    _generator = NoteGenerator(params, ref.watch(randomProvider));
    ref.onDispose(() => _timer?.cancel());
    return SessionState(
      question: _generator.next(),
      startedAt: ref.read(clockProvider)(),
    );
  }

  void answer(DiatonicStep step) {
    final current = state;
    if (current.phase != SessionPhase.asking) return;

    final right = step == current.question.answer;
    final answered = current.answered + 1;
    state = SessionState(
      question: current.question,
      phase: SessionPhase.feedback,
      answered: answered,
      correct: current.correct + (right ? 1 : 0),
      choice: step,
      startedAt: current.startedAt,
      finishedAt: answered == sessionLength ? ref.read(clockProvider)() : null,
    );
    _timer = Timer(right ? rightAnswerDelay : wrongAnswerDelay, _next);
  }

  void _next() {
    final current = state;
    final finished = current.finishedAt != null;
    state = SessionState(
      question: finished
          ? current.question
          : _generator.next(previous: current.question),
      phase: finished ? SessionPhase.finished : SessionPhase.asking,
      answered: current.answered,
      correct: current.correct,
      startedAt: current.startedAt,
      finishedAt: current.finishedAt,
    );
  }
}
