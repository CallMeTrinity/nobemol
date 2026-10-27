// Vérifie le contenu pédagogique : arbre de compétences, schéma des leçons,
// ABC (avec le parser du moteur), compétences citées.
//
// Depuis nobemol-app : dart run tool/validate_content.dart
//
// Lancé en CI : une leçon invalide fait échouer le build. Les erreurs sont au
// format fichier:ligne:colonne, cliquables dans un éditeur.
import 'dart:io';

import 'package:nobemol/lessons/content.dart';

void main() {
  // Racine de l'appli, quel que soit le dossier courant.
  final root = File.fromUri(Platform.script).parent.parent;
  String read(String path) => File('${root.path}/$path').readAsStringSync();

  final lessons = {
    for (final file in Directory(
      '${root.path}/$lessonsDir',
    ).listSync().whereType<File>())
      if (file.path.endsWith('.yaml'))
        '$lessonsDir${file.uri.pathSegments.last}': file.readAsStringSync(),
  };

  try {
    final content = parseContent(skills: read(skillsPath), lessons: lessons);
    stdout.writeln(
      '${content.lessons.length} leçons et '
      '${content.skills.length} compétences valides.',
    );
  } on ContentErrors catch (e) {
    for (final message in e.messages) {
      stderr.writeln(message);
    }
    stderr.writeln('${e.messages.length} erreur(s).');
    exitCode = 1;
  }
}
