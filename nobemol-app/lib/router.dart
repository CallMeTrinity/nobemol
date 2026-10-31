import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/achievements/achievements_screen.dart';
import 'package:nobemol/arcade/arcade.dart';
import 'package:nobemol/arcade/arcade_screen.dart';
import 'package:nobemol/arcade/game_screen.dart';
import 'package:nobemol/home/home_screen.dart';
import 'package:nobemol/home/skill_screen.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/lesson_screen.dart';
import 'package:nobemol/onboarding/onboarding_screen.dart';
import 'package:nobemol/profile/profile_screen.dart';
import 'package:nobemol/profile/stats_screen.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/review/review_screen.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/settings/settings_screen.dart';
import 'package:nobemol/shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final content = ref.watch(contentProvider);
  // Leçons et exercices passent au-dessus de la barre d'onglets.
  final root = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: root,
    // Premier lancement : le démarrage d'abord, et une seule fois.
    redirect: (context, state) {
      final onboarded = ref.read(settingsProvider).onboarded;
      final onboarding = state.matchedLocation == '/bienvenue';
      if (!onboarded && !onboarding) return '/bienvenue';
      if (onboarded && onboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/bienvenue',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/reglages',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // Dans l'onglet : la barre reste visible.
                  GoRoute(
                    path: 'competence/:id',
                    redirect: (context, state) =>
                        _hasLessons(content, state.pathParameters['id']!)
                        ? null
                        : '/',
                    builder: (context, state) =>
                        SkillScreen(skillId: state.pathParameters['id']!),
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
                        builder: (context, state) {
                          final lesson = _lesson(content, state)!;
                          return ReadingScreen(
                            exercise: lesson.exercise,
                            lessonId: lesson.id,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reviser',
                builder: (context, state) => const ReviewScreen(),
                routes: [
                  // La session vient de l'onglet (extra) : sans elle, après
                  // un redémarrage par exemple, retour à l'onglet.
                  GoRoute(
                    path: 'session',
                    parentNavigatorKey: root,
                    redirect: (context, state) =>
                        state.extra is ReviewExercise ? null : '/reviser',
                    builder: (context, state) =>
                        ReadingScreen(exercise: state.extra! as ReviewExercise),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/arcade',
                builder: (context, state) => const ArcadeScreen(),
                routes: [
                  // La partie vient de l'onglet (extra), comme la révision.
                  GoRoute(
                    path: 'partie',
                    parentNavigatorKey: root,
                    redirect: (context, state) =>
                        state.extra is ArcadeGame ? null : '/arcade',
                    builder: (context, state) =>
                        GameScreen(game: state.extra! as ArcadeGame),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // Dans l'onglet : la barre reste visible.
                  GoRoute(
                    path: 'statistiques',
                    builder: (context, state) => const StatsScreen(),
                  ),
                  GoRoute(
                    path: 'succes',
                    builder: (context, state) => const AchievementsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Vrai si la compétence [id] existe et a au moins une leçon.
bool _hasLessons(Content content, String id) =>
    content.lessons.any((lesson) => lesson.skills.contains(id));

Lesson? _lesson(Content content, GoRouterState state) =>
    content.lesson(state.pathParameters['id']!);
