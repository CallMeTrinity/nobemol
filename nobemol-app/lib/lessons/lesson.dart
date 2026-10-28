import 'package:notation/core.dart';
import 'package:yaml/yaml.dart';

import 'package:nobemol/lessons/yaml_fields.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_reading.dart';

/// Page de théorie : un texte, et de la musique si besoin.
class TheoryPage {
  const TheoryPage({required this.text, this.system, this.names = false});

  final String text;

  /// Musique lue depuis l'ABC, `null` sans musique.
  final System? system;

  /// Écrit le nom de chaque note sous la portée.
  final bool names;

  /// La première phrase, l'idée de la page, et la suite. La suite est vide
  /// si le texte n'a qu'une phrase.
  ({String title, String body}) get parts {
    final end = RegExp(r'[.!?…]\s+(?=\p{Lu})', unicode: true).firstMatch(text);
    if (end == null) return (title: text, body: '');
    return (
      title: text.substring(0, end.start + 1),
      body: text.substring(end.end),
    );
  }
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
  final ReadingExercise exercise;
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
    exercise: _exercise(fields.node('exercise')!, source),
  );
}

TheoryPage _theoryPage(YamlNode node, String path, String source) {
  final fields = YamlFields.read(
    node,
    path: path,
    required: {'text'},
    optional: {'abc', 'names'},
  );
  final system = fields.node('abc') == null ? null : _abc(fields, source);
  final names = fields.boolean('names', or: false);
  if (names && system == null) {
    throw fields.error(
      fields.node('names')!,
      '${fields.name('names')} : pas de musique (abc) sous laquelle écrire '
      'les noms',
    );
  }
  return TheoryPage(
    text: fields.string('text').trim(),
    system: system,
    names: names,
  );
}

/// Lit le champ `abc` de [fields] et situe ses erreurs dans le fichier YAML.
System _abc(YamlFields fields, String source) {
  final node = fields.node('abc')!;
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

/// Champs de chaque type d'exercice, `type` compris.
const _exerciseFields = {
  'note-reading': (
    required: {'type', 'staff'},
    optional: {'ledger-lines', 'accidentals'},
  ),
  'identify-note': (required: {'type', 'abc', 'targets'}, optional: <String>{}),
  'identify-duration': (
    required: {'type', 'abc', 'targets'},
    optional: <String>{},
  ),
  'identify-marking': (
    required: {'type', 'abc', 'targets', 'choices'},
    optional: <String>{},
  ),
};

ReadingExercise _exercise(YamlNode node, String source) {
  // Le type d'abord : il fixe les autres champs attendus.
  final type = YamlFields.read(
    node,
    path: 'exercise',
    required: {'type'},
    optional: {
      for (final fields in _exerciseFields.values) ...fields.required,
      for (final fields in _exerciseFields.values) ...fields.optional,
    },
  );
  final name = type.string('type');
  final expected = _exerciseFields[name];
  if (expected == null) {
    throw type.error(
      type.node('type')!,
      'exercise.type : « $name » inconnu '
      '(${_exerciseFields.keys.join(', ')})',
    );
  }

  final fields = YamlFields.read(
    node,
    path: 'exercise',
    required: expected.required,
    optional: expected.optional,
  );
  return switch (name) {
    'identify-note' => _identifyNote(fields, source),
    'identify-duration' => _identifyDuration(fields, source),
    'identify-marking' => _identifyMarking(fields, source),
    _ => _noteReading(fields),
  };
}

NoteReadingParams _noteReading(YamlFields fields) {
  final staffNode = fields.node('staff')!;
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

IdentifyNoteExercise _identifyNote(YamlFields fields, String source) {
  final system = _abc(fields, source);
  return IdentifyNoteExercise(
    system: system,
    targets: _targets(fields, system, (target, path) {
      if (system.event(target) is Rest) {
        return '$path : un silence n’a pas de nom de note';
      }
      return null;
    }),
  );
}

IdentifyDurationExercise _identifyDuration(YamlFields fields, String source) {
  final system = _abc(fields, source);
  // La noire vaut un temps : seulement en x/4.
  final time = system.staves.first.time;
  if (time == null || time.beatUnit != 4) {
    throw fields.error(
      fields.node('abc')!,
      'exercise.abc : chiffrage en x/4 attendu (M:4/4), '
      'les réponses comptent en noires',
    );
  }
  return IdentifyDurationExercise(
    system: system,
    targets: _targets(fields, system, (target, path) {
      final chain = system.tieChain(target);
      if (chain.first != target) {
        return '$path : note d’arrivée d’une liaison, '
            'viser la première note (mesure ${chain.first.measure + 1}, '
            'événement ${chain.first.event + 1})';
      }
      final beats = beatsOf(system, chain);
      if (Beats.of(beats) == null) {
        return '$path : $beats temps, pas de bouton pour cette durée '
            '(de ¼ à 4 temps)';
      }
      return null;
    }),
  );
}

IdentifyMarkingExercise _identifyMarking(YamlFields fields, String source) {
  final system = _abc(fields, source);
  final choices = _choices(fields);
  return IdentifyMarkingExercise(
    system: system,
    choices: choices,
    targets: _targets(fields, system, (target, path) {
      final signs = signsOf(system.event(target)!).toList();
      if (signs.isEmpty) return '$path : aucun signe sur cet événement';
      if (signs.length > 1) {
        return '$path : ${signs.length} signes sur cet événement, '
            'la question serait ambiguë';
      }
      final marking = markingOf(signs.single);
      if (marking == null) {
        final text = (signs.single as Annotation).text;
        return '$path : terme « $text » inconnu (${terms.keys.join(', ')})';
      }
      if (!choices.contains(marking)) {
        return '$path : réponse « ${marking.id} » absente de exercise.choices';
      }
      return null;
    }),
  );
}

/// Lit les réponses proposées : de 2 à 8 sens, rangés dans l'ordre de
/// [Marking] quel que soit l'ordre d'écriture.
List<Marking> _choices(YamlFields fields) {
  final nodes = fields.list('choices').nodes;
  final choices = <Marking>[];
  for (final (index, id) in fields.strings('choices').indexed) {
    final marking = Marking.byId(id);
    if (marking == null) {
      final ids = Marking.values.map((marking) => marking.id).join(', ');
      throw fields.error(
        nodes[index],
        '${fields.name('choices')} : « $id » inconnu ($ids)',
      );
    }
    choices.add(marking);
  }
  if (choices.length < 2 || choices.length > 8) {
    throw fields.error(
      fields.node('choices')!,
      '${fields.name('choices')} : de 2 à 8 réponses',
    );
  }
  return choices..sort((a, b) => a.index.compareTo(b.index));
}

/// Lit les cibles d'un exercice, sans doublon. [check] renvoie un message
/// d'erreur si une cible ne convient pas à l'exercice.
List<EventRef> _targets(
  YamlFields fields,
  System system,
  String? Function(EventRef target, String path) check,
) {
  final targets = <EventRef>[];
  for (final (index, node) in fields.list('targets').nodes.indexed) {
    final path = 'exercise.targets[${index + 1}]';
    final target = _target(node, path, system);
    if (targets.contains(target)) {
      throw fields.error(node, '$path : en double');
    }
    if (check(target, path) case final message?) {
      throw fields.error(node, message);
    }
    targets.add(target);
  }
  return targets;
}

/// Lit une cible `{ staff, measure, event }`, écrite en base 1 (« mesure 1,
/// 2e note ») et convertie ici en index du code, une fois pour toutes.
EventRef _target(YamlNode node, String path, System system) {
  final fields = YamlFields.read(
    node,
    path: path,
    required: {'measure', 'event'},
    optional: {'staff'},
  );
  final staves = system.staves.toList();
  final ids = staves.map((staff) => staff.id).nonNulls.join(', ');

  final int staffIndex;
  if (fields.node('staff') case final staffNode?) {
    final id = fields.string('staff');
    staffIndex = staves.indexWhere((staff) => staff.id == id);
    if (staffIndex < 0) {
      throw fields.error(
        staffNode,
        '${fields.name('staff')} : portée « $id » absente de l’ABC ($ids)',
      );
    }
  } else if (staves.length > 1) {
    throw fields.error(
      node,
      '$path : champ « staff » manquant, l’ABC a plusieurs portées ($ids)',
    );
  } else {
    staffIndex = 0;
  }

  final measures = staves[staffIndex].measures;
  if (measures.isEmpty) {
    throw fields.error(node, '$path : la portée est vide');
  }
  final measure = fields.integer('measure', min: 1, max: measures.length) - 1;
  final events = measures[measure].events;
  final event = fields.integer('event', min: 1, max: events.length) - 1;
  return EventRef(staff: staffIndex, measure: measure, event: event);
}
