import 'package:yaml/yaml.dart';

import 'package:nobemol/lessons/yaml_fields.dart';

/// Succès, relatif à la racine de l'appli.
const achievementsPath = 'assets/achievements.yaml';

/// Ce qu'un succès compte. Le nom est la clé de `when` dans le YAML.
enum AchievementKind {
  /// Leçons différentes terminées.
  lessons,

  /// Sessions de leçon sans erreur.
  perfect,

  /// Bonnes réponses, partout.
  answers,

  /// Meilleur combo d'une session.
  combo,

  /// Plus longue série de jours de pratique.
  streak,

  /// Niveau atteint.
  level,

  /// Compétences maîtrisées.
  mastered,

  /// Toutes les compétences d'une branche maîtrisées.
  branch,

  /// Meilleur score d'un mode d'arcade, toutes clés : le nom du mode.
  chrono,
  endless,
  survival,

  /// Cartes de révision acquises (dernière boîte).
  acquired,
}

/// Succès de l'onglet Profil (`assets/achievements.yaml`).
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    this.target = 1,
    this.branch,
  });

  final String id;
  final String title;

  /// La condition, dite à l'élève : « Termine 10 leçons. »
  final String description;
  final AchievementKind kind;

  /// Nombre à atteindre. Pour une branche, il vient de l'arbre.
  final int target;

  /// Branche à maîtriser (`note-reading`), pour [AchievementKind.branch].
  final String? branch;
}

final _id = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Lit les succès. [branches] : branches de l'arbre qui ont des leçons, les
/// seules qu'un succès peut demander (une branche vide serait maîtrisée
/// d'office).
List<Achievement> parseAchievements(
  String source, {
  required Set<String> branches,
}) {
  final root = loadContent(source);
  if (root is! YamlList || root.nodes.isEmpty) {
    throw ContentException.at(root, 'liste de succès attendue');
  }

  final achievements = <Achievement>[];
  for (final (index, node) in root.nodes.indexed) {
    final fields = YamlFields.read(
      node,
      path: '[${index + 1}]',
      required: {'id', 'title', 'description', 'when'},
    );
    final id = fields.string('id');
    if (!_id.hasMatch(id)) {
      throw fields.error(
        fields.node('id')!,
        'id « $id » invalide : minuscules, chiffres et tirets',
      );
    }
    if (achievements.any((achievement) => achievement.id == id)) {
      throw fields.error(fields.node('id')!, 'succès « $id » en double');
    }

    final when = fields.node('when')!;
    if (when is! YamlMap || when.length != 1) {
      throw fields.error(when, 'when : une seule condition attendue');
    }
    final key = when.nodes.keys.single as YamlNode;
    final kind = AchievementKind.values.asNameMap()[key.value];
    if (kind == null) {
      throw fields.error(
        key,
        'condition « ${key.value} » inconnue (attendues : '
        '${AchievementKind.values.map((kind) => kind.name).join(', ')})',
      );
    }
    final condition = YamlFields.read(
      when,
      path: fields.name('when'),
      required: {kind.name},
    );
    final title = fields.string('title');
    final description = fields.string('description');
    if (kind == AchievementKind.branch) {
      final branch = condition.string(kind.name);
      if (!branches.contains(branch)) {
        throw fields.error(
          condition.node(kind.name)!,
          'branche « $branch » inconnue ou sans leçon '
          '(connues : ${branches.join(', ')})',
        );
      }
      achievements.add(
        Achievement(
          id: id,
          title: title,
          description: description,
          kind: kind,
          branch: branch,
        ),
      );
    } else {
      achievements.add(
        Achievement(
          id: id,
          title: title,
          description: description,
          kind: kind,
          target: condition.integer(kind.name, min: 1, max: 1000000),
        ),
      );
    }
  }
  return achievements;
}
