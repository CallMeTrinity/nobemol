import 'dart:math';

import 'package:notation/core.dart';

/// Nombre de notes d'une session de lecture paramétrique.
const sessionLength = 20;

/// Exercice de lecture : des notes à nommer, une par une.
sealed class ReadingExercise {
  const ReadingExercise();

  /// Nombre de questions d'une session.
  int get length;

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
  LayoutOptions get layoutOptions => const LayoutOptions();

  @override
  QuestionSource questions(Random random) => _TargetQuestions(this);
}

/// Une question : une note à nommer.
class NoteQuestion {
  const NoteQuestion({required this.system, required this.pitch, this.target});

  /// Ce qui s'affiche.
  final System system;

  /// La note à trouver.
  final Pitch pitch;

  /// La note à colorer dans [system], `null` si elle y est seule.
  final EventRef? target;

  /// Bonne réponse : le nom de la note, altération ignorée.
  DiatonicStep get answer => pitch.step;
}

/// Fournit les questions d'une session, une par une.
abstract interface class QuestionSource {
  /// Question suivante. [previous] est la question d'avant.
  NoteQuestion next({NoteQuestion? previous});
}

/// Tire des questions au hasard selon des [NoteReadingParams].
class NoteGenerator implements QuestionSource {
  NoteGenerator(this.params, this.random);

  final NoteReadingParams params;
  final Random random;

  /// Tire une question, différente de [previous] pour que la note bouge.
  @override
  NoteQuestion next({NoteQuestion? previous}) {
    while (true) {
      final question = _draw();
      if (question.pitch != previous?.pitch) return question;
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
  NoteQuestion next({NoteQuestion? previous}) {
    final target = exercise.targets[_index++];
    final pitch = switch (exercise.system.event(target)!) {
      Note(:final pitch) => pitch,
    };
    return NoteQuestion(system: exercise.system, pitch: pitch, target: target);
  }
}
