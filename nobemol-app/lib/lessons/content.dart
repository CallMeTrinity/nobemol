import 'package:nobemol/achievements/achievement.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/skill_tree.dart';
import 'package:nobemol/lessons/yaml_fields.dart';

/// Arbre de compétences, relatif à la racine de l'appli.
const skillsPath = 'assets/skills.yaml';

/// Dossier des leçons, une par fichier `.yaml`.
const lessonsDir = 'assets/lessons/';

/// Contenu pédagogique : arbre de compétences, leçons et succès.
class Content {
  const Content({
    required this.skills,
    required this.lessons,
    this.achievements = const [],
  });

  final List<Skill> skills;

  /// Leçons dans l'ordre de l'arbre de compétences (voir [parseContent]).
  final List<Lesson> lessons;

  /// Succès, dans l'ordre du fichier.
  final List<Achievement> achievements;

  Lesson? lesson(String id) =>
      lessons.where((lesson) => lesson.id == id).firstOrNull;

  /// Leçons qui comptent pour la maîtrise de la compétence [skillId] :
  /// celles dont toutes les compétences sont [skillId] ou ses prérequis,
  /// directs ou non. Elles se jouent dès que la compétence est débloquée.
  ///
  /// Une leçon qui croise deux branches (grande portée et phrases) ne
  /// compte pour aucune des deux : sinon une compétence attendrait une
  /// leçon verrouillée par l'autre branche.
  List<Lesson> masteryLessons(String skillId) {
    final requires = {for (final skill in skills) skill.id: skill.requires};
    final allowed = <String>{};
    void add(String id) {
      if (allowed.add(id)) requires[id]?.forEach(add);
    }

    add(skillId);
    return [
      for (final lesson in lessons)
        if (lesson.skills.contains(skillId) &&
            lesson.skills.every(allowed.contains))
          lesson,
    ];
  }
}

/// Toutes les erreurs du contenu, au format `fichier:ligne:colonne: message`.
class ContentErrors implements Exception {
  const ContentErrors(this.messages);

  final List<String> messages;

  @override
  String toString() => messages.join('\n');
}

/// Lit et vérifie tout le contenu. [lessons] associe le chemin de chaque
/// leçon à sa source YAML. Sans [achievements], aucun succès.
///
/// Les leçons sont triées par compétence la plus avancée dans l'arbre, puis
/// par niveau, puis par identifiant. Lève une [ContentErrors] qui liste
/// toutes les erreurs, pas seulement la première.
Content parseContent({
  required String skills,
  required Map<String, String> lessons,
  String? achievements,
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

  // Un succès de branche ne vise qu'une branche qui a des leçons.
  final branches = {
    for (final skill in tree)
      if (parsed.any((lesson) => lesson.skills.contains(skill.id)))
        skill.id.split('.').first,
  };
  var achieved = const <Achievement>[];
  if (achievements != null) {
    try {
      achieved = parseAchievements(achievements, branches: branches);
    } on ContentException catch (e) {
      errors.add(format(achievementsPath, e));
    }
  }
  final content = Content(
    skills: tree,
    lessons: parsed,
    achievements: achieved,
  );

  // Une compétence avec des leçons se débloque quand ses prérequis sont
  // maîtrisés : chacun doit avoir une leçon qui compte pour sa maîtrise.
  for (final skill in tree) {
    if (!parsed.any((lesson) => lesson.skills.contains(skill.id))) continue;
    for (final required in skill.requires) {
      if (content.masteryLessons(required).isEmpty) {
        errors.add(
          '$skillsPath: « ${skill.id} » requiert « $required », qui n’a '
          'aucune leçon pour sa maîtrise : « ${skill.id} » resterait '
          'verrouillée',
        );
      }
    }
  }
  if (errors.isNotEmpty) throw ContentErrors(errors);
  return content;
}
