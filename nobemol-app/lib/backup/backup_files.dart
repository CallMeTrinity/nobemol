import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Le fichier de sauvegarde, hors de l'appli : partagé à l'export (Drive,
/// mail, Fichiers), choisi à l'import. Remplaçable en test.
abstract interface class BackupFiles {
  Future<void> share(String name, String contents);

  /// Contenu du fichier choisi, `null` si l'élève annule.
  Future<String?> pick();
}

/// Feuille de partage et sélecteur de fichiers du système.
class SystemBackupFiles implements BackupFiles {
  const SystemBackupFiles();

  @override
  Future<void> share(String name, String contents) => SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(utf8.encode(contents), mimeType: 'application/json'),
      ],
      // Le nom d'un XFile.fromData n'est gardé que sur le web.
      fileNameOverrides: [name],
    ),
  );

  @override
  Future<String?> pick() async {
    // N'importe quel fichier : Android ne connaît pas toujours le type
    // JSON d'un fichier venu du Drive. Le contenu est vérifié ensuite.
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}

final backupFilesProvider = Provider<BackupFiles>(
  (ref) => const SystemBackupFiles(),
);
