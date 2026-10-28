import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/fit_words.dart';
import 'package:nobemol/ui/nobemol_icon.dart';

/// Onglet Parcours : choix manuel du point de départ, puis les leçons. Le
/// vrai parcours (niveau, reprise, maîtrise) arrive avec la progression.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final lessons = ref.watch(contentProvider).lessons;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.m),
      child: Text(title, style: AppText.titleCard.copyWith(color: c.ink)),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.l,
          Space.xl,
          Space.l,
          Space.xl,
        ),
        children: [
          Row(
            children: [
              const NobemolIcon(),
              const SizedBox(width: Space.m),
              Text(
                l10n.appTitle,
                style: AppText.titleScreen.copyWith(color: c.ink),
              ),
            ],
          ),
          section(l10n.homeQuestion),
          for (final level in StartLevel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: AppTile(
                onTap: () => context.go('/lecture/${level.name}'),
                child: _TileText(
                  title: l10n.levelTitle(level),
                  subtitle: l10n.levelDescription(level),
                ),
              ),
            ),
          section(l10n.homeLessons),
          for (var start = 0; start < lessons.length; start += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  Expanded(child: _LessonTile(lesson: lessons[start])),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: start + 1 < lessons.length
                        ? _LessonTile(lesson: lessons[start + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppTile(
      // Hauteur commune : deux tuiles côte à côte s'alignent.
      height: 112,
      onTap: () => context.go('/lecon/${lesson.id}'),
      child: _TileText(
        title: lesson.title,
        meta: l10n.lessonLevel(lesson.level).toUpperCase(),
      ),
    );
  }
}

class _TileText extends StatelessWidget {
  const _TileText({required this.title, this.subtitle, this.meta});

  final String title;
  final String? subtitle;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FitWordsText(title, style: AppText.titleCard.copyWith(fontSize: 15)),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: Space.xs),
          Text(
            subtitle,
            style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
          ),
        ],
        if (meta case final meta?) ...[
          const SizedBox(height: Space.s),
          Text(meta, style: AppText.meta.copyWith(color: c.inkMuted)),
        ],
      ],
    );
  }
}
