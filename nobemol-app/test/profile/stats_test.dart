import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/profile/stats.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/review/leitner.dart';

void main() {
  // Un samedi.
  final now = DateTime(2026, 10, 31, 20);

  SessionSummary session(
    int daysAgo, {
    int xp = 100,
    int minutes = 5,
    int correct = 10,
    int combo = 0,
    String? lessonId,
    String? arcade,
    int? score,
  }) {
    final end = DateTime(now.year, now.month, now.day - daysAgo, 18);
    return SessionSummary(
      lessonId: lessonId,
      startedAt: end.subtract(Duration(minutes: minutes)),
      finishedAt: end,
      questions: 10,
      correct: correct,
      xp: xp,
      bestCombo: combo,
      arcade: arcade,
      arcadeScore: score,
    );
  }

  CardAnswer note(
    String card, {
    required bool correct,
    int daysAgo = 0,
    int ms = 2000,
    bool timedOut = false,
  }) => CardAnswer(
    card: card,
    correct: correct,
    answeredAt: DateTime(now.year, now.month, now.day - daysAgo, 18),
    elapsed: Duration(milliseconds: ms),
    timedOut: timedOut,
  );

  Stats stats(Progress progress, StatsPeriod period) =>
      Stats(progress, period: period, now: now, dailyGoal: 300);

  test('sans session : rien à montrer', () {
    final empty = stats(Progress(), StatsPeriod.all);
    expect(empty.sessions, 0);
    expect(empty.bars, isEmpty);
    expect(empty.timePerNote, isNull);
    expect(stats(Progress(), StatsPeriod.week).bars, hasLength(7));
  });

  test('7 jours : une barre par jour, l’objectif du jour', () {
    final week = stats(
      Progress(
        sessions: [
          session(10),
          session(6, xp: 350),
          session(0, xp: 120),
          session(0, xp: 200, minutes: 10),
        ],
      ),
      StatsPeriod.week,
    );
    expect(week.bars.first.start, DateTime(2026, 10, 25));
    expect(week.bars.map((bar) => bar.xp), [350, 0, 0, 0, 0, 0, 320]);
    expect(week.barGoal, 300);
    expect(week.goalDays, 2);
    expect(week.xp, 670);
    expect(week.sessions, 3);
    expect(week.practice, const Duration(minutes: 20));
  });

  test('tout : une barre par semaine, du lundi, l’objectif × 7', () {
    final all = stats(
      Progress(sessions: [session(19), session(12), session(0)]),
      StatsPeriod.all,
    );
    // 12 octobre (lundi) : la semaine de la première session.
    expect(all.bars.map((bar) => bar.start), [
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
    ]);
    expect(all.bars.map((bar) => bar.xp), [100, 100, 100]);
    expect(all.barGoal, 2100);
    expect(all.goalDays, isNull);
  });

  test('précision par clé et par note, temps par note', () {
    final week = stats(
      Progress(
        cardAnswers: [
          note('note:treble:fSharp5', correct: true, ms: 1000),
          note('note:treble:fSharp4', correct: false, ms: 3000),
          note('note:treble:c4', correct: true, ms: 2000),
          // Temps écoulé : une erreur, hors du temps moyen.
          note('note:bass:g2', correct: false, ms: 6000, timedOut: true),
          // Hors période, et pas une note.
          note('note:treble:c4', correct: false, daysAgo: 8),
          note('duration:half', correct: false),
        ],
      ),
      StatsPeriod.week,
    );
    expect(week.clefs.keys, [Clef.treble, Clef.bass]);
    final treble = week.clefs[Clef.treble]!;
    expect((treble.total.correct, treble.total.answers), (2, 3));
    // Dans l'ordre du clavier, sans l'octave.
    expect(treble.notes.keys, [NoteName.c, NoteName.fSharp]);
    expect(treble.notes[NoteName.fSharp]!.ratio, 0.5);
    expect(week.clefs[Clef.bass]!.total.ratio, 0);
    expect(week.timePerNote, const Duration(milliseconds: 2000));
  });

  test('série de jours : la plus longue, jours de calendrier', () {
    expect(Progress().bestStreak, 0);
    final progress = Progress(
      sessions: [
        session(9),
        session(8),
        session(8),
        session(7),
        session(3),
        session(2),
      ],
    );
    expect(progress.practiceDays, hasLength(5));
    expect(progress.bestStreak, 3);
  });

  test('chiffres clés du profil', () {
    final figures = ProfileFigures(
      Progress(
        sessions: [
          session(3, lessonId: 'treble-clef', correct: 8, combo: 6),
          session(2, lessonId: 'treble-clef', combo: 10),
          session(1, arcade: 'chrono:treble', score: 1200, correct: 7),
          session(0, arcade: 'chrono:bass', score: 1500, correct: 5),
          session(0, arcade: 'endless:bass', score: 30),
        ],
      ),
    );
    expect(figures.lessons, 1);
    expect(figures.bestCombo, 10);
    expect(figures.chronoRecord, 1500);
    expect((figures.accuracy.correct, figures.accuracy.answers), (40, 50));
    expect(ProfileFigures(Progress()).chronoRecord, isNull);
  });
}
