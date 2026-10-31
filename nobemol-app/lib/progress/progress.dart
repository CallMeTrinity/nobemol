import 'dart:math';

import 'package:nobemol/review/leitner.dart';

/// Réponse qui n'en est pas une : le temps de la note est écoulé (arcade).
/// Gardée comme une erreur, sous le nom `timeout`.
enum NoAnswer { timeout }

/// Réponse donnée pendant une session.
class AnswerRecord {
  const AnswerRecord({
    required this.expected,
    required this.given,
    required this.elapsed,
    required this.xp,
    this.card,
  });

  /// Bonne réponse et réponse donnée : `NoteName`, `Beats` ou `Marking`.
  /// Réponse donnée [NoAnswer.timeout] si le temps est écoulé.
  final Enum expected;
  final Enum given;

  /// De l'affichage de la question au choix.
  final Duration elapsed;
  final int xp;

  /// Carte de révision de la question (voir `lib/review/card.dart`).
  final String? card;

  bool get correct => expected == given;
}

/// Session terminée, sans le détail des réponses.
class SessionSummary {
  const SessionSummary({
    required this.lessonId,
    required this.finishedAt,
    required this.questions,
    required this.correct,
    required this.xp,
    this.arcade,
    this.arcadeScore,
  });

  /// `null` hors leçon : lecture libre, révision, arcade.
  final String? lessonId;

  /// Partie d'arcade (`ArcadeGame.record`) et son score, `null` hors
  /// arcade.
  final String? arcade;
  final int? arcadeScore;
  final DateTime finishedAt;
  final int questions;
  final int correct;
  final int xp;

  /// Part de bonnes réponses, de 0 à 1.
  double get score => questions == 0 ? 0 : correct / questions;
}

/// Lecture de la théorie d'une leçon.
class TheoryProgress {
  const TheoryProgress({
    required this.page,
    required this.read,
    required this.updatedAt,
  });

  /// Dernière page ouverte, à partir de 0.
  final int page;

  /// Vrai une fois la dernière page passée.
  final bool read;
  final DateTime updatedAt;
}

/// Progression de l'élève, lue depuis la base.
class Progress {
  Progress({
    this.sessions = const [],
    this.theory = const {},
    this.mastered = const {},
    this.cardAnswers = const [],
  });

  /// Sessions terminées, de la plus ancienne à la plus récente.
  final List<SessionSummary> sessions;

  /// Théorie ouverte, par identifiant de leçon.
  final Map<String, TheoryProgress> theory;

  /// Compétences maîtrisées au moins une fois. Elles le restent.
  final Set<String> mastered;

  /// Réponses qui ont une carte, de la plus ancienne à la plus récente.
  final List<CardAnswer> cardAnswers;

  /// Cartes de révision, par clé.
  late final Map<String, ReviewCard> cards = replay(cardAnswers);

  /// Total d'XP.
  late final int xp = sessions.fold(0, (sum, session) => sum + session.xp);

  /// Meilleur score de chaque leçon jouée au moins une fois.
  late final Map<String, double> bestScores = () {
    final best = <String, double>{};
    for (final session in sessions) {
      if (session.lessonId case final id?) {
        best.update(
          id,
          (score) => max(score, session.score),
          ifAbsent: () => session.score,
        );
      }
    }
    return best;
  }();

  /// Meilleur score de chaque partie d'arcade jouée (`ArcadeGame.record`).
  late final Map<String, int> records = () {
    final records = <String, int>{};
    for (final session in sessions) {
      if ((session.arcade, session.arcadeScore) case (
        final id?,
        final score?,
      )) {
        records.update(id, (best) => max(best, score), ifAbsent: () => score);
      }
    }
    return records;
  }();

  /// XP gagnés le jour (local) de [now].
  int xpOn(DateTime now) => sessions
      .where((session) => _sameDay(session.finishedAt.toLocal(), now))
      .fold(0, (sum, session) => sum + session.xp);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
