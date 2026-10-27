import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/home/home_screen.dart';
import 'package:nobemol/reading/reading_screen.dart';
import 'package:nobemol/reading/start_level.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'lecture/:level',
            redirect: (context, state) => _level(state) == null ? '/' : null,
            builder: (context, state) => ReadingScreen(level: _level(state)!),
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
