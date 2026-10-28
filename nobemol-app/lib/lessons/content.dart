import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/skill_tree.dart';
import 'package:nobemol/lessons/yaml_fields.dart';

/// Arbre de compétences, relatif à la racine de l'appli.
const skillsPath = 'assets/skills.yaml';

/// Dossier des leçons, une par fichier `.yaml`.
const lessonsDir = 'assets/lessons/';

/// Contenu pédagogique : arbre de compétences et leçons.
class Content {
  const Content({required this.skills, required this.lessons});

  final List<Skill> skills;

  /// Leçons dans l'ordre de l'arbre de compétences (voir [parseContent]).
  final List<Lesson> lessons;

  Lesson? lesson(String id) =>
      lessons.where((lesson) => lesson.id == id).firstOrNull;
}

/// Toutes les erreurs du contenu, au format `fichier:ligne:colonne: message`.
class ContentErrors implements Exception {
  const ContentErrors(this.messages);

  final List<String> messages;

  @override
  String toString() => messages.join('\n');
}

/// Lit et vérifie tout le contenu. [lessons] associe le chemin de chaque
/// leçon à sa source YAML.
///
/// Les leçons sont triées par compétence la plus avancée dans l'arbre, puis
/// par niveau, puis par identifiant. Lève une [ContentErrors] qui liste
/// toutes les erreurs, pas seulement la première.
Content parseContent({
  required String skills,
  required Map<String, String> lessons,
}) {
  final errors = <String>[];
  String format(String file, ContentException e) => [
    file,
    if (e.line != null) e.line,
    if (e.column != null) e.column,
    ' ${e.message}',
  ].join(':');

  var tree = const <Skill>[];
  try {
    tree = parseSkills(skills);
  } on ContentException catch (e) {
    errors.add(format(skillsPath, e));
  }
  final skillIds = {for (final skill in tree) skill.id};

  final parsed = <Lesson>[];
  for (final MapEntry(key: path, value: source) in lessons.entries) {
    final fileId = path.split('/').last.replaceFirst(RegExp(r'\.yaml$'), '');
    try {
      parsed.add(parseLesson(source, fileId: fileId, skills: skillIds));
    } on ContentException catch (e) {
      errors.add(format(path, e));
    }
  }
  if (errors.isNotEmpty) throw ContentErrors(errors);

  final rank = {for (final (i, skill) in tree.indexed) skill.id: i};
  int depth(Lesson lesson) => lesson.skills
      .map((skill) => rank[skill]!)
      .reduce((a, b) => a > b ? a : b);
  parsed.sort(
    (a, b) => switch (depth(a).compareTo(depth(b))) {
      0 => switch (a.level.compareTo(b.level)) {
        0 => a.id.compareTo(b.id),
        final order => order,
      },
      final order => order,
    },
  );
  return Content(skills: tree, lessons: parsed);
}
