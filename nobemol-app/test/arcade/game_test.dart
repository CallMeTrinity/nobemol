import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/arcade/arcade.dart';
import 'package:nobemol/arcade/game.dart';
import 'package:nobemol/clock.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/session.dart';

void main() {
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    now = DateTime(2026, 11, 1, 18);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        randomProvider.overrideWithValue(Random(1)),
      ],
    );
  });
  tearDown(() => container.dispose());

  const treble = NoteReadingParams(staff: StaffSetup.treble);
  const bass = NoteReadingParams(staff: StaffSetup.bass);

  ArcadeGame game(ArcadeMode mode, {List<NoteReadingParams>? stages}) =>
      ArcadeGame(
        mode: mode,
        clef: mode == ArcadeMode.survival ? null : ArcadeClef.treble,
        stages: stages ?? const [treble],
      );

  ArcadeState state(ArcadeGame game) => container.read(arcadeProvider(game));
  ArcadeNotifier notifier(ArcadeGame game) =>
      container.read(arcadeProvider(game).notifier);

  /// Répond juste ou faux après [after], puis attend la note suivante.
  void play(ArcadeGame game, {required bool right, Duration? after}) {
    final expected = state(game).question.answer;
    now = now.add(after ?? const Duration(seconds: 1));
    notifier(game).answer(
      right ? expected : NoteName.naturals[(expected.step.index + 1) % 7],
    );
    now = now.add(wrongFlash);
    notifier(game).tick();
  }

  group('chrono', () {
    final chrono = game(ArcadeMode.chrono);

    test('50 points par note, multipliés par le combo', () {
      container.listen(arcadeProvider(chrono), (_, _) {});
      for (var i = 0; i < 5; i++) {
        play(chrono, right: true);
      }
      // 4 notes à ×1, la 5e à ×2.
      expect(state(chrono).score, 4 * 50 + 100);
      play(chrono, right: false);
      expect(state(chrono).combo, 0);
      expect(state(chrono).score, 300);
      expect(state(chrono).xp, 5 * arcadeXpPerNote);
    });

    test('60 secondes : la note en cours ne compte pas', () {
      container.listen(arcadeProvider(chrono), (_, _) {});
      final start = now;
      play(chrono, right: true);
      now = start.add(chronoLength);
      notifier(chrono).tick();
      final end = state(chrono);
      expect(end.phase, ArcadePhase.finished);
      expect(end.finishedAt, start.add(chronoLength));
      expect(end.answers, hasLength(1));
    });

    test('la pause arrête le chrono, et le temps de réponse', () {
      container.listen(arcadeProvider(chrono), (_, _) {});
      final start = now;
      now = now.add(const Duration(seconds: 2));
      notifier(chrono).pause();
      now = now.add(const Duration(minutes: 5));
      notifier(chrono).tick();
      expect(state(chrono).phase, ArcadePhase.asking);
      // En pause, les touches ne répondent pas.
      notifier(chrono).answer(state(chrono).question.answer);
      expect(state(chrono).answers, isEmpty);
      notifier(chrono).resume();
      expect(
        state(chrono).endsAt,
        start.add(chronoLength + const Duration(minutes: 5)),
      );
      now = now.add(const Duration(seconds: 1));
      notifier(chrono).answer(state(chrono).question.answer);
      expect(state(chrono).answers.single.elapsed, const Duration(seconds: 3));
    });
  });

  group('sans fin', () {
    final endless = game(ArcadeMode.endless);

    test('les notes accélèrent', () {
      expect(noteTime(0), const Duration(seconds: 6));
      expect(noteTime(10), lessThan(noteTime(9)));
      expect(noteTime(200), const Duration(milliseconds: 1500));
    });

    test('une erreur et c’est fini', () {
      container.listen(arcadeProvider(endless), (_, _) {});
      play(endless, right: true);
      play(endless, right: true);
      play(endless, right: false);
      expect(state(endless).phase, ArcadePhase.finished);
      expect(state(endless).score, 2);
    });

    test('temps écoulé : une erreur, gardée pour la révision', () {
      container.listen(arcadeProvider(endless), (_, _) {});
      now = now.add(noteTime(0));
      notifier(endless).tick();
      final timeout = state(endless).answers.single;
      expect(timeout.given, NoAnswer.timeout);
      expect(timeout.correct, isFalse);
      expect(timeout.card, startsWith('note:treble:'));
      now = now.add(wrongFlash);
      notifier(endless).tick();
      expect(state(endless).phase, ArcadePhase.finished);
    });
  });

  group('survie', () {
    final survival = game(ArcadeMode.survival, stages: const [treble, bass]);

    test('trois erreurs', () {
      container.listen(arcadeProvider(survival), (_, _) {});
      play(survival, right: false);
      play(survival, right: false);
      expect(state(survival).lives, 1);
      expect(state(survival).phase, ArcadePhase.asking);
      play(survival, right: false);
      expect(state(survival).phase, ArcadePhase.finished);
    });

    test('une nouvelle clé toutes les 10 notes justes', () {
      container.listen(arcadeProvider(survival), (_, _) {});
      final clefs = <Object>{};
      for (var i = 0; i < 40; i++) {
        final question = state(survival).question;
        if (i < survivalStage) {
          expect(question.system.staves.single.clef, Clef.treble);
        }
        clefs.add(question.system.staves.single.clef);
        play(survival, right: true, after: const Duration(milliseconds: 500));
      }
      expect(state(survival).stage, 1);
      expect(clefs, hasLength(2));
    });
  });

  group('entraînement', () {
    final practice = game(ArcadeMode.practice);

    test('sans chrono : le temps ne compte pas', () {
      container.listen(arcadeProvider(practice), (_, _) {});
      expect(state(practice).endsAt, isNull);
      expect(state(practice).deadline, isNull);
      now = now.add(const Duration(minutes: 10));
      notifier(practice).tick();
      expect(state(practice).phase, ArcadePhase.asking);
      expect(state(practice).answers, isEmpty);
    });

    test('20 notes, justes ou fausses, puis la fin', () {
      container.listen(arcadeProvider(practice), (_, _) {});
      for (var i = 0; i < practiceLength - 1; i++) {
        play(practice, right: i.isEven);
      }
      expect(state(practice).phase, ArcadePhase.asking);
      play(practice, right: true);
      final end = state(practice);
      expect(end.phase, ArcadePhase.finished);
      expect(end.answers, hasLength(practiceLength));
      // Le score compte les notes justes.
      expect(end.score, 11);
      expect(end.xp, 11 * arcadeXpPerNote);
    });
  });
}
