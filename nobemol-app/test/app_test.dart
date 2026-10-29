import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/home/home_screen.dart';
import 'package:nobemol/home/skill_screen.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson_screen.dart';
import 'package:nobemol/main.dart';
import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/glyph_view.dart';

void main() {
  late DateTime now;
  late Content content;
  late NobemolDatabase db;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Chargé une fois, hors du temps simulé de testWidgets : rootBundle garde
  // ses Future en cache, et elles ne se terminent pas dans le test suivant.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await loadContent(rootBundle);
  });

  // Base en mémoire, neuve à chaque test.
  setUp(() {
    now = DateTime(2026);
    db = NobemolDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  /// Lance l'appli sur la base [db], comme au démarrage du téléphone.
  Future<void> launch(WidgetTester tester) async {
    final store = ProgressStore(db);
    final progress = await store.load();
    // Une autre appli : rien ne reste du lancement précédent.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWithValue(content),
          progressProvider.overrideWith(
            () => ProgressNotifier(store, progress),
          ),
          randomProvider.overrideWithValue(Random(1)),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const NobemolApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Fait défiler le Parcours jusqu'à [finder], s'il est hors de l'écran.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    // dragUntilVisible glisse avant de vérifier : on ne l'appelle que si
    // l'entrée est hors de l'écran. Le finder hitTestable continue tant que
    // l'entrée n'est pas touchable : construite juste sous le bord, elle
    // n'est pas encore à l'écran.
    if (finder.hitTestable().evaluate().isEmpty) {
      await tester.dragUntilVisible(
        finder.hitTestable(),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
    }
  }

  /// Lance l'appli et ouvre le point de départ [levelTitle] de la lecture
  /// libre.
  Future<ProviderContainer> startSession(
    WidgetTester tester,
    String levelTitle,
  ) async {
    await launch(tester);
    await scrollTo(tester, find.text(levelTitle));
    await tester.tap(find.text(levelTitle));
    await tester.pumpAndSettle();
    expect(find.byType(NotationView), findsOneWidget);

    return ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
  }

  /// Lance l'appli et ouvre la théorie d'une leçon, verrouillée ou non :
  /// comme depuis l'écran de sa compétence.
  Future<void> openLesson(WidgetTester tester, String id) async {
    await launch(tester);
    unawaited(
      GoRouter.of(tester.element(find.byType(HomeScreen))).push('/lecon/$id'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
  }

  /// Joue toute la théorie de la leçon ouverte, puis passe à l'exercice.
  Future<void> readTheory(WidgetTester tester) async {
    while (find.text('Suivant').evaluate().isNotEmpty) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text("S'entraîner"));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(ValueKey('answer-${step.name}')));
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

    expect(find.text('SESSION TERMINÉE'), findsOneWidget);
    expect(find.text('10 / 20'), findsOneWidget);
    expect(find.text('Temps : 1:00'), findsOneWidget);

    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider(level.params)).answered, 0);
    expect(find.byType(NotationView), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('la correction ne compte qu’une réponse', (tester) async {
    final container = await startSession(tester, 'Je connais la clé de sol');
    final params = StartLevel.knowsTreble.params;
    final expected = container.read(sessionProvider(params)).question.answer;

    await tester.tap(find.byKey(ValueKey('answer-${expected.name}')));
    await tester.tap(find.byKey(ValueKey('answer-${expected.name}')));
    await tester.pump();

    final session = container.read(sessionProvider(params));
    expect(session.phase, SessionPhase.feedback);
    expect(session.answered, 1);
    expect(session.correct, 1);

    await tester.pump(rightAnswerDelay);
    expect(container.read(sessionProvider(params)).phase, SessionPhase.asking);
  });

  testWidgets('grande portée', (tester) async {
    final container = await startSession(tester, 'Je lis les deux clés');
    final session = container.read(
      sessionProvider(StartLevel.readsBoth.params),
    );
    expect(session.question.system.staves, hasLength(2));
  });

  testWidgets('une leçon écrite en YAML : théorie puis exercice', (
    tester,
  ) async {
    await openLesson(tester, 'treble-clef');

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.textContaining('Une portée a cinq lignes'), findsOneWidget);
    expect(find.byType(NotationView), findsOneWidget);
    expect(find.text('Précédent'), findsNothing);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La clé de sol s\'enroule'), findsOneWidget);
    expect(find.text('Précédent'), findsOneWidget);

    await readTheory(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    final session = container.read(
      sessionProvider(const NoteReadingParams(staff: StaffSetup.treble)),
    );
    expect(session.answered, 0);
    expect(session.question.system.staves.single.clef, Clef.treble);
  });

  testWidgets('une leçon identify-note : notes ciblées dans une phrase', (
    tester,
  ) async {
    await openLesson(tester, 'measures');
    await readTheory(tester);

    final exercise =
        content.lesson('measures')!.exercise as IdentifyNoteExercise;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    final view = tester.widget<NotationView>(find.byType(NotationView));
    expect(view.highlights.keys, [exercise.targets.first]);
    expect(view.halos.keys, [exercise.targets.first]);
    // La cible doit se voir parmi les autres notes, dans le thème de
    // l'appli : un écart net sur au moins une composante, pas juste deux
    // couleurs différentes.
    final target = view.highlights.values.single;
    final ink = view.color!;
    final gap = [
      (target.r - ink.r).abs(),
      (target.g - ink.g).abs(),
      (target.b - ink.b).abs(),
    ].reduce(max);
    expect(gap, greaterThan(0.4));

    for (var i = 0; i < exercise.length; i++) {
      final question = container.read(sessionProvider(exercise)).question;
      expect(question.targets, [exercise.targets[i]]);
      expect(question.system, same(exercise.system));
      now = now.add(const Duration(seconds: 2));
      await tester.tap(find.byKey(ValueKey('answer-${question.answer.name}')));
      await tester.pump();
      await tester.pump(wrongAnswerDelay);
    }
    await tester.pumpAndSettle();

    expect(find.text('SESSION TERMINÉE'), findsOneWidget);
    expect(
      find.text('${exercise.length} / ${exercise.length}'),
      findsOneWidget,
    );
  });

  testWidgets('une leçon identify-duration : la liaison entière est colorée', (
    tester,
  ) async {
    await openLesson(tester, 'ties');
    await readTheory(tester);

    expect(find.text('Combien de temps dure-t-elle ?'), findsOneWidget);
    expect(find.text('1½'), findsOneWidget);

    final exercise =
        content.lesson('ties')!.exercise as IdentifyDurationExercise;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    // Première cible : mi blanche liée à mi noire, sur deux mesures.
    final view = tester.widget<NotationView>(find.byType(NotationView));
    expect(view.highlights.keys, const [
      EventRef(staff: 0, measure: 0, event: 2),
      EventRef(staff: 0, measure: 1, event: 0),
    ]);
    expect(
      container.read(sessionProvider(exercise)).question.answer,
      Beats.three,
    );

    for (var i = 0; i < exercise.length; i++) {
      final question = container.read(sessionProvider(exercise)).question;
      await tester.tap(find.byKey(ValueKey('answer-${question.answer.name}')));
      await tester.pump();
      await tester.pump(wrongAnswerDelay);
    }
    await tester.pumpAndSettle();
    expect(
      find.text('${exercise.length} / ${exercise.length}'),
      findsOneWidget,
    );
  });

  testWidgets('une leçon identify-marking : le signe est coloré, pas la note', (
    tester,
  ) async {
    await openLesson(tester, 'articulations');
    await readTheory(tester);

    expect(find.text('Ce signe veut dire…'), findsOneWidget);
    expect(find.text('piqué'), findsOneWidget);
    expect(find.text('prolongé à volonté'), findsOneWidget);

    final exercise =
        content.lesson('articulations')!.exercise as IdentifyMarkingExercise;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    final view = tester.widget<NotationView>(find.byType(NotationView));
    expect(view.highlights, isEmpty);
    expect(view.halos, isEmpty);
    expect(view.decorationHighlights.keys, [exercise.targets.first]);
    expect(view.decorationHalos.keys, [exercise.targets.first]);
    expect(
      container.read(sessionProvider(exercise)).question.answer,
      Marking.staccato,
    );

    // Des cartes, trois par ligne.
    Offset card(String name) =>
        tester.getTopLeft(find.byKey(ValueKey('answer-$name')));
    expect(card('tenuto').dy, card('staccato').dy);
    expect(card('accent').dy, card('staccato').dy);
    expect(card('fermata').dy, greaterThan(card('staccato').dy));

    // Le signe n'apparaît sur les cartes qu'à la correction.
    Finder sign(String name) => find.descendant(
      of: find.byKey(ValueKey('answer-$name')),
      matching: find.byType(GlyphView),
    );
    expect(find.byType(GlyphView), findsNothing);
    await tester.tap(find.byKey(const ValueKey('answer-tenuto')));
    await tester.pump();
    expect(sign('staccato'), findsOneWidget);
    expect(sign('tenuto'), findsOneWidget);
    await tester.pump(wrongAnswerDelay);
    expect(find.byType(GlyphView), findsNothing);

    for (var i = 1; i < exercise.length; i++) {
      final question = container.read(sessionProvider(exercise)).question;
      await tester.tap(find.byKey(ValueKey('answer-${question.answer.name}')));
      await tester.pump();
      await tester.pump(wrongAnswerDelay);
    }
    await tester.pumpAndSettle();
    expect(
      find.text('${exercise.length - 1} / ${exercise.length}'),
      findsOneWidget,
    );
  });

  testWidgets(
    'théorie : la première phrase en titre, les noms sous la portée',
    (tester) async {
      await openLesson(tester, 'treble-clef');
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(
        find.text('À partir du sol, on lit de proche en proche.'),
        findsOneWidget,
      );
      expect(find.textContaining('Juste en dessous'), findsOneWidget);
      final view = tester.widget<NotationView>(find.byType(NotationView));
      expect(view.labels.values, ['fa', 'sol', 'la']);

      await tester.tap(find.text('Précédent'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NotationView>(find.byType(NotationView)).labels,
        isEmpty,
      );

      await tester.tap(find.byKey(const ValueKey('close')));
      await tester.pumpAndSettle();
      // Le Parcours garde sa position : on y était descendu.
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('quatre onglets, chacun garde sa place', (tester) async {
    await openLesson(tester, 'treble-clef');
    // La leçon passe au-dessus de la barre d'onglets.
    expect(find.byKey(const ValueKey('tab-1')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('close')));
    await tester.pumpAndSettle();

    for (final (index, title) in ['Réviser', 'Arcade', 'Profil'].indexed) {
      await tester.tap(find.byKey(ValueKey('tab-${index + 1}')));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      expect(find.text('BIENTÔT'), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('tab-0')));
    await tester.pumpAndSettle();
    // Le Parcours garde sa position : on y était descendu.
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('thème sombre quand le téléphone est en sombre', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final container = await startSession(tester, 'Je débute');
    expect(container, isNotNull);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(
      Theme.of(tester.element(find.byWidget(scaffold))).scaffoldBackgroundColor,
      NobemolColors.dark.bg,
    );
    final view = tester.widget<NotationView>(find.byType(NotationView));
    expect(view.color, NobemolColors.dark.ink);
  });

  testWidgets('une session terminée rapporte de l’XP, gardée en base', (
    tester,
  ) async {
    final container = await startSession(tester, 'Je débute');
    for (var i = 0; i < sessionLength; i++) {
      await answer(tester, container, StartLevel.beginner, right: true);
    }
    await tester.pumpAndSettle();
    // 4 × 10, puis 16 × 15 avec le combo.
    expect(find.text('+280 XP'), findsOneWidget);

    // Relance : la progression est relue depuis la base.
    await launch(tester);
    expect(find.text('Niveau 2'), findsOneWidget);
    expect(find.text('80 / 400 XP'), findsOneWidget);
    expect(find.text('ATTEINT'), findsOneWidget);
  });

  testWidgets('une session quittée avant la fin n’est pas gardée', (
    tester,
  ) async {
    final container = await startSession(tester, 'Je débute');
    await answer(tester, container, StartLevel.beginner, right: true);
    await tester.tap(find.byKey(const ValueKey('close')));
    await tester.pumpAndSettle();

    expect(await db.select(db.sessions).get(), isEmpty);
  });

  testWidgets('une leçon interrompue reprend à la bonne page après '
      'redémarrage', (tester) async {
    await launch(tester);
    expect(find.text('COMMENCER'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resume')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('close')));
    await tester.pumpAndSettle();
    expect(find.text('REPRENDRE'), findsOneWidget);
    expect(find.text('Théorie · page 3 sur 5'), findsOneWidget);

    await launch(tester);
    expect(find.text('Théorie · page 3 sur 5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resume')));
    await tester.pumpAndSettle();
    expect(
      find.text('À partir du sol, on lit de proche en proche.'),
      findsOneWidget,
    );

    // Théorie lue : la reprise passe à l'exercice.
    await readTheory(tester);
    expect(find.byType(ReadingScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close')));
    await tester.pumpAndSettle();
    expect(find.text('Exercice'), findsOneWidget);
  });

  testWidgets('compétences : verrouillées par l’arbre, débloquées par la '
      'maîtrise', (tester) async {
    await launch(tester);
    final bass = find.byKey(const ValueKey('skill-note-reading.bass'));
    await scrollTo(tester, bass);
    expect(
      find.descendant(
        of: bass,
        matching: find.text('Se débloque après « Lire en clé de sol »'),
      ),
      findsOneWidget,
    );
    await tester.tap(bass);
    await tester.pumpAndSettle();
    expect(find.byType(SkillScreen), findsNothing);

    final treble = find.byKey(const ValueKey('skill-note-reading.treble'));
    expect(
      find.descendant(of: treble, matching: find.text('À FAIRE')),
      findsOneWidget,
    );
    await tester.tap(treble);
    await tester.pumpAndSettle();
    expect(find.byType(SkillScreen), findsOneWidget);
    expect(find.text('5 pages'), findsOneWidget);
    expect(find.text('Pas encore fait'), findsOneWidget);
    expect(find.text("Après l'exercice"), findsOneWidget);

    // L'exercice directement, sans la théorie, puis retour à la compétence.
    await tester.tap(find.byKey(const ValueKey('exercise-treble-clef')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    for (var i = 0; i < sessionLength; i++) {
      await answer(tester, container, StartLevel.beginner, right: i > 0);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.byType(SkillScreen), findsOneWidget);
    expect(find.text('Meilleur score : 95 %'), findsOneWidget);
    expect(find.text('MAÎTRISÉ'), findsOneWidget);
    expect(find.text('Bientôt'), findsOneWidget);
    expect(
      (await db.select(db.masteredSkills).get()).map((row) => row.skillId),
      ['note-reading.treble'],
    );

    await tester.tap(find.byKey(const ValueKey('back')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: bass, matching: find.text('À FAIRE')),
      findsOneWidget,
    );
  });
}
