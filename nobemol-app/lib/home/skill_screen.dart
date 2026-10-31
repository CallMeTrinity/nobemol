import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/progress/course.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Une compétence : sa maîtrise, puis pour chacune de ses leçons la
/// théorie, l'exercice et l'arcade (verrouillée avant l'exercice).
class SkillScreen extends ConsumerWidget {
  const SkillScreen({super.key, required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final skill = ref.watch(courseProvider).skill(skillId)!;
    final progress = ref.watch(progressProvider);
    final locked = skill.state == SkillState.locked;
    final percent = (skill.mastery * 100).round();

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
                  skill.skill.title,
                  style: AppText.titlePrompt.copyWith(color: c.ink),
                ),
                const SizedBox(height: Space.ml),
                Text(
                  (locked
                          ? l10n.skillLocked(
                              skill.missing
                                  .map((skill) => '« ${skill.title} »')
                                  .join(', '),
                            )
                          : skill.state == SkillState.mastered
                          ? l10n.skillMastered
                          : l10n.skillMastery(percent))
                      .toUpperCase(),
                  style: AppText.meta.copyWith(
                    color: skill.state == SkillState.mastered
                        ? c.success
                        : c.inkMuted,
                  ),
                ),
                const SizedBox(height: Space.s),
                ProgressBar(value: skill.mastery),
                for (final lesson in skill.lessons) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Space.xl,
                      bottom: Space.m,
                    ),
                    child: Text(
                      lesson.title,
                      style: AppText.titleCard.copyWith(color: c.ink),
                    ),
                  ),
                  _LessonSteps(
                    lesson: lesson,
                    theory: progress.theory[lesson.id],
                    best: progress.bestScores[lesson.id],
                    locked: locked,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Théorie, exercice et arcade d'une leçon.
class _LessonSteps extends StatelessWidget {
  const _LessonSteps({
    required this.lesson,
    required this.theory,
    required this.best,
    required this.locked,
  });

  final Lesson lesson;
  final TheoryProgress? theory;

  /// Meilleur score de l'exercice, `null` s'il n'a jamais été joué.
  final double? best;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = lesson.theory.length;
    final theory = this.theory;
    final best = this.best;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Step(
          key: ValueKey('theory-${lesson.id}'),
          title: l10n.skillTheory,
          subtitle: switch (theory) {
            null => l10n.skillTheoryPages(pages),
            TheoryProgress(read: true) => l10n.skillTheoryRead,
            TheoryProgress(:final page) => l10n.skillTheoryProgress(
              page + 1,
              pages,
            ),
          },
          onTap: locked ? null : () => context.push('/lecon/${lesson.id}'),
        ),
        const SizedBox(height: Space.sm),
        _Step(
          key: ValueKey('exercise-${lesson.id}'),
          title: l10n.skillExercise,
          subtitle: best == null
              ? l10n.skillExerciseTodo
              : l10n.skillExerciseBest((best * 100).round()),
          onTap: locked
              ? null
              : () => context.push('/lecon/${lesson.id}/exercice'),
        ),
        const SizedBox(height: Space.sm),
        // L'arcade ne lit que des notes.
        if (branchOf(lesson.skills.first) == 'note-reading')
          _Step(
            key: ValueKey('arcade-${lesson.id}'),
            title: l10n.skillArcade,
            subtitle: best == null
                ? l10n.skillArcadeLocked
                : l10n.skillArcadeOpen,
            onTap: best == null ? null : () => context.go('/arcade'),
          ),
      ],
    );
  }
}

/// Une étape de la leçon : un titre, son état, et une flèche si elle
/// s'ouvre (un cadenas sinon).
class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return AppTile(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.titleCard.copyWith(
                    fontSize: 15,
                    color: enabled ? c.ink : c.inkMuted,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  subtitle,
                  style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
            color: enabled ? c.accent : c.inkMuted,
          ),
        ],
      ),
    );
  }
}
