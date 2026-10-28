import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/home/home_screen.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/lesson_screen.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final content = ref.watch(contentProvider);
  // Leçons et exercices passent au-dessus de la barre d'onglets.
  final root = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: root,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'lecture/:level',
                    parentNavigatorKey: root,
                    redirect: (context, state) =>
                        _level(state) == null ? '/' : null,
                    builder: (context, state) =>
                        ReadingScreen(exercise: _level(state)!.params),
                  ),
                  GoRoute(
                    path: 'lecon/:id',
                    parentNavigatorKey: root,
                    redirect: (context, state) =>
                        _lesson(content, state) == null ? '/' : null,
                    builder: (context, state) =>
                        LessonScreen(lesson: _lesson(content, state)!),
                    routes: [
                      GoRoute(
                        path: 'exercice',
                        parentNavigatorKey: root,
                        builder: (context, state) => ReadingScreen(
                          exercise: _lesson(content, state)!.exercise,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          _soon('/reviser', (l10n) => (l10n.tabReview, l10n.reviewSoon)),
          _soon('/arcade', (l10n) => (l10n.tabArcade, l10n.arcadeSoon)),
          _soon('/profil', (l10n) => (l10n.tabProfile, l10n.profileSoon)),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Onglet pas encore construit.
StatefulShellBranch _soon(
  String path,
  (String, String) Function(AppLocalizations l10n) texts,
) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (context, state) {
        final (title, description) = texts(AppLocalizations.of(context));
        return ComingSoonScreen(title: title, description: description);
      },
    ),
  ],
);

StartLevel? _level(GoRouterState state) =>
    StartLevel.values.asNameMap()[state.pathParameters['level']];

Lesson? _lesson(Content content, GoRouterState state) =>
    content.lesson(state.pathParameters['id']!);
