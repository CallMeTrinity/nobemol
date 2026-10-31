import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/achievements/achievement.dart';
import 'package:nobemol/achievements/achievements.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/yaml_fields.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/review/leitner.dart';

void main() {
  const skills = '''
- id: a.base
  title: Base
- id: a.next
  title: Suite
  requires: [a.base]
- id: a.empty
  title: Sans leçon
- id: b.other
  title: Autre
''';

  String lesson(String id, String skill) =>
      '''
id: $id
title: $id
skills: [$skill]
level: 1
theory:
  - text: x
exercise:
  type: note-reading
  staff: treble
''';

  String achievement(String id, String when) =>
      '''
- id: $id
  title: $id
  description: $id
  when: { $when }
''';

  Content content(String achievements) => parseContent(
    skills: skills,
    lessons: {
      'base.yaml': lesson('base', 'a.base'),
      'next.yaml': lesson('next', 'a.next'),
      'other.yaml': lesson('other', 'b.other'),
    },
    achievements: achievements,
  );

  group('lecture', () {
    List<Achievement> parse(String source) =>
        parseAchievements(source, branches: {'a', 'b'});

    test('une condition, un nombre ou une branche', () {
      final list = parse(
        achievement('one', 'lessons: 1') + achievement('a', 'branch: a'),
      );
      expect(list.map((a) => (a.kind, a.target, a.branch)), [
        (AchievementKind.lessons, 1, null),
        (AchievementKind.branch, 1, 'a'),
      ]);
    });

    test('condition inconnue, double ou sans nombre : refusée', () {
      for (final when in [
        'played: 3',
        'lessons: 1, combo: 5',
        'combo: 0',
        'combo: beaucoup',
      ]) {
        expect(
          () => parse(achievement('x', when)),
          throwsA(isA<ContentException>()),
          reason: when,
        );
      }
    });

    test('branche inconnue ou sans leçon : refusée', () {
      expect(
        () => parseAchievements(achievement('x', 'branch: a'), branches: {'b'}),
        throwsA(isA<ContentException>().having((e) => e.line, 'line', 4)),
      );
    });

    test('doublon et id invalide', () {
      expect(
        () => parse(achievement('x', 'lessons: 1') * 2),
        throwsA(isA<ContentException>()),
      );
      expect(
        () => parse(achievement('Un_Succès', 'lessons: 1')),
        throwsA(isA<ContentException>()),
      );
    });
  });

  group('calcul', () {
    final day = DateTime(2026, 10, 1, 18);

    SessionSummary session({
      String? lessonId,
      int questions = 10,
      int correct = 10,
      int combo = 0,
      int days = 0,
      String? arcade,
      int? score,
    }) {
      final at = DateTime(day.year, day.month, day.day + days, day.hour);
      return SessionSummary(
        lessonId: lessonId,
        startedAt: at,
        finishedAt: at,
        questions: questions,
        correct: correct,
        xp: correct * 10,
        bestCombo: combo,
        arcade: arcade,
        arcadeScore: score,
      );
    }

    AchievementProgress only(String when, Progress progress) =>
        AchievementList(content(achievement('x', when)), progress).all.single;

    test('leçons différentes, et sans faute', () {
      final progress = Progress(
        sessions: [
          session(lessonId: 'base', correct: 9),
          session(lessonId: 'base'),
          session(lessonId: 'next'),
          // Une révision sans faute n'est pas une leçon.
          session(),
        ],
      );
      expect(only('lessons: 3', progress).current, 2);
      expect(only('perfect: 5', progress).current, 2);
      expect(only('answers: 100', progress).current, 39);
    });

    test('combo et série de jours', () {
      final progress = Progress(
        sessions: [
          session(combo: 4),
          session(combo: 12, days: 1),
          session(days: 2),
          // Un jour sans : la série repart.
          session(days: 4),
        ],
      );
      expect(only('combo: 10', progress).unlocked, isTrue);
      expect(only('combo: 10', progress).current, 10);
      expect(only('streak: 7', progress).current, 3);
    });

    test('branche : ses compétences qui ont des leçons', () {
      final entry = only(
        'branch: a',
        Progress(mastered: {'a.base', 'b.other'}),
      );
      // a.empty n'a pas de leçon : elle ne compte pas.
      expect((entry.current, entry.target), (1, 2));
    });

    test('arcade : meilleur score du mode, toutes clés', () {
      final progress = Progress(
        sessions: [
          session(arcade: 'chrono:treble', score: 1800),
          session(arcade: 'chrono:bass', score: 2600),
          session(arcade: 'endless:treble', score: 40),
        ],
      );
      expect(only('chrono: 2500', progress).unlocked, isTrue);
      expect(only('survival: 10', progress).current, 0);
    });

    test('cartes acquises', () {
      // Une erreur, puis juste à chaque retour : dernière boîte.
      final answers = [
        CardAnswer(card: 'note:treble:c4', correct: false, answeredAt: day),
        for (final days in [1, 4, 11, 25])
          CardAnswer(
            card: 'note:treble:c4',
            correct: true,
            answeredAt: day.add(Duration(days: days)),
          ),
      ];
      expect(
        only('acquired: 1', Progress(cardAnswers: answers)).unlocked,
        true,
      );
    });

    test('enregistré : reste débloqué, et pas à nouveau', () {
      final list = AchievementList(
        content(
          achievement('one', 'lessons: 1') + achievement('two', 'lessons: 2'),
        ),
        Progress(
          sessions: [
            session(lessonId: 'base'),
            session(lessonId: 'next'),
          ],
          achievements: {'one': day},
        ),
      );
      expect(list.newlyReached.map((a) => a.id), ['two']);
      expect(list.all.first.unlockedAt, day);
      expect(list.unlocked, 2);
    });
  });
}
