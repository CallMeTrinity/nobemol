import 'package:notation/core.dart';
import 'package:yaml/yaml.dart';

import 'package:nobemol/lessons/yaml_fields.dart';
import 'package:nobemol/reading/note_reading.dart';

/// Page de théorie : un texte, et de la musique si besoin.
class TheoryPage {
  const TheoryPage({required this.text, this.system});

  final String text;

  /// Musique lue depuis l'ABC, `null` sans musique.
  final System? system;
}

/// Leçon : des pages de théorie, puis un exercice de lecture.
///
/// Format décrit dans `doc/lessons.md`.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.skills,
    required this.level,
    required this.theory,
    required this.exercise,
  });

  /// Identifiant, égal au nom du fichier sans `.yaml`.
  final String id;
  final String title;

  /// Compétences travaillées, définies dans `assets/skills.yaml`.
  final List<String> skills;

  /// Niveau, à partir de 1.
  final int level;
  final List<TheoryPage> theory;
  final NoteReadingParams exercise;
}

final _lessonId = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Lit une leçon. [fileId] est le nom du fichier sans `.yaml`, [skills] les
/// identifiants de l'arbre de compétences.
Lesson parseLesson(
  String source, {
  required String fileId,
  required Set<String> skills,
}) {
  final fields = YamlFields.read(
    loadContent(source),
    required: {'id', 'title', 'skills', 'level', 'theory', 'exercise'},
  );

  final id = fields.string('id');
  if (!_lessonId.hasMatch(id)) {
    throw fields.error(
      fields.node('id')!,
      'id « $id » invalide : minuscules, chiffres et tirets',
    );
  }
  if (id != fileId) {
    throw fields.error(
      fields.node('id')!,
      'id « $id » différent du nom du fichier « $fileId.yaml »',
    );
  }

  final lessonSkills = fields.strings('skills');
  for (final (index, skill) in lessonSkills.indexed) {
    if (!skills.contains(skill)) {
      throw fields.error(
        fields.list('skills').nodes[index],
        'compétence « $skill » absente de assets/skills.yaml',
      );
    }
  }

  return Lesson(
    id: id,
    title: fields.string('title'),
    skills: lessonSkills,
    level: fields.integer('level', min: 1, max: 10),
    theory: [
      for (final (index, node) in fields.list('theory').nodes.indexed)
        _theoryPage(node, 'theory[${index + 1}]', source),
    ],
    exercise: _exercise(fields.node('exercise')!),
  );
}

TheoryPage _theoryPage(YamlNode node, String path, String source) {
  final fields = YamlFields.read(
    node,
    path: path,
    required: {'text'},
    optional: {'abc'},
  );
  final abc = fields.node('abc');
  return TheoryPage(
    text: fields.string('text').trim(),
    system: abc == null ? null : _abc(fields, abc, source),
  );
}

/// Lit l'ABC de [node] et situe ses erreurs dans le fichier YAML.
System _abc(YamlFields fields, YamlNode node, String source) {
  final abc = fields.string('abc');
  try {
    return parseAbc(abc);
  } on AbcException catch (e) {
    final message = '${fields.name('abc')} : ${e.message}';
    // Bloc `|` : la ligne ABC n commence n lignes sous l'indicateur, après
    // l'indentation du bloc.
    if (node is YamlScalar && node.style == ScalarStyle.LITERAL) {
      final line = node.span.start.line + e.line;
      final text = source.split('\n')[line];
      final indent = text.length - text.trimLeft().length;
      throw ContentException(
        message,
        line: line + 1,
        column: indent + e.column,
      );
    }
    throw ContentException.at(node, '$message (ligne ${e.line} de l’ABC)');
  }
}

NoteReadingParams _exercise(YamlNode node) {
  final fields = YamlFields.read(
    node,
    path: 'exercise',
    required: {'type'},
    optional: {'staff', 'ledger-lines', 'accidentals'},
  );
  final type = fields.string('type');
  if (type != 'note-reading') {
    throw fields.error(
      fields.node('type')!,
      'exercise.type : « $type » inconnu (note-reading)',
    );
  }

  final staffNode = fields.node('staff');
  if (staffNode == null) {
    throw fields.error(node, 'exercise : champ « staff » manquant');
  }
  final staffName = fields.string('staff');
  final staff = StaffSetup.values.asNameMap()[staffName];
  if (staff == null) {
    final names = StaffSetup.values.map((s) => s.name).join(', ');
    throw fields.error(
      staffNode,
      'exercise.staff : « $staffName » inconnu ($names)',
    );
  }

  return NoteReadingParams(
    staff: staff,
    ledgerLines: fields.integer('ledger-lines', min: 0, max: 4, or: 0),
    accidentals: fields.boolean('accidentals', or: false),
  );
}
