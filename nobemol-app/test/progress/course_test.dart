import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/progress/course.dart';
import 'package:nobemol/progress/progress.dart';

void main() {
  const skills = '''
- id: a.base
  title: Base
- id: a.next
  title: Suite
  requires: [a.base]
- id: b.other
  title: Autre
  requires: [a.base]
- id: b.empty
  title: Sans leçon
''';

  String lesson(String id, List<String> skills, {int level = 1}) =>
      '''
id: $id
title: $id
skills: [${skills.join(', ')}]
level: $level
theory:
  - text: un
  - text: deux
  - text: trois
exercise:
  type: note-reading
  staff: treble
''';

  final content = parseContent(
    skills: skills,
    lessons: {
      'base-1.yaml': lesson('base-1', ['a.base']),
      'base-2.yaml': lesson('base-2', ['a.base'], level: 2),
      'next.yaml': lesson('next', ['a.next']),
      'both.yaml': lesson('both', ['a.next', 'b.other']),
    },
  );
  final t0 = DateTime(2026, 10, 1);

  SessionSummary played(String lessonId, int correct, {DateTime? at}) =>
      SessionSummary(
        lessonId: lessonId,
        startedAt: at ?? t0,
        finishedAt: at ?? t0,
        questions: 10,
        correct: correct,
        xp: correct * 10,
        bestCombo: correct,
      );

  test('au départ : la racine à faire, le reste verrouillé', () {
    final course = Course(content, Progress());
    expect(course.skill('a.base')!.state, SkillState.todo);
    expect(course.skill('a.next')!.state, SkillState.locked);
    expect(course.skill('a.next')!.missing.map((s) => s.id), ['a.base']);
    expect(course.isUnlocked(content.lesson('base-1')!), isTrue);
    expect(course.isUnlocked(content.lesson('next')!), isFalse);
  });

  test('maîtrise : moyenne des meilleurs scores, leçon non jouée à 0', () {
    final course = Course(
      content,
      Progress(sessions: [played('base-1', 6), played('base-1', 10)]),
    );
    final base = course.skill('a.base')!;
    expect(base.mastery, 0.5);
    expect(base.state, SkillState.started);
    expect(course.skill('a.next')!.state, SkillState.locked);
  });

  test('maîtrisée à 80 % : débloque les suivantes', () {
    final course = Course(
      content,
      Progress(sessions: [played('base-1', 9), played('base-2', 7)]),
    );
    expect(course.skill('a.base')!.mastery, closeTo(0.8, 1e-9));
    expect(course.skill('a.base')!.state, SkillState.mastered);
    expect(course.skill('a.next')!.state, SkillState.todo);
    expect(course.isUnlocked(content.lesson('both')!), isTrue);
  });

  test('maîtrisée une fois, le reste : une nouvelle leçon ne reverrouille '
      'rien', () {
    // a.base a deux leçons : 50 % de maîtrise calculée, sous le seuil.
    final course = Course(
      content,
      Progress(sessions: [played('base-1', 10)], mastered: {'a.base'}),
    );
    expect(course.skill('a.base')!.mastery, 0.5);
    expect(course.skill('a.base')!.state, SkillState.mastered);
    expect(course.skill('a.next')!.state, SkillState.todo);
    expect(course.newlyMastered, isEmpty);
  });

  test('au seuil sans être enregistrée : à enregistrer', () {
    final course = Course(
      content,
      Progress(sessions: [played('base-1', 10), played('base-2', 8)]),
    );
    expect(course.newlyMastered, ['a.base']);
  });

  test('une leçon qui croise deux branches ne compte pour aucune', () {
    expect(content.masteryLessons('a.next').map((l) => l.id), ['next']);
    expect(content.masteryLessons('b.other'), isEmpty);
    expect(content.masteryLessons('a.base').map((l) => l.id), [
      'base-1',
      'base-2',
    ]);

    final course = Course(
      content,
      Progress(
        sessions: [
          played('base-1', 10),
          played('base-2', 10),
          played('next', 8),
          played('both', 2),
        ],
      ),
    );
    final next = course.skill('a.next')!;
    expect(next.lessons.map((l) => l.id), ['next', 'both']);
    expect(next.mastery, 0.8);
    expect(next.state, SkillState.mastered);
  });

  test('une théorie ouverte suffit pour « en cours »', () {
    final course = Course(
      content,
      Progress(
        theory: {'base-2': TheoryProgress(page: 1, read: false, updatedAt: t0)},
      ),
    );
    expect(course.skill('a.base')!.state, SkillState.started);
  });

  test('branches : compétences avec leçons, dans l’ordre de l’arbre', () {
    final course = Course(content, Progress());
    expect(course.branches.keys, ['a', 'b']);
    expect(course.branches['a']!.map((s) => s.skill.id), ['a.base', 'a.next']);
    expect(course.branches['b']!.map((s) => s.skill.id), ['b.other']);
  });

  group('reprendre', () {
    test('rien d’ouvert : la première leçon débloquée, à commencer', () {
      final resume = Course(content, Progress()).resume!;
      expect(resume.lesson.id, 'base-1');
      expect(resume.page, 0);
      expect(resume.started, isFalse);
    });

    test('la théorie ouverte le plus récemment, à sa page', () {
      final resume = Course(
        content,
        Progress(
          theory: {
            'base-1': TheoryProgress(page: 2, read: false, updatedAt: t0),
            'base-2': TheoryProgress(
              page: 1,
              read: false,
              updatedAt: t0.add(const Duration(hours: 1)),
            ),
          },
        ),
      ).resume!;
      expect(resume.lesson.id, 'base-2');
      expect(resume.page, 1);
      expect(resume.started, isTrue);
    });

    test('théorie lue, exercice pas joué : l’exercice', () {
      final resume = Course(
        content,
        Progress(
          theory: {
            'base-1': TheoryProgress(page: 2, read: true, updatedAt: t0),
          },
        ),
      ).resume!;
      expect(resume.lesson.id, 'base-1');
      expect(resume.page, isNull);
    });

    test('leçon jouée : on passe à la suivante', () {
      final resume = Course(
        content,
        Progress(
          sessions: [played('base-1', 5)],
          theory: {
            'base-1': TheoryProgress(page: 2, read: true, updatedAt: t0),
          },
        ),
      ).resume!;
      expect(resume.lesson.id, 'base-2');
      expect(resume.started, isFalse);
    });

    test('page au-delà de la théorie (leçon raccourcie) : la dernière', () {
      final resume = Course(
        content,
        Progress(
          theory: {
            'base-1': TheoryProgress(page: 7, read: false, updatedAt: t0),
          },
        ),
      ).resume!;
      expect(resume.page, 2);
    });

    test('tout joué : rien à reprendre', () {
      final course = Course(
        content,
        Progress(
          sessions: [
            for (final id in ['base-1', 'base-2', 'next', 'both'])
              played(id, 10),
          ],
        ),
      );
      expect(course.resume, isNull);
    });
  });

  group('point de départ', () {
    test('une compétence acquise débloque la suite sans être maîtrisée', () {
      final course = Course(content, Progress(), acquired: {'a.base'});
      expect(course.skill('a.base')!.state, SkillState.todo);
      expect(course.skill('a.next')!.state, SkillState.todo);
      expect(course.skill('a.next')!.missing, isEmpty);
      expect(course.isUnlocked(content.lesson('both')!), isTrue);
      expect(course.newlyMastered, isEmpty);
    });

    test('« Commencer » saute les leçons des compétences acquises', () {
      final resume = Course(content, Progress(), acquired: {'a.base'}).resume!;
      expect(resume.lesson.id, 'next');
      expect(resume.started, isFalse);
    });

    test('tout le reste fait : on revient aux compétences acquises', () {
      final resume = Course(
        content,
        Progress(sessions: [played('next', 5), played('both', 5)]),
        acquired: {'a.base'},
      ).resume!;
      expect(resume.lesson.id, 'base-1');
    });
  });

  test('XP du jour : sessions du même jour local', () {
    final progress = Progress(
      sessions: [
        played('base-1', 5, at: DateTime(2026, 10, 1, 23, 59)),
        played('base-1', 3, at: DateTime(2026, 10, 2, 0, 1)),
        played('base-2', 2, at: DateTime(2026, 10, 2, 18)),
      ],
    );
    expect(progress.xp, 100);
    expect(progress.xpOn(DateTime(2026, 10, 2, 20)), 50);
    expect(progress.bestScores, {'base-1': 0.5, 'base-2': 0.2});
  });
}
