import 'dart:math';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/skill_tree.dart';
import 'package:nobemol/progress/progress.dart';

/// Maîtrise à partir de laquelle une compétence est acquise.
const masteryThreshold = 0.8;

enum SkillState {
  /// Un prérequis n'est pas maîtrisé.
  locked,

  /// Débloquée, aucune leçon commencée.
  todo,

  /// Une leçon commencée, maîtrise sous le seuil.
  started,

  /// Maîtrise au seuil ou au-dessus.
  mastered,
}

/// Une compétence de l'arbre, vue depuis la progression de l'élève.
class SkillProgress {
  const SkillProgress({
    required this.skill,
    required this.lessons,
    required this.mastery,
    required this.state,
    required this.missing,
  });

  final Skill skill;

  /// Leçons qui travaillent la compétence, dans l'ordre du parcours.
  final List<Lesson> lessons;

  /// Moyenne des meilleurs scores des leçons qui comptent pour la maîtrise
  /// (voir [Content.masteryLessons]), de 0 à 1. Une leçon jamais jouée
  /// compte 0.
  final double mastery;
  final SkillState state;

  /// Prérequis pas encore maîtrisés, dans l'ordre de l'arbre.
  final List<Skill> missing;
}

/// Où reprendre le parcours : une page de théorie, ou l'exercice.
class Resume {
  const Resume({required this.lesson, required this.page, this.started = true});

  final Lesson lesson;

  /// Page de théorie, `null` quand la théorie est lue : l'exercice.
  final int? page;

  /// Faux pour une leçon jamais ouverte : « Commencer ».
  final bool started;
}

/// Le parcours : maîtrise et déblocage de chaque compétence, et la leçon à
/// reprendre.
class Course {
  factory Course(Content content, Progress progress) {
    final bySkill = <String, SkillProgress>{};
    for (final skill in content.skills) {
      final lessons = [
        for (final lesson in content.lessons)
          if (lesson.skills.contains(skill.id)) lesson,
      ];
      final counted = content.masteryLessons(skill.id);
      final mastery = counted.isEmpty
          ? 0.0
          : counted
                    .map((lesson) => progress.bestScores[lesson.id] ?? 0)
                    .reduce((a, b) => a + b) /
                counted.length;
      // L'arbre déclare les prérequis plus haut : ils sont déjà calculés.
      final missing = [
        for (final id in skill.requires)
          if (bySkill[id]!.state != SkillState.mastered) bySkill[id]!.skill,
      ];
      final started = lessons.any(
        (lesson) =>
            progress.bestScores.containsKey(lesson.id) ||
            progress.theory.containsKey(lesson.id),
      );
      bySkill[skill.id] = SkillProgress(
        skill: skill,
        lessons: lessons,
        mastery: mastery,
        missing: missing,
        // Une compétence maîtrisée le reste, même si sa maîtrise ou un
        // prérequis a baissé depuis (nouvelle leçon ajoutée à l'arbre).
        state: progress.mastered.contains(skill.id) || reached(mastery, counted)
            ? SkillState.mastered
            : missing.isNotEmpty
            ? SkillState.locked
            : started
            ? SkillState.started
            : SkillState.todo,
      );
    }
    return Course._(content, progress, bySkill);
  }

  Course._(this._content, this._progress, this._bySkill);

  final Content _content;
  final Progress _progress;
  final Map<String, SkillProgress> _bySkill;

  SkillProgress? skill(String id) => _bySkill[id];

  /// Compétences au seuil de maîtrise, pas encore enregistrées comme
  /// maîtrisées.
  Iterable<String> get newlyMastered => [
    for (final skill in _bySkill.values)
      if (skill.state == SkillState.mastered &&
          !_progress.mastered.contains(skill.skill.id))
        skill.skill.id,
  ];

  /// Compétences qui ont au moins une leçon, rangées par branche
  /// (`note-reading`, `rhythm`...) dans l'ordre de l'arbre.
  late final Map<String, List<SkillProgress>> branches = () {
    final branches = <String, List<SkillProgress>>{};
    for (final skill in _bySkill.values) {
      if (skill.lessons.isEmpty) continue;
      branches.putIfAbsent(branchOf(skill.skill.id), () => []).add(skill);
    }
    return branches;
  }();

  /// Une leçon se joue quand toutes ses compétences sont débloquées.
  bool isUnlocked(Lesson lesson) =>
      lesson.skills.every((id) => _bySkill[id]!.state != SkillState.locked);

  /// La leçon commencée le plus récemment et jamais terminée. Sans elle, la
  /// première leçon débloquée jamais ouverte. `null` si tout est fait.
  late final Resume? resume = () {
    final played = _progress.bestScores;
    final open = [
      for (final MapEntry(key: id, value: theory) in _progress.theory.entries)
        if (_content.lesson(id) case final lesson?
            when !played.containsKey(id) && isUnlocked(lesson))
          (lesson, theory),
    ]..sort((a, b) => b.$2.updatedAt.compareTo(a.$2.updatedAt));
    if (open.firstOrNull case (final lesson, final theory)?) {
      return Resume(
        lesson: lesson,
        page: theory.read ? null : min(theory.page, lesson.theory.length - 1),
      );
    }
    for (final lesson in _content.lessons) {
      if (isUnlocked(lesson) &&
          !played.containsKey(lesson.id) &&
          !_progress.theory.containsKey(lesson.id)) {
        return Resume(lesson: lesson, page: 0, started: false);
      }
    }
    return null;
  }();
}

/// Vrai si [mastery] atteint le seuil, avec au moins une leçon qui compte.
/// Marge d'arrondi : (0,9 + 0,7) / 2 doit valoir 80 %.
bool reached(double mastery, List<Lesson> counted) =>
    counted.isNotEmpty && mastery >= masteryThreshold - 1e-9;

/// Branche d'une compétence : le début de son identifiant.
String branchOf(String skillId) => skillId.split('.').first;
