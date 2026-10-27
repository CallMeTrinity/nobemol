import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/reading/start_level.dart';

/// Choix manuel du point de départ, puis les leçons.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lessons = ref.watch(contentProvider).lessons;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 32),
            Text(l10n.appTitle, style: text.displaySmall),
            const SizedBox(height: 8),
            Text(l10n.homeQuestion, style: text.titleMedium),
            const SizedBox(height: 24),
            for (final level in StartLevel.values)
              Card(
                child: ListTile(
                  title: Text(l10n.levelTitle(level)),
                  subtitle: Text(l10n.levelDescription(level)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/lecture/${level.name}'),
                ),
              ),
            const SizedBox(height: 24),
            Text(l10n.homeLessons, style: text.titleMedium),
            const SizedBox(height: 8),
            for (final lesson in lessons)
              Card(
                child: ListTile(
                  title: Text(lesson.title),
                  subtitle: Text(l10n.lessonLevel(lesson.level)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/lecon/${lesson.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
