import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/progress/course.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/fit_words.dart';
import 'package:nobemol/ui/level_header.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Onglet Parcours : niveau, objectif du jour, la leçon à reprendre, puis
/// les compétences par branche.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final progress = ref.watch(progressProvider);
    final course = ref.watch(courseProvider);

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
          LevelHeader(level: Level.of(progress.xp)),
          const SizedBox(height: Space.xl),
          _DailyGoal(
            xp: progress.xpOn(ref.watch(clockProvider)()),
            goal: ref.watch(settingsProvider.select((s) => s.goal.xp)),
          ),
          if (course.resume case final resume?) ...[
            const SizedBox(height: Space.m),
            _ResumeCard(resume: resume),
          ],
          for (final MapEntry(key: branch, value: skills)
              in course.branches.entries) ...[
            section(l10n.branchTitle(branch)),
            _Grid(
              children: [
                for (final skill in skills) _SkillTile(progress: skill),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyGoal extends StatelessWidget {
  const _DailyGoal({required this.xp, required this.goal});

  /// XP gagnés aujourd'hui, et l'objectif.
  final int xp;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final done = xp >= goal;
    return AppTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dailyGoal,
                  style: AppText.titleCard.copyWith(fontSize: 15),
                ),
              ),
              Text(
                (done ? l10n.dailyGoalDone : l10n.dailyGoalXp(xp, goal))
                    .toUpperCase(),
                style: AppText.meta.copyWith(
                  color: done ? c.success : c.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          ProgressBar(value: xp / goal),
        ],
      ),
    );
  }
}

/// La leçon à reprendre, ou la prochaine à commencer.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.resume});

  final Resume resume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final lesson = resume.lesson;
    final page = resume.page;
    return AppTile(
      key: const ValueKey('resume'),
      highlighted: true,
      onTap: () => context.push(
        page == null ? '/lecon/${lesson.id}/exercice' : '/lecon/${lesson.id}',
      ),
      child: Row(
        children: [
          Expanded(
            child: _TileText(
              meta: (resume.started ? l10n.resume : l10n.resumeStart)
                  .toUpperCase(),
              metaColor: c.accentDeep,
              title: lesson.title,
              subtitle: page == null
                  ? l10n.resumeExercise
                  : l10n.resumePage(page + 1, lesson.theory.length),
            ),
          ),
          const SizedBox(width: Space.s),
          Icon(Icons.arrow_forward_rounded, color: c.accent),
        ],
      ),
    );
  }
}

/// Tuile d'une compétence : son état, ou ce qui la débloque.
class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.progress});

  final SkillProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final skill = progress.skill;
    final percent = (progress.mastery * 100).round();
    final locked = progress.state == SkillState.locked;

    return AppTile(
      key: ValueKey('skill-${skill.id}'),
      // Hauteur commune : deux tuiles côte à côte s'alignent.
      height: 128,
      onTap: locked ? null : () => context.push('/competence/${skill.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FitWordsText(
            skill.title,
            style: AppText.titleCard.copyWith(
              fontSize: 15,
              color: locked ? c.inkMuted : c.ink,
            ),
          ),
          if (locked)
            Text(
              l10n.skillLocked(
                progress.missing
                    .map((skill) => '« ${skill.title} »')
                    .join(', '),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(
                fontSize: 12,
                height: 1.3,
                color: c.inkMuted,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  switch (progress.state) {
                    SkillState.mastered => l10n.skillMastered,
                    SkillState.started => l10n.skillStarted(percent),
                    _ => l10n.skillTodo,
                  }.toUpperCase(),
                  style: AppText.meta.copyWith(
                    color: progress.state == SkillState.mastered
                        ? c.success
                        : c.inkMuted,
                  ),
                ),
                const SizedBox(height: Space.s),
                ProgressBar(value: progress.mastery, height: 6),
              ],
            ),
        ],
      ),
    );
  }
}

/// Deux colonnes égales, remplies ligne par ligne.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: children[start]),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: start + 1 < children.length
                      ? children[start + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TileText extends StatelessWidget {
  const _TileText({
    required this.title,
    this.subtitle,
    this.meta,
    this.metaColor,
  });

  final String title;
  final String? subtitle;

  /// Au-dessus du titre, en capitales.
  final String? meta;
  final Color? metaColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta case final meta?) ...[
          Text(
            meta,
            style: AppText.meta.copyWith(color: metaColor ?? c.inkMuted),
          ),
          const SizedBox(height: Space.s),
        ],
        FitWordsText(title, style: AppText.titleCard.copyWith(fontSize: 15)),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: Space.xs),
          Text(
            subtitle,
            style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
          ),
        ],
      ],
    );
  }
}
