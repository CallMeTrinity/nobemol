import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/backup/backup.dart';
import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/settings/settings.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final start = DateTime(2026, 10, 29, 18);
  const settings = Settings(
    onboarded: true,
    naming: NoteNaming.letters,
    goal: DailyGoal.fifteen,
    theme: ThemeMode.dark,
    updateCheck: false,
  );

  /// Une base avec deux sessions, une théorie, une maîtrise et un succès.
  Future<ProgressStore> filled() async {
    final store = ProgressStore(NobemolDatabase(NativeDatabase.memory()));
    await store.recordSession(
      lessonId: 'treble-clef',
      startedAt: start,
      finishedAt: start.add(const Duration(minutes: 2)),
      answers: const [
        AnswerRecord(
          expected: DiatonicStep.f,
          given: DiatonicStep.g,
          elapsed: Duration(milliseconds: 1800),
          xp: 0,
          card: 'note:treble:f5',
        ),
        AnswerRecord(
          expected: DiatonicStep.c,
          given: DiatonicStep.c,
          elapsed: Duration(milliseconds: 900),
          xp: 10,
          card: 'note:treble:c5',
        ),
      ],
      bestCombo: 1,
    );
    await store.recordSession(
      lessonId: null,
      startedAt: start.add(const Duration(days: 1)),
      finishedAt: start.add(const Duration(days: 1, minutes: 1)),
      answers: const [
        AnswerRecord(
          expected: DiatonicStep.f,
          given: NoAnswer.timeout,
          elapsed: Duration(seconds: 6),
          xp: 0,
          card: 'note:treble:f5',
        ),
      ],
      bestCombo: 0,
      arcade: 'endless:treble',
      score: 0,
    );
    await store.saveTheory(
      'bass-clef',
      TheoryProgress(page: 2, read: false, updatedAt: start),
    );
    await store.saveMastered(['note-reading.treble'], start);
    await store.saveAchievements(['first-lesson'], start);
    return store;
  }

  test('exportée puis importée : la même progression', () async {
    final source = await filled();
    final backup = Backup(
      rows: await source.rows(),
      settings: settings,
      exportedAt: start,
    );
    expect(backup.xp, 10);
    expect(backup.fileName, 'nobemol-2026-10-29.json');

    final read = Backup.decode(backup.encode(), current: const Settings());
    expect(read.exportedAt, start);
    final target = ProgressStore(NobemolDatabase(NativeDatabase.memory()));
    // Une progression déjà là : remplacée, pas complétée.
    await target.saveTheory(
      'treble-clef',
      TheoryProgress(page: 1, read: true, updatedAt: start),
    );
    await target.replace(read.rows);

    final before = await source.load();
    final after = await target.load();
    expect(after.xp, before.xp);
    expect(after.bestScores, before.bestScores);
    expect(after.records, {'endless:treble': 0});
    expect(after.theory.keys, ['bass-clef']);
    expect(after.mastered, {'note-reading.treble'});
    expect(after.achievements, {'first-lesson': start});
    expect(after.sessions.first.startedAt, start);
    expect(after.sessions.first.bestCombo, 1);
    // Le journal des réponses, dans l'ordre : mêmes cartes, temps écoulé
    // compris.
    expect(
      after.cardAnswers.map((a) => (a.card, a.correct, a.elapsed, a.timedOut)),
      before.cardAnswers.map((a) => (a.card, a.correct, a.elapsed, a.timedOut)),
    );
    expect(after.cards.keys, before.cards.keys);
  });

  test('réglages : gardés, démarrage passé', () {
    final json = Backup(
      rows: const ProgressRows(),
      settings: settings,
      exportedAt: start,
    ).encode();
    final read = Backup.decode(json, current: const Settings()).settings;
    expect(read.onboarded, isTrue);
    expect(read.naming, NoteNaming.letters);
    expect(read.goal, DailyGoal.fifteen);
    expect(read.updateCheck, isFalse);
    expect(read.theme, ThemeMode.dark);

    // Un réglage inconnu (retiré d'une version) : celui du téléphone.
    final edited = (jsonDecode(json) as Map<String, Object?>)
      ..['settings'] = {'goal': 'forty', 'haptics': false};
    final mixed = Backup.decode(
      jsonEncode(edited),
      current: const Settings(goal: DailyGoal.ten),
    ).settings;
    expect(mixed.goal, DailyGoal.ten);
    expect(mixed.haptics, isFalse);
  });

  test('fichier abîmé ou étranger : refusé', () {
    final valid = jsonDecode(
      Backup(
        rows: const ProgressRows(),
        settings: settings,
        exportedAt: start,
      ).encode(),
    ) as Map<String, Object?>;
    for (final source in [
      '',
      'pas du json',
      '[]',
      jsonEncode({...valid, 'app': 'autre'}),
      jsonEncode({
        ...valid,
        'progress': {'sessions': 'non'},
      }),
      jsonEncode({
        ...valid,
        'progress': {
          ...valid['progress']! as Map<String, Object?>,
          'sessions': [
            {'xp': 'dix'},
          ],
        },
      }),
    ]) {
      expect(
        () => Backup.decode(source, current: const Settings()),
        throwsA(
          isA<BackupException>().having(
            (e) => e.error,
            'error',
            BackupError.invalid,
          ),
        ),
        reason: source,
      );
    }
  });

  test('format plus récent : refusé, à mettre à jour', () {
    final json = jsonDecode(
      Backup(
        rows: const ProgressRows(),
        settings: settings,
        exportedAt: start,
      ).encode(),
    ) as Map<String, Object?>;
    json['format'] = backupFormat + 1;
    expect(
      () => Backup.decode(jsonEncode(json), current: const Settings()),
      throwsA(
        isA<BackupException>().having(
          (e) => e.error,
          'error',
          BackupError.tooNew,
        ),
      ),
    );
  });

  test('import refusé par la base : rien ne change', () async {
    final store = await filled();
    final before = await store.load();
    final rows = await store.rows();
    // Deux théories pour la même leçon : clé en double.
    await expectLater(
      store.replace(ProgressRows(theory: [...rows.theory, ...rows.theory])),
      throwsA(anything),
    );
    expect((await store.load()).xp, before.xp);
  });
}
