import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/achievements/achievement.dart';
import 'package:nobemol/lessons/content.dart';

/// Contenu pédagogique, chargé une fois au démarrage (voir main.dart).
final contentProvider = Provider<Content>(
  (ref) => throw UnimplementedError('contentProvider : à surcharger'),
);

/// Charge l'arbre de compétences, toutes les leçons embarquées et les
/// succès.
///
/// Le validateur (tool/validate_content.dart) a déjà vérifié ce contenu en
/// CI : une erreur ici est un bug, pas un cas à gérer.
Future<Content> loadContent(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final paths = manifest.listAssets().where(
    (path) => path.startsWith(lessonsDir) && path.endsWith('.yaml'),
  );
  return parseContent(
    skills: await bundle.loadString(skillsPath),
    lessons: {for (final path in paths) path: await bundle.loadString(path)},
    achievements: await bundle.loadString(achievementsPath),
  );
}
