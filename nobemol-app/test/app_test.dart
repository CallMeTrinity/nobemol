import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson_screen.dart';
import 'package:nobemol/main.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/reading/start_level.dart';

void main() {
  late DateTime now;
  late Content content;

  // Chargé une fois, hors du temps simulé de testWidgets : rootBundle garde
  // ses Future en cache, et elles ne se terminent pas dans le test suivant.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await loadContent(rootBundle);
  });

  /// Lance l'appli et ouvre l'entrée [levelTitle] de l'accueil (point de
  /// départ ou leçon).
  Future<ProviderContainer?> startSession(
    WidgetTester tester,
    String levelTitle, {
    bool expectReading = true,
  }) async {
    now = DateTime(2026);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWithValue(content),
          randomProvider.overrideWithValue(Random(1)),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const NobemolApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Par où commencer ?'), findsOneWidget);
    // Les leçons sont en bas de l'accueil. dragUntilVisible glisse avant de
    // vérifier : on ne l'appelle que si l'entrée est hors de l'écran.
    if (find.text(levelTitle).hitTestable().evaluate().isEmpty) {
      await tester.dragUntilVisible(
        find.text(levelTitle),
        find.byType(ListView),
        const Offset(0, -200),
      );
    }
    await tester.tap(find.text(levelTitle));
    await tester.pumpAndSettle();
    if (!expectReading) return null;
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
    final expected = container
        .read(sessionProvider(level.params))
        .question
        .answer;
    final step = right
        ? expected
        : DiatonicStep.values[(expected.index + 1) % 7];
    now = now.add(const Duration(seconds: 3));
    await tester.tap(find.byKey(ValueKey('note-${step.name}')));
    await tester.pump();
    await tester.pump(wrongAnswerDelay);
  }

  testWidgets('une session complète en clé de sol', (tester) async {
    final container = (await startSession(tester, 'Je débute'))!;
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
    expect(container.read(sessionProvider(level.params)).answered, 0);
    expect(find.byType(NotationView), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Par où commencer ?'), findsOneWidget);
  });

  testWidgets('la correction ne compte qu’une réponse', (tester) async {
    final container = (await startSession(tester, 'Je connais la clé de sol'))!;
    final params = StartLevel.knowsTreble.params;
    final expected = container.read(sessionProvider(params)).question.answer;

    await tester.tap(find.byKey(ValueKey('note-${expected.name}')));
    await tester.tap(find.byKey(ValueKey('note-${expected.name}')));
    await tester.pump();

    final session = container.read(sessionProvider(params));
    expect(session.phase, SessionPhase.feedback);
    expect(session.answered, 1);
    expect(session.correct, 1);

    await tester.pump(rightAnswerDelay);
    expect(container.read(sessionProvider(params)).phase, SessionPhase.asking);
  });

  testWidgets('grande portée', (tester) async {
    final container = (await startSession(tester, 'Je lis les deux clés'))!;
    final session = container.read(
      sessionProvider(StartLevel.readsBoth.params),
    );
    expect(session.question.system.staves, hasLength(2));
  });

  testWidgets('une leçon écrite en YAML : théorie puis exercice', (
    tester,
  ) async {
    await startSession(tester, 'La clé de sol', expectReading: false);

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.textContaining('Une portée a cinq lignes'), findsOneWidget);
    expect(find.byType(NotationView), findsOneWidget);
    expect(find.text('Précédent'), findsNothing);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La clé de sol s\'enroule'), findsOneWidget);
    expect(find.text('Précédent'), findsOneWidget);

    while (find.text('Suivant').evaluate().isNotEmpty) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text("S'entraîner"));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    final session = container.read(
      sessionProvider(const NoteReadingParams(staff: StaffSetup.treble)),
    );
    expect(session.answered, 0);
    expect(session.question.system.staves.single.clef, Clef.treble);
  });
}
