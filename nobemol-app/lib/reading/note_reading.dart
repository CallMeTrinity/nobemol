import 'dart:math';

import 'package:notation/core.dart';

import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';

/// Nombre de notes d'une session de lecture paramétrique.
const sessionLength = 20;

/// Exercice de lecture : des questions une par une, une réponse à choisir
/// parmi des boutons (nom de note, durée).
sealed class ReadingExercise {
  const ReadingExercise();

  /// Nombre de questions d'une session.
  int get length;

  /// Réponses possibles, une par bouton, dans l'ordre d'affichage.
  List<Enum> get choices;

  /// Réglages du layout, communs à toutes les questions.
  LayoutOptions get layoutOptions;

  /// Questions d'une nouvelle session.
  QuestionSource questions(Random random);
}

/// Portée(s) affichée(s) par un exercice de lecture.
enum StaffSetup { treble, bass, alto, tenor, grand }

/// Paramètres d'un exercice de lecture de notes. Un niveau n'est qu'un jeu
/// de paramètres.
class NoteReadingParams extends ReadingExercise {
  const NoteReadingParams({
    required this.staff,
    this.ledgerLines = 0,
    this.accidentals = false,
  });

  final StaffSetup staff;

  /// Nombre maximal de lignes supplémentaires, au-dessus comme au-dessous.
  /// Fixe la tessiture : on va jusqu'à la note qui pend sous (ou sur) la
  /// dernière ligne supplémentaire.
  final int ledgerLines;

  /// Ajoute des dièses et des bémols à une partie des notes.
  final bool accidentals;

  /// Plus basse position sur la portée (0 = ligne du bas).
  int get lowestPosition => -2 * ledgerLines - 1;

  /// Plus haute position sur la portée (8 = ligne du haut).
  int get highestPosition => 9 + 2 * ledgerLines;

  @override
  int get length => sessionLength;

  @override
  List<Enum> get choices => DiatonicStep.values;

  /// Réserve la place de la note la plus haute et la plus basse, altération
  /// comprise : la portée ne bouge pas d'une question à l'autre.
  @override
  LayoutOptions get layoutOptions => LayoutOptions(
    reserveAbove: ledgerLines + 2.5,
    reserveBelow: ledgerLines + 2.5,
  );

  @override
  QuestionSource questions(Random random) => NoteGenerator(this, random);

  // Clé de la session (sessionProvider) : comparée par valeur.
  @override
  bool operator ==(Object other) =>
      other is NoteReadingParams &&
      other.staff == staff &&
      other.ledgerLines == ledgerLines &&
      other.accidentals == accidentals;

  @override
  int get hashCode => Object.hash(staff, ledgerLines, accidentals);
}

/// Notes ciblées dans une phrase écrite en ABC, à nommer dans l'ordre.
///
/// Clé de la session comparée par identité : la leçon est chargée une fois.
class IdentifyNoteExercise extends ReadingExercise {
  const IdentifyNoteExercise({required this.system, required this.targets});

  /// La phrase, affichée telle quelle à chaque question.
  final System system;

  /// Notes à nommer, dans l'ordre. Chacune existe dans [system] : c'est
  /// vérifié au chargement de la leçon.
  final List<EventRef> targets;

  @override
  int get length => targets.length;

  @override
  List<Enum> get choices => DiatonicStep.values;

  @override
  LayoutOptions get layoutOptions => const LayoutOptions();

  @override
  QuestionSource questions(Random random) => _TargetQuestions(this);
}

/// Notes et silences ciblés dans une phrase écrite en ABC : donner leur
/// durée en temps, dans l'ordre. Une note liée compte toute sa liaison.
///
/// Clé de la session comparée par identité : la leçon est chargée une fois.
class IdentifyDurationExercise extends ReadingExercise {
  const IdentifyDurationExercise({required this.system, required this.targets});

  /// La phrase, en x/4 : la noire vaut un temps.
  final System system;

  /// Événements à mesurer, dans l'ordre. Vérifié au chargement de la leçon :
  /// chacun existe, commence sa liaison et dure un nombre de temps de
  /// [Beats].
  final List<EventRef> targets;

  @override
  int get length => targets.length;

  @override
  List<Enum> get choices => Beats.values;

  @override
  LayoutOptions get layoutOptions => const LayoutOptions();

  @override
  QuestionSource questions(Random random) => _DurationQuestions(this);
}

/// Signes ciblés dans une phrase écrite en ABC (nuance, soufflet,
/// articulation, terme) : donner leur sens, dans l'ordre.
///
/// Clé de la session comparée par identité : la leçon est chargée une fois.
class IdentifyMarkingExercise extends ReadingExercise {
  const IdentifyMarkingExercise({
    required this.system,
    required this.targets,
    required this.choices,
  });

  /// La phrase, affichée telle quelle à chaque question.
  final System system;

  /// Événements dont le signe est à reconnaître, dans l'ordre. Vérifié au
  /// chargement de la leçon : chacun porte un seul signe, dont le sens est
  /// dans [choices].
  final List<EventRef> targets;

  /// Réponses proposées, choisies par l'auteur de la leçon, dans l'ordre de
  /// [Marking].
  @override
  final List<Marking> choices;

  @override
  int get length => targets.length;

  @override
  LayoutOptions get layoutOptions => const LayoutOptions();

  @override
  QuestionSource questions(Random random) => _MarkingQuestions(this);
}

/// Une question : ce qui s'affiche, et la bonne réponse parmi les choix de
/// l'exercice.
sealed class Question {
  const Question({required this.system});

  /// Ce qui s'affiche.
  final System system;

  /// Événements à colorer dans [system], vide si rien n'est ciblé.
  List<EventRef> get targets;

  /// Événements dont les décorations sont à colorer, sans leur note.
  List<EventRef> get decorationTargets => const [];

  /// Bonne réponse.
  Enum get answer;
}

/// Une note à nommer.
class NoteQuestion extends Question {
  const NoteQuestion({required super.system, required this.pitch, this.target});

  /// La note à trouver.
  final Pitch pitch;

  /// La note à colorer dans [system], `null` si elle y est seule.
  final EventRef? target;

  @override
  List<EventRef> get targets => [?target];

  /// Le nom de la note, altération ignorée.
  @override
  DiatonicStep get answer => pitch.step;
}

/// Une durée à donner en temps.
class DurationQuestion extends Question {
  const DurationQuestion({
    required super.system,
    required this.targets,
    required this.answer,
  });

  /// La note ou le silence visé, et les notes qui lui sont liées.
  @override
  final List<EventRef> targets;

  @override
  final Beats answer;
}

/// Un signe à reconnaître.
class MarkingQuestion extends Question {
  const MarkingQuestion({
    required super.system,
    required this.target,
    required this.answer,
  });

  /// L'événement qui porte le signe.
  final EventRef target;

  /// Seul le signe est coloré, pas sa note.
  @override
  List<EventRef> get targets => const [];

  @override
  List<EventRef> get decorationTargets => [target];

  @override
  final Marking answer;
}

/// Fournit les questions d'une session, une par une.
abstract interface class QuestionSource {
  /// Question suivante. [previous] est la question d'avant.
  Question next({Question? previous});
}

/// Tire des questions au hasard selon des [NoteReadingParams].
class NoteGenerator implements QuestionSource {
  NoteGenerator(this.params, this.random);

  final NoteReadingParams params;
  final Random random;

  /// Tire une question, différente de [previous] pour que la note bouge.
  @override
  NoteQuestion next({Question? previous}) {
    final last = previous is NoteQuestion ? previous.pitch : null;
    while (true) {
      final question = _draw();
      if (question.pitch != last) return question;
    }
  }

  NoteQuestion _draw() {
    final clef = switch (params.staff) {
      StaffSetup.treble => Clef.treble,
      StaffSetup.bass => Clef.bass,
      StaffSetup.alto => Clef.alto,
      StaffSetup.tenor => Clef.tenor,
      StaffSetup.grand => random.nextBool() ? Clef.treble : Clef.bass,
    };
    final low = params.lowestPosition;
    final position = low + random.nextInt(params.highestPosition - low + 1);
    final natural = clef.pitchAt(position);
    final pitch = Pitch(
      natural.step,
      natural.octave,
      accidental: _accidental(),
    );
    final measures = [
      Measure([Note(pitch)]),
    ];

    final system = params.staff == StaffSetup.grand
        ? System([
            clef == Clef.treble
                ? StaffGroup.grand(upper: measures)
                : StaffGroup.grand(lower: measures),
          ])
        : System.single(Staff(clef: clef, measures: measures));
    return NoteQuestion(system: system, pitch: pitch);
  }

  /// Une note sur trois porte un dièse ou un bémol.
  Accidental? _accidental() {
    if (!params.accidentals || random.nextInt(3) != 0) return null;
    return random.nextBool() ? Accidental.sharp : Accidental.flat;
  }
}

/// Les cibles d'un [IdentifyNoteExercise], dans l'ordre.
class _TargetQuestions implements QuestionSource {
  _TargetQuestions(this.exercise);

  final IdentifyNoteExercise exercise;
  var _index = 0;

  @override
  NoteQuestion next({Question? previous}) {
    final target = exercise.targets[_index++];
    // Le chargement de la leçon a vérifié que chaque cible est une note.
    final note = exercise.system.event(target)! as Note;
    return NoteQuestion(
      system: exercise.system,
      pitch: note.pitch,
      target: target,
    );
  }
}

/// Les cibles d'un [IdentifyDurationExercise], dans l'ordre.
class _DurationQuestions implements QuestionSource {
  _DurationQuestions(this.exercise);

  final IdentifyDurationExercise exercise;
  var _index = 0;

  @override
  DurationQuestion next({Question? previous}) {
    final system = exercise.system;
    final targets = system.tieChain(exercise.targets[_index++]);
    return DurationQuestion(
      system: system,
      targets: targets,
      answer: Beats.of(beatsOf(system, targets))!,
    );
  }
}

/// Les cibles d'un [IdentifyMarkingExercise], dans l'ordre.
class _MarkingQuestions implements QuestionSource {
  _MarkingQuestions(this.exercise);

  final IdentifyMarkingExercise exercise;
  var _index = 0;

  @override
  MarkingQuestion next({Question? previous}) {
    final system = exercise.system;
    final target = exercise.targets[_index++];
    // Le chargement de la leçon a vérifié le signe et son sens.
    final sign = signsOf(system.event(target)!).single;
    return MarkingQuestion(
      system: system,
      target: target,
      answer: markingOf(sign)!,
    );
  }
}
