import 'dart:math';

import 'package:notation/notation.dart';

/// Portée(s) affichée(s) par un exercice de lecture.
enum StaffSetup { treble, bass, alto, tenor, grand }

/// Paramètres d'un exercice de lecture de notes. Un niveau n'est qu'un jeu
/// de paramètres.
class NoteReadingParams {
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

  /// Réserve la place de la note la plus haute et la plus basse, altération
  /// comprise : la portée ne bouge pas d'une question à l'autre.
  LayoutOptions get layoutOptions => LayoutOptions(
    reserveAbove: ledgerLines + 2.5,
    reserveBelow: ledgerLines + 2.5,
  );
}

/// Une question : une note à nommer.
class NoteQuestion {
  const NoteQuestion({required this.system, required this.pitch});

  /// Ce qui s'affiche.
  final System system;

  /// La note à trouver.
  final Pitch pitch;

  /// Bonne réponse : le nom de la note, altération ignorée.
  DiatonicStep get answer => pitch.step;
}

/// Tire des questions au hasard selon des [NoteReadingParams].
class NoteGenerator {
  NoteGenerator(this.params, this.random);

  final NoteReadingParams params;
  final Random random;

  /// Tire une question, différente de [previous] pour que la note bouge.
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
    final notes = [Note(pitch)];

    final system = params.staff == StaffSetup.grand
        ? System([
            clef == Clef.treble
                ? StaffGroup.grand(upper: notes)
                : StaffGroup.grand(lower: notes),
          ])
        : System.single(Staff(clef: clef, notes: notes));
    return NoteQuestion(system: system, pitch: pitch);
  }

  /// Une note sur trois porte un dièse ou un bémol.
  Accidental? _accidental() {
    if (!params.accidentals || random.nextInt(3) != 0) return null;
    return random.nextBool() ? Accidental.sharp : Accidental.flat;
  }
}
