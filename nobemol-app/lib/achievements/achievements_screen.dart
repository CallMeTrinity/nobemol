import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/achievements/achievement.dart';
import 'package:nobemol/achievements/achievements.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Les succès, vus depuis la progression.
final achievementsProvider = Provider<AchievementList>(
  (ref) =>
      AchievementList(ref.watch(contentProvider), ref.watch(progressProvider)),
);

/// Les succès : débloqués avec leur date, les autres avec leur avancée.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final achievements = ref.watch(achievementsProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.l, Space.xl),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox.square(
              dimension: Sizes.minTarget,
              child: IconButton(
                key: const ValueKey('back'),
                tooltip: l10n.back,
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_rounded, color: c.ink),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.m, Space.m, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.achievementsTitle,
                  style: AppText.titleScreen.copyWith(color: c.ink),
                ),
                const SizedBox(height: Space.m),
                Text(
                  l10n
                      .achievementsCount(
                        achievements.unlocked,
                        achievements.all.length,
                      )
                      .toUpperCase(),
                  style: AppText.meta.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: Space.xl),
                for (final entry in achievements.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: _AchievementTile(entry: entry),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.entry});

  final AchievementProgress entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final achievement = entry.achievement;
    final unlocked = entry.unlocked;

    return Semantics(
      label: unlocked ? l10n.achievementUnlocked : null,
      child: AppTile(
        key: ValueKey('achievement-${achievement.id}'),
        highlighted: unlocked,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icon(achievement.kind),
              size: 28,
              color: unlocked ? c.accent : c.keyBorder,
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    achievement.title,
                    style: AppText.titleCard.copyWith(
                      fontSize: 15,
                      color: unlocked ? c.ink : c.inkMuted,
                    ),
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    achievement.description,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      color: c.inkMuted,
                    ),
                  ),
                  const SizedBox(height: Space.s),
                  if (unlocked)
                    Text(
                      switch (entry.unlockedAt) {
                        final at? => l10n.achievementUnlockedOn(
                          MaterialLocalizations.of(context)
                              .formatCompactDate(at.toLocal()),
                        ),
                        null => l10n.achievementUnlocked,
                      }.toUpperCase(),
                      style: AppText.meta.copyWith(color: c.success),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ProgressBar(
                            value: entry.current / entry.target,
                            height: 6,
                            color: c.accent,
                          ),
                        ),
                        const SizedBox(width: Space.s),
                        Text(
                          l10n.achievementProgress(entry.current, entry.target),
                          style: AppText.meta.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _icon(AchievementKind kind) => switch (kind) {
  AchievementKind.lessons => Icons.menu_book_rounded,
  AchievementKind.perfect => Icons.verified_rounded,
  AchievementKind.answers => Icons.check_circle_rounded,
  AchievementKind.combo => Icons.bolt_rounded,
  AchievementKind.streak => Icons.local_fire_department_rounded,
  AchievementKind.level => Icons.trending_up_rounded,
  AchievementKind.mastered ||
  AchievementKind.branch => Icons.workspace_premium_rounded,
  AchievementKind.chrono => Icons.timer_rounded,
  AchievementKind.endless => Icons.all_inclusive_rounded,
  AchievementKind.survival => Icons.favorite_rounded,
  AchievementKind.acquired => Icons.style_rounded,
};
