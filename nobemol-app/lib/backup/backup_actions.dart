import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/backup/backup.dart';
import 'package:nobemol/backup/backup_files.dart';
import 'package:nobemol/clock.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/ui/confirm_dialog.dart';

/// Exporte la progression et les réglages : la feuille de partage s'ouvre.
Future<void> exportBackup(WidgetRef ref) async {
  final backup = Backup(
    rows: await ref.read(progressProvider.notifier).rows(),
    settings: ref.read(settingsProvider),
    exportedAt: ref.read(clockProvider)(),
  );
  await ref.read(backupFilesProvider).share(backup.fileName, backup.encode());
}

/// Importe une sauvegarde choisie par l'élève : elle remplace la
/// progression et les réglages du téléphone, après confirmation s'il y a
/// déjà une progression. Vrai une fois importée.
Future<bool> importBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void say(String message) =>
      messenger.showSnackBar(SnackBar(content: Text(message)));

  final Backup backup;
  try {
    final source = await ref.read(backupFilesProvider).pick();
    if (source == null) return false;
    backup = Backup.decode(source, current: ref.read(settingsProvider));
  } on BackupException catch (e) {
    say(switch (e.error) {
      BackupError.invalid => l10n.backupInvalid,
      BackupError.tooNew => l10n.backupTooNew,
    });
    return false;
  } on Exception {
    // Fichier illisible : même message qu'un fichier abîmé.
    say(l10n.backupInvalid);
    return false;
  }

  final progress = ref.read(progressProvider);
  if (progress.sessions.isNotEmpty || progress.theory.isNotEmpty) {
    if (!context.mounted) return false;
    final replace = await confirmDialog(
      context,
      title: l10n.backupReplaceTitle,
      body: l10n.backupReplaceBody(
        MaterialLocalizations.of(context)
            .formatCompactDate(backup.exportedAt.toLocal()),
        backup.xp,
        progress.xp,
      ),
      stay: l10n.backupReplaceCancel,
      leave: l10n.backupReplaceConfirm,
      keyPrefix: 'restore',
    );
    if (!replace) return false;
  }

  try {
    await ref.read(progressProvider.notifier).restore(backup.rows);
  } on Exception {
    // Lignes refusées par la base (doublons) : rien n'a changé.
    say(l10n.backupInvalid);
    return false;
  }
  await ref.read(settingsProvider.notifier).update((_) => backup.settings);
  say(l10n.backupRestored(Level.of(backup.xp).number, backup.xp));
  return true;
}
