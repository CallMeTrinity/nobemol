import 'package:yaml/yaml.dart';

import 'package:nobemol/lessons/yaml_fields.dart';

/// Compétence de l'arbre (`assets/skills.yaml`).
class Skill {
  const Skill({
    required this.id,
    required this.title,
    this.requires = const [],
  });

  /// Identifiant pointé : `note-reading.treble`.
  final String id;
  final String title;

  /// Compétences à maîtriser avant celle-ci.
  final List<String> requires;
}

final _skillId = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*(\.[a-z0-9]+(-[a-z0-9]+)*)*$');

/// Lit l'arbre de compétences.
///
/// Un prérequis est toujours déclaré plus haut dans le fichier : l'ordre du
/// fichier est un ordre d'apprentissage possible, et aucun cycle n'est
/// possible.
List<Skill> parseSkills(String source) {
  final root = loadContent(source);
  if (root is! YamlList || root.nodes.isEmpty) {
    throw ContentException.at(root, 'liste de compétences attendue');
  }

  final skills = <Skill>[];
  for (final (index, node) in root.nodes.indexed) {
    final fields = YamlFields.read(
      node,
      path: '[${index + 1}]',
      required: {'id', 'title'},
      optional: {'requires'},
    );
    final id = fields.string('id');
    if (!_skillId.hasMatch(id)) {
      throw fields.error(
        fields.node('id')!,
        'id « $id » invalide : minuscules, chiffres, tirets et points',
      );
    }
    if (skills.any((skill) => skill.id == id)) {
      throw fields.error(fields.node('id')!, 'compétence « $id » en double');
    }

    final requires = fields.node('requires') == null
        ? const <String>[]
        : fields.strings('requires');
    for (final (i, required) in requires.indexed) {
      if (!skills.any((skill) => skill.id == required)) {
        throw fields.error(
          fields.list('requires').nodes[i],
          'prérequis « $required » inconnu : '
          'il doit être déclaré plus haut dans le fichier',
        );
      }
    }
    skills.add(
      Skill(id: id, title: fields.string('title'), requires: requires),
    );
  }
  return skills;
}
