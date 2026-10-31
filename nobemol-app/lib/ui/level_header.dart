import 'package:flutter/material.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/nobemol_icon.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Icône, niveau et XP vers le niveau suivant : en haut du Parcours et du
/// Profil.
class LevelHeader extends StatelessWidget {
  const LevelHeader({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Row(
      children: [
        const NobemolIcon(size: 48),
        const SizedBox(width: Space.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.courseLevel(level.number),
                style: AppText.titleScreen.copyWith(color: c.ink),
              ),
              const SizedBox(height: Space.s),
              ProgressBar(value: level.progress / level.span, color: c.accent),
              const SizedBox(height: Space.xs),
              Text(
                l10n.courseLevelXp(level.progress, level.span),
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
