import 'dart:math';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/skill_tree.dart';
import 'package:nobemol/reading/note_reading.dart';

/// Bonnes réponses qui valident une compétence.
const placementPass = 2;

/// Mauvaises réponses qui l'écartent. Deux sur trois décident : une
/// touche ratée ne coûte pas toute une branche, et un hasard heureux ne
/// suffit pas.
const placementFail = 2;

/// Une compétence du test, et l'exercice qui la mesure : celui de sa
/// première leçon.
class PlacementSkill {
  const PlacementSkill(this.skill, this.exercise);

  final Skill skill;
  final ReadingExercise exercise;
}

/// Les compétences du test, dans l'ordre de l'arbre : celles qui ont une
/// leçon de lecture (note, durée, signe, intervalle). L'oreille et le
/// rythme tapé s'écoutent et se jouent : pas en trois questions.
List<PlacementSkill> placementSkills(Content content) => [
  for (final skill in content.skills)
    if (content
            .masteryLessons(skill.id)
            .map((lesson) => lesson.exercise)
            .where(_readable)
            .firstOrNull
        case final exercise?)
      PlacementSkill(skill, exercise),
];

bool _readable(ReadingExercise exercise) => switch (exercise) {
  NoteReadingParams() ||
  IdentifyNoteExercise() ||
  IdentifyDurationExercise() ||
  IdentifyMarkingExercise() ||
  IdentifyIntervalExercise() => true,
  TapRhythmExercise() ||
  EarNoteParams() ||
  EarIntervalParams() ||
  ReviewExercise() => false,
};

/// Le test de positionnement : il suit l'arbre de compétences, et ne pose
/// une compétence que si ses prérequis sont réussis. Chacune se décide en
/// deux ou trois questions : [placementPass] justes la valident,
/// [placementFail] fausses l'écartent, avec tout ce qui la suit.
///
/// Un débutant sort après deux questions de clé de sol. Un lecteur
/// confirmé répond deux fois par compétence.
class PlacementTest {
  PlacementTest(this.skills, this._random) {
    _advance();
  }

  final List<PlacementSkill> skills;
  final Random _random;

  /// Compétences réussies : le résultat.
  final passed = <String>{};

  var _index = -1;
  var _right = 0;
  var _wrong = 0;
  late QuestionSource _source;

  /// Question en cours, `null` à la fin.
  Question? question;

  /// Compétence en cours, `null` à la fin.
  PlacementSkill? get current => _index < skills.length ? skills[_index] : null;

  bool get finished => current == null;

  /// Part des compétences décidées : réussies, ratées, ou écartées par un
  /// prérequis raté.
  double get progress =>
      skills.isEmpty ? 1 : min(_index, skills.length) / skills.length;

  /// Réponses possibles de la question en cours.
  List<Enum> get choices => current!.exercise.choicesFor(question!);

  void answer({required bool right}) {
    if (finished) return;
    right ? _right++ : _wrong++;
    if (_right >= placementPass) {
      passed.add(current!.skill.id);
      _advance();
    } else if (_wrong >= placementFail) {
      _advance();
    } else {
      question = _source.next(previous: question);
    }
  }

  void _advance() {
    _right = 0;
    _wrong = 0;
    do {
      _index++;
    } while (_index < skills.length &&
        !skills[_index].skill.requires.every(passed.contains));
    final skill = current;
    if (skill == null) {
      question = null;
      return;
    }
    _source = _questionsOf(skill.exercise, _random);
    question = _source.next();
  }
}

QuestionSource _questionsOf(ReadingExercise exercise, Random random) =>
    switch (exercise) {
      NoteReadingParams() => _Telling(
        NoteGenerator(exercise, random),
        exercise,
      ),
      _ => _Shuffled(exercise, random),
    };

/// Notes tirées par les paramètres d'une leçon de lecture, mais seulement
/// celles qui la distinguent de ses prérequis : hors de la portée dès que
/// les lignes supplémentaires sont ouvertes, altérées dès que les
/// altérations le sont. Une note sur la portée ne dit rien des lignes
/// supplémentaires.
class _Telling implements QuestionSource {
  _Telling(this._generator, this._params);

  final NoteGenerator _generator;
  final NoteReadingParams _params;

  @override
  NoteQuestion next({Question? previous}) {
    while (true) {
      final question = _generator.next(previous: previous);
      if (_tells(question)) return question;
    }
  }

  bool _tells(NoteQuestion question) {
    if (_params.accidentals && question.pitch.accidental == null) return false;
    if (_params.ledgerLines == 0) return true;
    final clef = question.system.staves.elementAt(question.target.staff).clef;
    final position = clef.staffPosition(question.pitch);
    // De -1 à 9 : sur la portée, ou juste au-dessous, au-dessus.
    return position < -1 || position > 9;
  }
}

/// Les cibles d'une leçon écrite, dans le désordre : un test repris ne
/// pose pas les mêmes questions.
class _Shuffled implements QuestionSource {
  _Shuffled(ReadingExercise exercise, Random random) {
    final source = exercise.questions(random);
    Question? previous;
    for (var i = 0; i < exercise.length; i++) {
      previous = source.next(previous: previous);
      _questions.add(previous);
    }
    _questions.shuffle(random);
  }

  final _questions = <Question>[];
  var _index = 0;

  @override
  Question next({Question? previous}) =>
      _questions[_index++ % _questions.length];
}
