import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/progress_provider.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late NobemolDatabase db;
  late ProgressStore store;

  setUp(() {
    db = NobemolDatabase(NativeDatabase.memory());
    store = ProgressStore(db);
  });
  tearDown(() => db.close());

  final start = DateTime(2026, 10, 29, 18);

  AnswerRecord answer(DiatonicStep expected, DiatonicStep given, int xp) =>
      AnswerRecord(
        expected: expected,
        given: given,
        elapsed: const Duration(milliseconds: 1500),
        xp: xp,
      );

  test('base vide : aucune progression', () async {
    final progress = await store.load();
    expect(progress.sessions, isEmpty);
    expect(progress.theory, isEmpty);
    expect(progress.xp, 0);
  });

  test('une session et ses réponses, relues', () async {
    await store.recordSession(
      lessonId: 'treble-clef',
      startedAt: start,
      finishedAt: start.add(const Duration(minutes: 1)),
      answers: [
        answer(DiatonicStep.c, DiatonicStep.c, 10),
        answer(DiatonicStep.d, DiatonicStep.e, 0),
        answer(DiatonicStep.f, DiatonicStep.f, 10),
      ],
      bestCombo: 1,
    );

    final progress = await store.load();
    final session = progress.sessions.single;
    expect(session.lessonId, 'treble-clef');
    expect(session.questions, 3);
    expect(session.correct, 2);
    expect(session.xp, 20);
    expect(session.finishedAt, start.add(const Duration(minutes: 1)));
    expect(progress.bestScores, {'treble-clef': 2 / 3});

    final answers = await db.select(db.answers).get();
    expect(answers.map((row) => (row.expected, row.given)), [
      ('c', 'c'),
      ('d', 'e'),
      ('f', 'f'),
    ]);
    expect(answers.first.elapsedMs, 1500);
  });

  test('lecture libre : session sans leçon, XP comptés', () async {
    await store.recordSession(
      lessonId: null,
      startedAt: start,
      finishedAt: start,
      answers: [answer(DiatonicStep.g, DiatonicStep.g, 10)],
      bestCombo: 1,
    );
    final progress = await store.load();
    expect(progress.xp, 10);
    expect(progress.bestScores, isEmpty);
  });

  test('cartes : écrites avec la réponse, rejouées à la lecture', () async {
    Future<void> session(DateTime at, {required bool right}) =>
        store.recordSession(
          lessonId: null,
          startedAt: at,
          finishedAt: at,
          answers: [
            AnswerRecord(
              expected: DiatonicStep.f,
              given: right ? DiatonicStep.f : DiatonicStep.g,
              elapsed: const Duration(seconds: 1),
              xp: right ? 10 : 0,
              card: 'note:treble:f5',
            ),
            // Sans carte (réponse d'avant la v2) : ignorée.
            answer(DiatonicStep.c, DiatonicStep.d, 0),
          ],
          bestCombo: 0,
        );

    await session(start, right: false);
    await session(start.add(const Duration(days: 1)), right: true);

    final cards = (await store.load()).cards;
    expect(cards.keys, ['note:treble:f5']);
    expect(cards.values.single.box, 2);
    expect(cards.values.single.due, DateTime(2026, 11, 2));
  });

  test('théorie : une ligne par leçon, remplacée à chaque page', () async {
    await store.saveTheory(
      'treble-clef',
      TheoryProgress(page: 1, read: false, updatedAt: start),
    );
    await store.saveTheory(
      'treble-clef',
      TheoryProgress(page: 3, read: true, updatedAt: start),
    );
    final theory = (await store.load()).theory;
    expect(theory.keys, ['treble-clef']);
    expect(theory['treble-clef']!.page, 3);
    expect(theory['treble-clef']!.read, isTrue);
  });

  test('compétences maîtrisées : la première date reste', () async {
    await store.saveMastered(['note-reading.treble'], start);
    await store.saveMastered([
      'note-reading.treble',
      'note-reading.bass',
    ], start.add(const Duration(days: 1)));

    expect((await store.load()).mastered, {
      'note-reading.treble',
      'note-reading.bass',
    });
    final treble = await (db.select(
      db.masteredSkills,
    )..where((row) => row.skillId.equals('note-reading.treble'))).getSingle();
    expect(treble.masteredAt, start);
  });
}
