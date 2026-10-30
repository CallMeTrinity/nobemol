import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/home/home_screen.dart';
import 'package:nobemol/home/skill_screen.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/lesson_screen.dart';
import 'package:nobemol/onboarding/onboarding_screen.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/settings/settings_screen.dart';
import 'package:nobemol/shell/app_shell.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

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
          _soon('/reviser', (l10n) => (l10n.tabReview, l10n.reviewSoon)),
          _soon('/arcade', (l10n) => (l10n.tabArcade, l10n.arcadeSoon)),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (context, state) {
                  final l10n = AppLocalizations.of(context);
                  // Le profil arrive à l'étape 12 ; les réglages sont là.
                  return ComingSoonScreen(
                    title: l10n.tabProfile,
                    description: l10n.profileSoon,
                    footer: AppTile(
                      key: const ValueKey('open-settings'),
                      onTap: () => context.push('/reglages'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.settingsTitle,
                              style: AppText.titleCard.copyWith(fontSize: 15),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.colors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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

/// Vrai si la compétence [id] existe et a au moins une leçon.
bool _hasLessons(Content content, String id) =>
    content.lessons.any((lesson) => lesson.skills.contains(id));

Lesson? _lesson(Content content, GoRouterState state) =>
    content.lesson(state.pathParameters['id']!);
