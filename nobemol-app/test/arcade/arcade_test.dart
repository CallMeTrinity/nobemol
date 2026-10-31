import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/arcade/arcade.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/start_level.dart';

void main() {
  late Content content;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await loadContent(rootBundle);
  });

  final day = DateTime(2026, 11, 1);

  /// Une session terminée de la leçon [lessonId], ou une partie d'arcade.
  SessionSummary session({
    String? lessonId,
    int xp = 10,
    String? arcade,
    int? score,
  }) => SessionSummary(
    lessonId: lessonId,
    startedAt: day,
    finishedAt: day,
    questions: 1,
    correct: 1,
    xp: xp,
    bestCombo: 1,
    arcade: arcade,
    arcadeScore: score,
  );

  Arcade arcade(
    List<SessionSummary> sessions, {
    Set<String> acquired = const {},
  }) => Arcade(content, Progress(sessions: sessions), acquired: acquired);

  test('rien d’appris : pas de clé, pas de partie', () {
    final empty = arcade([]);
    expect(empty.clefs, isEmpty);
    expect(empty.game(ArcadeMode.chrono, ArcadeClef.treble), isNull);
  });

  test('une clé s’ouvre avec l’exercice de sa leçon', () {
    final treble = arcade([session(lessonId: 'treble-clef')]);
    expect(treble.clefs, [ArcadeClef.treble]);
    expect(
      treble.game(ArcadeMode.chrono, ArcadeClef.treble)!.stages.single,
      const NoteReadingParams(staff: StaffSetup.treble),
    );
    expect(treble.game(ArcadeMode.chrono, ArcadeClef.bass), isNull);
  });

  test('lignes supplémentaires et altérations une fois apprises', () {
    final more = arcade([
      session(lessonId: 'treble-clef'),
      session(lessonId: 'ledger-lines'),
      session(lessonId: 'accidentals'),
    ]);
    expect(
      more.params(ArcadeClef.treble),
      const NoteReadingParams(
        staff: StaffSetup.treble,
        ledgerLines: 1,
        accidentals: true,
      ),
    );
  });

  test('le point de départ compte comme appris', () {
    final both = arcade([], acquired: StartLevel.readsBoth.acquired);
    expect(both.clefs, ArcadeClef.values);
  });

  test('survie : au niveau 5, toutes les clés apprises en étapes', () {
    final sessions = [
      session(lessonId: 'treble-clef'),
      session(lessonId: 'bass-clef'),
    ];
    expect(arcade(sessions).game(ArcadeMode.survival, null), isNull);

    final level5 = arcade([
      ...sessions,
      session(xp: Level.threshold(survivalLevel)),
    ]);
    final survival = level5.game(ArcadeMode.survival, ArcadeClef.bass)!;
    expect(survival.clef, isNull);
    expect(survival.stages.map((params) => params.staff), [
      StaffSetup.treble,
      StaffSetup.bass,
    ]);
  });

  test('records : le meilleur score par mode et par clé', () {
    final played = arcade([
      session(lessonId: 'treble-clef'),
      session(arcade: 'chrono:treble', score: 900),
      session(arcade: 'chrono:treble', score: 1200),
      session(arcade: 'chrono:bass', score: 300),
      session(arcade: 'survival', score: 14),
    ]);
    expect(played.record(ArcadeMode.chrono, ArcadeClef.treble), 1200);
    expect(played.record(ArcadeMode.chrono, ArcadeClef.bass), 300);
    expect(played.record(ArcadeMode.endless, ArcadeClef.treble), isNull);
    // La survie mélange les clés : un seul record.
    expect(played.record(ArcadeMode.survival, ArcadeClef.treble), 14);
  });

  test('format des records stocké', () {
    expect(recordKey(ArcadeMode.chrono, ArcadeClef.grand), 'chrono:grand');
    expect(recordKey(ArcadeMode.endless, ArcadeClef.bass), 'endless:bass');
    expect(recordKey(ArcadeMode.survival, ArcadeClef.bass), 'survival');
  });
}
