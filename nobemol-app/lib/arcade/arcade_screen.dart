import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/arcade/arcade.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// L'arcade, vue depuis la progression.
final arcadeOptionsProvider = Provider<Arcade>(
  (ref) => Arcade(
    ref.watch(contentProvider),
    ref.watch(progressProvider),
    acquired: ref.watch(settingsProvider.select((s) => s.start.acquired)),
  ),
);

/// Onglet Arcade : la clé, puis les trois modes et leurs records.
class ArcadeScreen extends ConsumerStatefulWidget {
  const ArcadeScreen({super.key});

  @override
  ConsumerState<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends ConsumerState<ArcadeScreen> {
  /// Clé choisie, la première apprise par défaut.
  ArcadeClef? _clef;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final arcade = ref.watch(arcadeOptionsProvider);
    final clef = arcade.clefs.contains(_clef)
        ? _clef
        : arcade.clefs.firstOrNull;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 36, Space.l, Space.xl),
        children: [
          Text(
            l10n.tabArcade,
            style: AppText.titleScreen.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.m),
          Text(
            clef == null ? l10n.arcadeLocked : l10n.arcadeIntro,
            style: AppText.body.copyWith(color: c.inkMuted),
          ),
          if (clef != null) ...[
            const SizedBox(height: Space.xl),
            Text(
              l10n.arcadeClef.toUpperCase(),
              style: AppText.meta.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.s),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final option in arcade.clefs)
                  AppChip(
                    key: ValueKey('clef-${option.name}'),
                    label: l10n.arcadeClefName(option),
                    selected: option == clef,
                    onTap: () => setState(() => _clef = option),
                  ),
              ],
            ),
            const SizedBox(height: Space.xl),
            for (final mode in ArcadeMode.values)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _ModeTile(
                  mode: mode,
                  game: arcade.game(mode, clef),
                  record: arcade.record(mode, clef),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Un mode : sa règle, et son record dans la clé choisie.
class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.game,
    required this.record,
  });

  final ArcadeMode mode;

  /// `null` tant que le mode est verrouillé.
  final ArcadeGame? game;
  final int? record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final game = this.game;
    final record = this.record;

    return AppTile(
      key: ValueKey('mode-${mode.name}'),
      onTap: game == null
          ? null
          : () => context.push('/arcade/partie', extra: game),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.arcadeModeName(mode),
                  style: AppText.titleCard.copyWith(
                    fontSize: 15,
                    color: game == null ? c.inkMuted : c.ink,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  l10n.arcadeModeRule(mode),
                  style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
                ),
                const SizedBox(height: Space.s),
                Text(
                  (game == null
                          ? l10n.arcadeSurvivalLocked(survivalLevel)
                          : record == null
                          ? l10n.arcadeNoRecord
                          : l10n.arcadeRecord(l10n.arcadeScore(mode, record)))
                      .toUpperCase(),
                  style: AppText.meta.copyWith(
                    color: record == null ? c.inkMuted : c.accentDeep,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            game == null
                ? Icons.lock_outline_rounded
                : Icons.play_arrow_rounded,
            color: game == null ? c.inkMuted : c.accent,
          ),
        ],
      ),
    );
  }
}

/// Textes de l'arcade qui dépendent d'un mode ou d'une clé.
extension ArcadeLabels on AppLocalizations {
  String arcadeClefName(ArcadeClef clef) => switch (clef) {
    ArcadeClef.treble => arcadeClefTreble,
    ArcadeClef.bass => arcadeClefBass,
    ArcadeClef.grand => arcadeClefGrand,
  };

  String arcadeModeName(ArcadeMode mode) => switch (mode) {
    ArcadeMode.chrono => arcadeChrono,
    ArcadeMode.endless => arcadeEndless,
    ArcadeMode.survival => arcadeSurvival,
  };

  String arcadeModeRule(ArcadeMode mode) => switch (mode) {
    ArcadeMode.chrono => arcadeChronoRule,
    ArcadeMode.endless => arcadeEndlessRule,
    ArcadeMode.survival => arcadeSurvivalRule,
  };

  /// Points en chrono, notes ailleurs.
  String arcadeScore(ArcadeMode mode, int score) => switch (mode) {
    ArcadeMode.chrono => arcadePoints(score),
    _ => arcadeNotes(score),
  };
}
