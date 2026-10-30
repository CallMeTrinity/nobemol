import 'package:flutter/material.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/fit_words.dart';

/// Les 4 points de départ, au démarrage et dans les réglages.
class StartLevelChoices extends StatelessWidget {
  const StartLevelChoices({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  /// `null` tant que rien n'est choisi.
  final StartLevel? selected;
  final ValueChanged<StartLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final level in StartLevel.values)
          ChoiceTile(
            key: ValueKey('start-${level.name}'),
            title: l10n.levelTitle(level),
            subtitle: l10n.levelDescription(level),
            selected: level == selected,
            onTap: () => onSelect(level),
          ),
      ],
    );
  }
}

/// Les 4 objectifs du jour : la durée, son nom et ses XP.
class DailyGoalChoices extends StatelessWidget {
  const DailyGoalChoices({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  /// `null` tant que rien n'est choisi.
  final DailyGoal? selected;
  final ValueChanged<DailyGoal> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final goal in DailyGoal.values)
          ChoiceTile(
            key: ValueKey('goal-${goal.name}'),
            meta: l10n.goalMinutes(goal.minutes),
            title: l10n.goalTitle(goal),
            subtitle: l10n.goalXp(goal.xp),
            selected: goal == selected,
            onTap: () => onSelect(goal),
          ),
      ],
    );
  }
}

/// Tuile d'un choix parmi plusieurs : bordée d'accent et cochée une fois
/// choisie.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.meta,
  });

  final String title;
  final String? subtitle;

  /// À gauche du titre, en chiffres (« 5 min »).
  final String? meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Semantics(
        selected: selected,
        child: AppTile(
          highlighted: selected,
          onTap: onTap,
          child: Row(
            children: [
              if (meta case final meta?) ...[
                SizedBox(
                  width: 64,
                  child: Text(
                    meta.toUpperCase(),
                    style: AppText.metaLarge.copyWith(color: c.accentDeep),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitWordsText(
                      title,
                      style: AppText.titleCard.copyWith(fontSize: 15),
                    ),
                    if (subtitle case final subtitle?) ...[
                      const SizedBox(height: Space.xxs),
                      Text(
                        subtitle,
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          color: c.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Space.s),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? c.accent : c.keyBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
