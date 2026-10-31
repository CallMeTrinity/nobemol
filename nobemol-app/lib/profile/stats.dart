import 'dart:math';

import 'package:notation/core.dart';

import 'package:nobemol/arcade/arcade.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/review/card.dart';
import 'package:nobemol/review/leitner.dart';

/// Période des statistiques.
enum StatsPeriod {
  week(days: 7),
  month(days: 30),

  /// Tout, depuis la première session : des barres par semaine.
  all();

  const StatsPeriod({this.days});

  /// Jours couverts, aujourd'hui compris. `null` : tout.
  final int? days;
}

/// Bonnes réponses sur un ensemble de réponses.
class Accuracy {
  const Accuracy(this.correct, this.answers);

  final int correct;
  final int answers;

  /// De 0 à 1.
  double get ratio => answers == 0 ? 0 : correct / answers;

  Accuracy add({required bool correct}) =>
      Accuracy(this.correct + (correct ? 1 : 0), answers + 1);
}

/// Une barre du graphique d'XP : un jour, ou une semaine sur « Tout ».
class XpBar {
  const XpBar(this.start, this.xp);

  /// Le jour, ou le lundi de la semaine (minuit local).
  final DateTime start;
  final int xp;
}

/// Lecture de notes dans une clé : en tout, et note par note.
class ClefStats {
  const ClefStats(this.total, this.notes);

  final Accuracy total;

  /// Dans l'ordre du clavier (do, do dièse, ré bémol, ré...).
  final Map<NoteName, Accuracy> notes;
}

/// Statistiques d'une période, recalculées depuis la progression.
///
/// La précision par note vient des cartes : une grande portée compte
/// chaque note dans sa propre clé. L'objectif est celui d'aujourd'hui,
/// l'historique des réglages n'est pas gardé.
class Stats {
  factory Stats(
    Progress progress, {
    required StatsPeriod period,
    required DateTime now,
    required int dailyGoal,
  }) {
    final today = dayOf(now);
    final days = period.days;
    final from = days == null
        ? progress.practiceDays.firstOrNull
        : _addDays(today, 1 - days);
    bool inPeriod(DateTime time) =>
        from != null &&
        !dayOf(time).isBefore(from) &&
        !dayOf(time).isAfter(today);

    final sessions = [
      for (final session in progress.sessions)
        if (inPeriod(session.finishedAt)) session,
    ];

    // Un jour par barre, ou une semaine (du lundi) sur « Tout ».
    final weekly = days == null;
    DateTime barOf(DateTime time) {
      final day = dayOf(time);
      return weekly ? _addDays(day, 1 - day.weekday) : day;
    }

    final xp = <DateTime, int>{};
    if (from != null) {
      for (
        var bar = barOf(from);
        !bar.isAfter(today);
        bar = _addDays(bar, weekly ? 7 : 1)
      ) {
        xp[bar] = 0;
      }
    }
    for (final session in sessions) {
      xp.update(barOf(session.finishedAt), (sum) => sum + session.xp);
    }

    final notes = <Clef, Map<NoteName, Accuracy>>{};
    var timed = 0;
    var elapsed = Duration.zero;
    for (final answer in progress.cardAnswers) {
      if (!inPeriod(answer.answeredAt)) continue;
      final note = noteOfCard(answer.card);
      if (note == null) continue;
      final (clef, name) = note;
      notes
          .putIfAbsent(clef, () => {})
          .update(
            name,
            (accuracy) => accuracy.add(correct: answer.correct),
            ifAbsent: () => const Accuracy(0, 0).add(correct: answer.correct),
          );
      if (!answer.timedOut) {
        timed++;
        elapsed += answer.elapsed;
      }
    }

    return Stats._(
      period: period,
      sessions: sessions.length,
      bars: [
        for (final MapEntry(:key, :value) in xp.entries) XpBar(key, value),
      ],
      barGoal: weekly ? dailyGoal * 7 : dailyGoal,
      xp: sessions.fold(0, (sum, session) => sum + session.xp),
      goalDays: weekly
          ? null
          : xp.values.where((value) => value >= dailyGoal).length,
      practice: sessions.fold(
        Duration.zero,
        (sum, session) =>
            sum + session.finishedAt.difference(session.startedAt),
      ),
      timePerNote: timed == 0 ? null : elapsed ~/ timed,
      clefs: {
        for (final clef in _clefOrder)
          if (notes[clef] case final byName?)
            clef: ClefStats(
              byName.values.fold(
                const Accuracy(0, 0),
                (sum, accuracy) => Accuracy(
                  sum.correct + accuracy.correct,
                  sum.answers + accuracy.answers,
                ),
              ),
              {for (final name in NoteName.values) name: ?byName[name]},
            ),
      },
    );
  }

  const Stats._({
    required this.period,
    required this.sessions,
    required this.bars,
    required this.barGoal,
    required this.xp,
    required this.goalDays,
    required this.practice,
    required this.timePerNote,
    required this.clefs,
  });

  final StatsPeriod period;

  /// Sessions terminées dans la période.
  final int sessions;

  /// XP par jour, ou par semaine sur « Tout ». Vide sans aucune session.
  final List<XpBar> bars;

  /// Objectif d'une barre : celui du jour, ou d'une semaine.
  final int barGoal;

  /// XP de la période.
  final int xp;

  /// Jours où l'objectif est atteint, `null` sur « Tout ».
  final int? goalDays;

  /// Temps passé en session, du début à la fin.
  final Duration practice;

  /// Temps moyen pour nommer une note, sans les temps écoulés de l'arcade.
  /// `null` sans note.
  final Duration? timePerNote;

  /// Lecture de notes par clé, dans l'ordre sol, fa, ut 3e, ut 4e.
  final Map<Clef, ClefStats> clefs;
}

const _clefOrder = [Clef.treble, Clef.bass, Clef.alto, Clef.tenor];

/// Les chiffres clés du profil, depuis toujours.
class ProfileFigures {
  factory ProfileFigures(Progress progress) {
    final sessions = progress.sessions;
    final chrono = progress.records.entries
        .where(
          (record) => record.key.split(':').first == ArcadeMode.chrono.name,
        )
        .map((record) => record.value);
    return ProfileFigures._(
      lessons: progress.bestScores.length,
      bestCombo: sessions.fold(0, (best, s) => max(best, s.bestCombo)),
      chronoRecord: chrono.isEmpty ? null : chrono.reduce(max),
      accuracy: sessions.fold(
        const Accuracy(0, 0),
        (sum, session) => Accuracy(
          sum.correct + session.correct,
          sum.answers + session.questions,
        ),
      ),
    );
  }

  const ProfileFigures._({
    required this.lessons,
    required this.bestCombo,
    required this.chronoRecord,
    required this.accuracy,
  });

  /// Leçons différentes terminées.
  final int lessons;
  final int bestCombo;

  /// Meilleur score de chrono, toutes clés. `null` sans partie.
  final int? chronoRecord;

  /// Toutes les réponses, partout.
  final Accuracy accuracy;
}

DateTime _addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);
