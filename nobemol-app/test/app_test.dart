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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/home/home_screen.dart';
import 'package:nobemol/home/skill_screen.dart';
import 'package:nobemol/l10n/app_localizations_fr.dart';
import 'package:nobemol/l10n/explanations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson_screen.dart';
import 'package:nobemol/main.dart';
import 'package:nobemol/onboarding/onboarding_screen.dart';
import 'package:nobemol/progress/course.dart';
import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/review/card.dart';
import 'package:nobemol/review/review_screen.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/settings/settings_screen.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/glyph_view.dart';

void main() {
  late DateTime now;
  late Content content;
  late NobemolDatabase db;
  late SharedPreferences prefs;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Chargé une fois, hors du temps simulé de testWidgets : rootBundle garde
  // ses Future en cache, et elles ne se terminent pas dans le test suivant.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await loadContent(rootBundle);
  });

  // Base en mémoire, neuve à chaque test. Réglages neufs aussi, démarrage
  // déjà passé : il a ses propres tests.
  setUp(() async {
    now = DateTime(2026);
    db = NobemolDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({'onboarded': true});
    prefs = await SharedPreferences.getInstance();
  });
  tearDown(() => db.close());

  /// Lance l'appli sur la base [db] et les réglages [prefs], comme au
  /// démarrage du téléphone.
  Future<void> launch(WidgetTester tester) async {
    final store = ProgressStore(db);
    final progress = await store.load();
    final settingsStore = SettingsStore(prefs);
    final settings = settingsStore.load();
    // Une autre appli : rien ne reste du lancement précédent.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWithValue(content),
          progressProvider.overrideWith(
            () => ProgressNotifier(store, progress),
          ),
          settingsProvider.overrideWith(
            () => SettingsNotifier(settingsStore, settings),
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

  /// Donne [choice] : une touche, une tuile ou une carte. Une touche noire
  /// ouvre d'abord sa bulle.
  Future<void> give(WidgetTester tester, Enum choice) async {
    if (choice case NoteName(:final blackKey?)) {
      await tester.tap(find.byKey(ValueKey('black-${blackKey.name}')));
      await tester.pump();
    }
    await tester.tap(find.byKey(ValueKey('answer-${choice.name}')));
    await tester.pump();
  }

  /// Passe la correction : question suivante, ou résultats. « Continuer »
  /// ne répond qu'une fois le panneau monté.
  Future<void> next(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('continue')));
    await tester.pump();
  }

  /// Répond à la question en cours, juste ou faux, et passe à la suivante.
  Future<void> answer(
    WidgetTester tester,
    ProviderContainer container,
    StartLevel level, {
    required bool right,
  }) async {
    final expected =
        container.read(sessionProvider(level.params)).question.answer
            as NoteName;
    final choice = right
        ? expected
        : NoteName.naturals[(expected.step.index + 1) % 7];
    now = now.add(const Duration(seconds: 3));
    await give(tester, choice);
    await next(tester);
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

    // Juste ou faux, la question suivante attend « Continuer », qui ne
    // répond pas tout de suite : un double appui ne saute pas la correction.
    await tester.pump(const Duration(seconds: 5));
    expect(
      container.read(sessionProvider(params)).phase,
      SessionPhase.feedback,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue')));
    await tester.pump();
    expect(container.read(sessionProvider(params)).phase, SessionPhase.asking);
  });

  testWidgets('« Continuer » ignore un appui trop rapide', (tester) async {
    final container = await startSession(tester, 'Je débute');
    final params = StartLevel.beginner.params;
    final expected = container.read(sessionProvider(params)).question.answer;
    await tester.tap(find.byKey(ValueKey('answer-${expected.name}')));
    await tester.pump();
    // Panneau monté (200 ms), verrou encore actif (300 ms).
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('continue')));
    await tester.pump();
    expect(
      container.read(sessionProvider(params)).phase,
      SessionPhase.feedback,
    );

    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('continue')));
    await tester.pump();
    expect(container.read(sessionProvider(params)).phase, SessionPhase.asking);
  });

  testWidgets('le panneau de correction ne décale pas la portée', (
    tester,
  ) async {
    await startSession(tester, 'Je débute');
    final before = tester.getRect(find.byType(NotationView));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    final expected = container
        .read(sessionProvider(StartLevel.beginner.params))
        .question
        .answer;
    await tester.tap(find.byKey(ValueKey('answer-${expected.name}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('feedback')), findsOneWidget);
    expect(tester.getRect(find.byType(NotationView)), before);
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
      await give(tester, question.answer);
      await next(tester);
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
      await give(tester, question.answer);
      await next(tester);
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

    // Le sens seul sur les cartes, jamais le signe : il suffirait de
    // comparer les formes.
    await tester.tap(find.byKey(const ValueKey('answer-tenuto')));
    await tester.pump();
    await next(tester);
    expect(find.byType(GlyphView), findsNothing);

    for (var i = 1; i < exercise.length; i++) {
      final question = container.read(sessionProvider(exercise)).question;
      await give(tester, question.answer);
      await next(tester);
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

  group('révision', () {
    /// Ouvre l'onglet Réviser.
    Future<void> openReview(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tab-1')));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewScreen), findsOneWidget);
    }

    testWidgets('une note ratée revient le lendemain, puis s’espace', (
      tester,
    ) async {
      final container = await startSession(tester, 'Je débute');
      const level = StartLevel.beginner;
      final missed = cardOf(
        container.read(sessionProvider(level.params)).question,
      );
      for (var i = 0; i < sessionLength; i++) {
        await answer(tester, container, level, right: i > 0);
      }
      await tester.pumpAndSettle();

      // Le jour même : la carte existe, pas encore due.
      await launch(tester);
      await openReview(tester);
      expect(find.text("Rien à réviser aujourd'hui."), findsOneWidget);
      expect(find.text('Prochaine carte demain.'), findsOneWidget);
      expect(find.byKey(const ValueKey('review-start')), findsNothing);

      // Le lendemain : elle revient.
      now = now.add(const Duration(days: 1));
      await launch(tester);
      await openReview(tester);
      expect(find.text('1 carte · environ 1 min'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('review-start')));
      await tester.pumpAndSettle();

      final exercise =
          tester.widget<ReadingScreen>(find.byType(ReadingScreen)).exercise
              as ReviewExercise;
      final question = exercise.cards.single;
      expect(cardOf(question), missed);
      // Seule sur sa portée, en grand, comme la lecture de notes.
      expect(question.system.staves.single.notes, hasLength(1));
      await give(tester, question.answer);
      await next(tester);
      await tester.pumpAndSettle();
      expect(find.text('SESSION TERMINÉE'), findsOneWidget);
      // Rejouée, une révision ne serait plus une révision.
      expect(find.text('Recommencer'), findsNothing);

      // Juste : elle revient dans 3 jours.
      await launch(tester);
      await openReview(tester);
      expect(find.text('Prochaine carte dans 3 jours.'), findsOneWidget);

      now = now.add(const Duration(days: 3));
      await launch(tester);
      await openReview(tester);
      expect(find.byKey(const ValueKey('review-start')), findsOneWidget);
    });

    testWidgets('sans carte : l’onglet explique ce qui viendra', (
      tester,
    ) async {
      await launch(tester);
      await openReview(tester);
      expect(find.textContaining('Rien à réviser pour l'), findsOneWidget);
    });

    testWidgets('les plus difficiles, et les signes en révision', (
      tester,
    ) async {
      final store = ProgressStore(db);
      // Un crescendo raté deux fois, la veille et l'avant-veille.
      for (final days in [2, 1]) {
        final at = now.subtract(Duration(days: days));
        await store.recordSession(
          lessonId: 'hairpins',
          startedAt: at,
          finishedAt: at,
          answers: [
            AnswerRecord(
              expected: Marking.crescendo,
              given: Marking.diminuendo,
              elapsed: const Duration(seconds: 2),
              xp: 0,
              card: 'marking:hairpin:crescendo',
            ),
          ],
          bestCombo: 0,
        );
      }
      await launch(tester);
      await openReview(tester);
      expect(find.text('Les plus difficiles'), findsOneWidget);
      expect(find.text('ratée 2 fois'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('review-start')));
      await tester.pumpAndSettle();
      // Les réponses de la leçon des soufflets.
      for (final marking in [
        Marking.piano,
        Marking.forte,
        Marking.crescendo,
        Marking.diminuendo,
      ]) {
        expect(find.byKey(ValueKey('answer-${marking.name}')), findsOneWidget);
      }
      expect(find.text('Ce signe veut dire…'), findsOneWidget);
    });
  });

  testWidgets('quatre onglets, chacun garde sa place', (tester) async {
    await openLesson(tester, 'treble-clef');
    // La leçon passe au-dessus de la barre d'onglets.
    expect(find.byKey(const ValueKey('tab-1')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewScreen), findsOneWidget);
    for (final (index, title) in ['Arcade', 'Profil'].indexed) {
      await tester.tap(find.byKey(ValueKey('tab-${index + 2}')));
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
    // Objectif par défaut : 5 min, 300 XP.
    expect(find.text('280 / 300 XP'), findsOneWidget);
  });

  testWidgets('une session quittée avant la fin n’est pas gardée', (
    tester,
  ) async {
    final container = await startSession(tester, 'Je débute');
    await answer(tester, container, StartLevel.beginner, right: true);

    // Retour du téléphone, puis la croix : la même confirmation.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("Quitter l'exercice ?"), findsOneWidget);
    expect(
      find.text('Ta réponse et les 10 XP de cette session seront perdus.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('quit-stay')));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quit-leave')));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

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
    await tester.tap(find.byKey(const ValueKey('result-continue')));
    await tester.pumpAndSettle();

    // Palier : niveau 2, clé de sol maîtrisée, clé de fa débloquée.
    expect(find.text('NIVEAU SUPÉRIEUR'), findsOneWidget);
    expect(find.text('Niveau 2'), findsOneWidget);
    expect(find.text('MAÎTRISÉ'), findsOneWidget);
    expect(find.text('Lire en clé de sol'), findsOneWidget);
    expect(find.text('Lire en clé de fa'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('milestone-continue')));
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

  testWidgets('une erreur affiche son explication, et la note ratée revient '
      'dans « À revoir »', (tester) async {
    final container = await startSession(tester, 'Je débute');
    final params = StartLevel.beginner.params;
    final question =
        container.read(sessionProvider(params)).question as NoteQuestion;
    final expected = question.answer;
    final given = NoteName.naturals[(expected.step.index + 1) % 7];
    final l10n = AppLocalizationsFr();

    await give(tester, given);
    // Faux : la correction attend « Continuer ».
    await tester.pump(const Duration(seconds: 5));
    expect(
      container.read(sessionProvider(params)).phase,
      SessionPhase.feedback,
    );
    expect(
      find.text(
        "C'est un ${l10n.noteFullName(expected, naming: NoteNaming.solfege)}",
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Tu as répondu : ${l10n.noteFullName(given, naming: NoteNaming.solfege)}.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10n.explain(question, naming: NoteNaming.solfege)),
      findsOneWidget,
    );
    await next(tester);

    for (var i = 1; i < sessionLength; i++) {
      await answer(tester, container, StartLevel.beginner, right: true);
    }
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('pas ${l10n.noteFullName(given, naming: NoteNaming.solfege)}'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('À revoir'), findsOneWidget);
    expect(
      find.text('pas ${l10n.noteFullName(given, naming: NoteNaming.solfege)}'),
      findsOneWidget,
    );
    // 19 justes : 4 × 10, puis 15 × 15 avec le combo.
    expect(find.text('19 bonnes réponses × 10'), findsOneWidget);
    expect(find.text('+190 XP'), findsOneWidget);
    expect(find.text('+75 XP'), findsOneWidget);
    expect(find.text('+265 XP'), findsOneWidget);
  });

  testWidgets('combo : affiché à partir de 2, perdu à la première erreur', (
    tester,
  ) async {
    final container = await startSession(tester, 'Je débute');
    const level = StartLevel.beginner;
    await answer(tester, container, level, right: true);
    expect(find.byKey(const ValueKey('combo')), findsNothing);
    await answer(tester, container, level, right: true);
    await answer(tester, container, level, right: true);
    expect(find.text('×3'), findsOneWidget);

    final expected =
        container.read(sessionProvider(level.params)).question.answer
            as NoteName;
    await give(tester, NoteName.naturals[(expected.step.index + 1) % 7]);
    expect(find.text('COMBO ×3 PERDU'), findsOneWidget);
    await next(tester);
    expect(find.byKey(const ValueKey('combo')), findsNothing);
  });

  testWidgets('armure : touche noire et orthographe, un fa dièse n’est pas '
      'un sol bémol', (tester) async {
    await openLesson(tester, 'key-signature');
    await readTheory(tester);
    expect(find.text('TOUCHE NOIRE POUR UN DIÈSE OU UN BÉMOL'), findsOneWidget);

    // Ré majeur : ré, puis fa dièse par l'armure.
    await give(tester, NoteName.d);
    await next(tester);
    await give(tester, NoteName.gFlat);
    expect(find.text("C'est un fa dièse"), findsOneWidget);
    expect(find.text('Tu as répondu : sol bémol.'), findsOneWidget);
    expect(
      find.text(
        "En clé de sol, le 1er interligne est un fa. L'armure en fait un fa "
        'dièse.',
      ),
      findsOneWidget,
    );
    await next(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingScreen)),
    );
    final exercise =
        content.lesson('key-signature')!.exercise as IdentifyNoteExercise;
    expect(
      container.read(sessionProvider(exercise)).question.answer,
      NoteName.a,
    );
  });

  group('démarrage', () {
    testWidgets('le premier lancement passe par les 3 écrans, une seule fois', (
      tester,
    ) async {
      await prefs.clear();
      await launch(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Lire les notes sans y penser'), findsOneWidget);
      final action = find.byKey(const ValueKey('onboarding-action'));

      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Où en es-tu ?'), findsOneWidget);
      // Rien de choisi : on ne passe pas.
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Où en es-tu ?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('start-readsBoth')));
      await tester.pump();
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.text('Combien de temps par jour ?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('goal-ten')));
      await tester.pump();
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('0 / 600 XP'), findsOneWidget);
      // « Je lis les deux clés » : la clé de fa est ouverte, et le parcours
      // propose de commencer après la grande portée.
      expect(find.textContaining('Se débloque'), findsWidgets);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      final course = container.read(courseProvider);
      expect(course.skill('note-reading.bass')!.state, SkillState.todo);
      expect(course.skill('note-reading.phrases')!.state, SkillState.todo);
      expect(
        course.resume!.lesson.skills,
        isNot(contains('note-reading.treble')),
      );

      // Relance : directement le Parcours.
      await launch(tester);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('retour du téléphone : l’écran d’avant', (tester) async {
      await prefs.clear();
      await launch(tester);
      await tester.tap(find.byKey(const ValueKey('onboarding-action')));
      await tester.pumpAndSettle();
      expect(find.text('Où en es-tu ?'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Lire les notes sans y penser'), findsOneWidget);
    });
  });

  group('réglages', () {
    /// Ouvre les réglages depuis l'onglet Profil.
    Future<void> openSettings(WidgetTester tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Nobémol',
        packageName: 'fr.antoninpamart.nobemol',
        version: '1.0.0',
        buildNumber: '2',
        buildSignature: '',
      );
      await launch(tester);
      await tester.tap(find.byKey(const ValueKey('tab-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    }

    Future<void> tapSetting(WidgetTester tester, String key) async {
      final finder = find.byKey(ValueKey(key)).hitTestable();
      if (finder.evaluate().isEmpty) {
        await tester.dragUntilVisible(
          finder,
          find.byType(ListView).last,
          const Offset(0, -200),
        );
      }
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('gardés, et appliqués partout', (tester) async {
      await openSettings(tester);
      await tapSetting(tester, 'naming-letters');
      await tapSetting(tester, 'goal-twenty');
      await tapSetting(tester, 'theme-dark');
      await tapSetting(tester, 'haptics');
      expect(find.text('1.0.0 (2)'), findsOneWidget);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);

      // Relus au lancement suivant.
      final settings = SettingsStore(prefs).load();
      expect(settings.naming, NoteNaming.letters);
      expect(settings.goal, DailyGoal.twenty);
      expect(settings.theme, ThemeMode.dark);
      expect(settings.haptics, isFalse);
      await launch(tester);
      expect(find.text('0 / 1200 XP'), findsOneWidget);
    });

    testWidgets('point de départ : change le parcours, réversible', (
      tester,
    ) async {
      await openSettings(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      SkillState bass() =>
          container.read(courseProvider).skill('note-reading.bass')!.state;
      expect(bass(), SkillState.locked);
      await tapSetting(tester, 'start-knowsTreble');
      expect(bass(), SkillState.todo);
      await tapSetting(tester, 'start-beginner');
      expect(bass(), SkillState.locked);
    });

    testWidgets('licences des polices', (tester) async {
      await openSettings(tester);
      await tapSetting(tester, 'licenses');
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  group('noms C-D-E', () {
    setUp(() => prefs.setString('naming', NoteNaming.letters.name));

    testWidgets('touches, correction et explication', (tester) async {
      final container = await startSession(tester, 'Je débute');
      final params = StartLevel.beginner.params;
      for (final letter in ['C', 'D', 'E', 'F', 'G', 'A', 'B']) {
        expect(find.text(letter), findsOneWidget);
      }
      expect(find.text('do'), findsNothing);

      final question =
          container.read(sessionProvider(params)).question as NoteQuestion;
      final expected = question.answer;
      final given = NoteName.naturals[(expected.step.index + 1) % 7];
      await give(tester, given);
      await tester.pump(const Duration(seconds: 1));
      final letter = expected.step.name.toUpperCase();
      expect(find.text("C'est un $letter"), findsOneWidget);
      expect(
        find.text('Tu as répondu : ${given.step.name.toUpperCase()}.'),
        findsOneWidget,
      );
      expect(find.textContaining('est un $letter.'), findsOneWidget);
    });

    testWidgets('noms sous la portée de la théorie', (tester) async {
      await openLesson(tester, 'treble-clef');
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      final view = tester.widget<NotationView>(find.byType(NotationView));
      expect(view.labels.values, ['F', 'G', 'A']);
    });
  });

  testWidgets('noms sous les touches désactivés : touches muettes', (
    tester,
  ) async {
    await prefs.setBool('keyLabels', false);
    await startSession(tester, 'Je débute');
    expect(find.text('do'), findsNothing);
    expect(find.bySemanticsLabel('do'), findsOneWidget);
  });

  group('vibrations', () {
    late List<MethodCall> calls;

    Future<void> play(WidgetTester tester) async {
      calls = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final container = await startSession(tester, 'Je débute');
      await answer(tester, container, StartLevel.beginner, right: true);
      await answer(tester, container, StartLevel.beginner, right: false);
    }

    testWidgets('courte si c’est juste, longue si c’est faux', (tester) async {
      await play(tester);
      expect(calls.map((call) => call.arguments), [
        'HapticFeedbackType.lightImpact',
        null,
      ]);
    });

    testWidgets('désactivées dans les réglages : aucune', (tester) async {
      await prefs.setBool('haptics', false);
      await play(tester);
      expect(calls, isEmpty);
    });
  });
}
