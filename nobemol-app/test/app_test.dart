import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/main.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/reading/start_level.dart';

void main() {
  late DateTime now;

  Future<ProviderContainer> startSession(
    WidgetTester tester,
    String levelTitle,
  ) async {
    now = DateTime(2026);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          randomProvider.overrideWithValue(Random(1)),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const NobemolApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Par où commencer ?'), findsOneWidget);
    await tester.tap(find.text(levelTitle));
    await tester.pumpAndSettle();
    expect(find.byType(NotationView), findsOneWidget);

    return ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
  }

  /// Répond à la question en cours, juste ou faux, et passe à la suivante.
  Future<void> answer(
    WidgetTester tester,
    ProviderContainer container,
    StartLevel level, {
    required bool right,
  }) async {
    final expected = container.read(sessionProvider(level)).question.answer;
    final step = right
        ? expected
        : DiatonicStep.values[(expected.index + 1) % 7];
    now = now.add(const Duration(seconds: 3));
    await tester.tap(find.byKey(ValueKey('note-${step.name}')));
    await tester.pump();
    await tester.pump(wrongAnswerDelay);
  }

  testWidgets('une session complète en clé de sol', (tester) async {
    final container = await startSession(tester, 'Je débute');
    const level = StartLevel.beginner;

    for (var i = 0; i < sessionLength; i++) {
      await answer(tester, container, level, right: i.isEven);
    }
    await tester.pumpAndSettle();

    expect(find.text('Session terminée'), findsOneWidget);
    expect(find.text('10 / 20'), findsOneWidget);
    expect(find.text('Temps : 1:00'), findsOneWidget);

    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider(level)).answered, 0);
    expect(find.byType(NotationView), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Par où commencer ?'), findsOneWidget);
  });

  testWidgets('la correction ne compte qu’une réponse', (tester) async {
    final container = await startSession(tester, 'Je connais la clé de sol');
    const level = StartLevel.knowsTreble;
    final expected = container.read(sessionProvider(level)).question.answer;

    await tester.tap(find.byKey(ValueKey('note-${expected.name}')));
    await tester.tap(find.byKey(ValueKey('note-${expected.name}')));
    await tester.pump();

    final session = container.read(sessionProvider(level));
    expect(session.phase, SessionPhase.feedback);
    expect(session.answered, 1);
    expect(session.correct, 1);

    await tester.pump(rightAnswerDelay);
    expect(container.read(sessionProvider(level)).phase, SessionPhase.asking);
  });

  testWidgets('grande portée', (tester) async {
    final container = await startSession(tester, 'Je lis les deux clés');
    final session = container.read(sessionProvider(StartLevel.readsBoth));
    expect(session.question.system.staves, hasLength(2));
  });
}
