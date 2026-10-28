import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/home/home_screen.dart';
import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/lesson_screen.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/start_level.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final content = ref.watch(contentProvider);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'lecture/:level',
            redirect: (context, state) => _level(state) == null ? '/' : null,
            builder: (context, state) =>
                ReadingScreen(exercise: _level(state)!.params),
          ),
          GoRoute(
            path: 'lecon/:id',
            redirect: (context, state) =>
                _lesson(content, state) == null ? '/' : null,
            builder: (context, state) =>
                LessonScreen(lesson: _lesson(content, state)!),
            routes: [
              GoRoute(
                path: 'exercice',
                builder: (context, state) =>
                    ReadingScreen(exercise: _lesson(content, state)!.exercise),
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

StartLevel? _level(GoRouterState state) =>
    StartLevel.values.asNameMap()[state.pathParameters['level']];

Lesson? _lesson(Content content, GoRouterState state) =>
    content.lesson(state.pathParameters['id']!);
