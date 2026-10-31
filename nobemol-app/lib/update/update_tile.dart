import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/update/update.dart';

/// Nouvelle version sortie : la tuile ouvre sa page dans le navigateur
/// (notes et APK). Rien tant que l'appli est à jour.
class UpdateTile extends ConsumerWidget {
  const UpdateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(updateProvider).value;
    if (release == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: AppTile(
        key: const ValueKey('update'),
        highlighted: true,
        onTap: () => unawaited(
          launchUrl(release.page, mode: LaunchMode.externalApplication),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.updateAvailable.toUpperCase(),
                    style: AppText.meta.copyWith(color: c.accentDeep),
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    l10n.updateVersion('${release.version}'),
                    style: AppText.titleCard.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    l10n.updateHint,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      color: c.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.s),
            Icon(Icons.open_in_new_rounded, color: c.accent),
          ],
        ),
      ),
    );
  }
}
