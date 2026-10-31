import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/achievements/achievements_screen.dart';
import 'package:nobemol/backup/backup_actions.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/profile/stats.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/level_header.dart';
import 'package:nobemol/update/update_tile.dart';

/// Onglet Profil : niveau, chiffres clés, puis statistiques, succès,
/// sauvegarde et réglages.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final progress = ref.watch(progressProvider);
    final figures = ProfileFigures(progress);
    final achievements = ref.watch(achievementsProvider);
    final accuracy = figures.accuracy;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.m),
      child: Text(
        title.toUpperCase(),
        style: AppText.meta.copyWith(color: c.inkMuted),
      ),
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
          const UpdateTile(),
          section(l10n.profileFigures),
          Row(
            children: [
              _Figure(
                key: const ValueKey('figure-lessons'),
                value: '${figures.lessons}',
                label: l10n.profileLessons,
              ),
              const SizedBox(width: Space.sm),
              _Figure(
                key: const ValueKey('figure-combo'),
                value: '×${figures.bestCombo}',
                label: l10n.profileBestCombo,
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              _Figure(
                key: const ValueKey('figure-chrono'),
                value: switch (figures.chronoRecord) {
                  final record? => '$record',
                  null => '–',
                },
                label: l10n.profileChronoRecord,
              ),
              const SizedBox(width: Space.sm),
              _Figure(
                key: const ValueKey('figure-accuracy'),
                value: accuracy.answers == 0
                    ? '–'
                    : '${(accuracy.ratio * 100).round()} %',
                label: l10n.profileAccuracy,
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          _Link(
            key: const ValueKey('open-stats'),
            title: l10n.statsTitle,
            subtitle: l10n.profileStatsHint,
            onTap: () => context.push('/profil/statistiques'),
          ),
          const SizedBox(height: Space.sm),
          _Link(
            key: const ValueKey('open-achievements'),
            title: l10n.achievementsTitle,
            subtitle: l10n.achievementsCount(
              achievements.unlocked,
              achievements.all.length,
            ),
            onTap: () => context.push('/profil/succes'),
          ),
          section(l10n.profileBackup),
          Text(
            l10n.profileBackupHint,
            style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
          ),
          const SizedBox(height: Space.m),
          _Link(
            key: const ValueKey('backup-export'),
            title: l10n.backupExport,
            subtitle: l10n.backupExportHint,
            icon: Icons.ios_share_rounded,
            onTap: () => unawaited(exportBackup(ref)),
          ),
          const SizedBox(height: Space.sm),
          _Link(
            key: const ValueKey('backup-import'),
            title: l10n.backupImport,
            subtitle: l10n.backupImportHint,
            icon: Icons.file_open_outlined,
            onTap: () => unawaited(importBackup(context, ref)),
          ),
          const SizedBox(height: Space.xl),
          _Link(
            key: const ValueKey('open-settings'),
            title: l10n.settingsTitle,
            onTap: () => context.push('/reglages'),
          ),
        ],
      ),
    );
  }
}

/// Un chiffre clé et ce qu'il compte.
class _Figure extends StatelessWidget {
  const _Figure({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: AppTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppText.titleScreen.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile qui ouvre un écran ou lance une action.
class _Link extends StatelessWidget {
  const _Link({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.chevron_right_rounded,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppTile(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleCard.copyWith(fontSize: 15)),
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
          Icon(icon, color: c.inkMuted),
        ],
      ),
    );
  }
}
