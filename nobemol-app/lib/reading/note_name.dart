import 'package:notation/core.dart';

/// Nom de note à donner au clavier : une touche blanche, ou une touche
/// noire et son orthographe. Un fa dièse n'est pas un sol bémol.
///
/// Seules les altérations qui tombent sur une touche noire existent : pas
/// de mi dièse ni de do bémol (touches blanches), pas de double dièse.
enum NoteName {
  c(DiatonicStep.c),
  cSharp(DiatonicStep.c, Accidental.sharp),
  dFlat(DiatonicStep.d, Accidental.flat),
  d(DiatonicStep.d),
  dSharp(DiatonicStep.d, Accidental.sharp),
  eFlat(DiatonicStep.e, Accidental.flat),
  e(DiatonicStep.e),
  f(DiatonicStep.f),
  fSharp(DiatonicStep.f, Accidental.sharp),
  gFlat(DiatonicStep.g, Accidental.flat),
  g(DiatonicStep.g),
  gSharp(DiatonicStep.g, Accidental.sharp),
  aFlat(DiatonicStep.a, Accidental.flat),
  a(DiatonicStep.a),
  aSharp(DiatonicStep.a, Accidental.sharp),
  bFlat(DiatonicStep.b, Accidental.flat),
  b(DiatonicStep.b);

  const NoteName(this.step, [this.accidental]);

  final DiatonicStep step;

  /// Dièse ou bémol, `null` pour une touche blanche.
  final Accidental? accidental;

  /// Les 7 touches blanches.
  static final naturals = [
    for (final name in values)
      if (name.accidental == null) name,
  ];

  /// Nom de [step] altéré par [accidental], `null` hors du clavier (mi
  /// dièse, double dièse). Un bécarre donne la touche blanche.
  static NoteName? of(DiatonicStep step, Accidental? accidental) {
    final key = accidental == Accidental.natural ? null : accidental;
    return values
        .where((name) => name.step == step && name.accidental == key)
        .firstOrNull;
  }

  /// Touche blanche qui précède la touche noire de ce nom : do pour do
  /// dièse comme pour ré bémol. `null` pour une touche blanche.
  DiatonicStep? get blackKey => switch (accidental) {
    Accidental.sharp => step,
    Accidental.flat => DiatonicStep.values[step.index - 1],
    _ => null,
  };
}

/// D'où vient l'altération qu'on entend sur une note.
enum AccidentalSource {
  /// Écrite devant la note.
  written,

  /// Écrite plus tôt dans la mesure, sur la même note.
  measure,

  /// Prolongée par une liaison depuis la mesure d'avant.
  tie,

  /// L'armure.
  key,
}

/// Altération de la note [ref] de [system] telle qu'on la lit : écrite,
/// sinon reprise plus tôt dans la mesure, sinon prolongée par une liaison,
/// sinon l'armure. `null` pour une note naturelle sans rien de tout cela.
({Accidental accidental, AccidentalSource source})? soundingAccidental(
  System system,
  EventRef ref,
) {
  final note = system.event(ref)! as Note;
  final pitch = note.pitch;
  if (pitch.accidental case final written?) {
    return (accidental: written, source: AccidentalSource.written);
  }

  // Une altération vaut jusqu'à la barre, pour la même note à la même
  // octave.
  final staff = system.staves.elementAt(ref.staff);
  final events = staff.measures[ref.measure].events;
  for (var i = ref.event - 1; i >= 0; i--) {
    if (events[i] case Note(pitch: final before)
        when before.step == pitch.step &&
            before.octave == pitch.octave &&
            before.accidental != null) {
      return (accidental: before.accidental!, source: AccidentalSource.measure);
    }
  }

  // Liée depuis la mesure d'avant : la note garde l'altération du début.
  final first = system.tieChain(ref).first;
  if (first.measure != ref.measure) {
    if (soundingAccidental(system, first)
        case (:final accidental, :final source)
        when source != AccidentalSource.key) {
      return (accidental: accidental, source: AccidentalSource.tie);
    }
  }

  if (staff.key.steps.contains(pitch.step)) {
    return (accidental: staff.key.accidental!, source: AccidentalSource.key);
  }
  return null;
}

/// Nom de la note [ref] de [system], altération comprise. `null` hors du
/// clavier (mi dièse).
NoteName? noteNameAt(System system, EventRef ref) {
  final note = system.event(ref)! as Note;
  return NoteName.of(
    note.pitch.step,
    soundingAccidental(system, ref)?.accidental,
  );
}

/// Vrai si une note de [system] porte une altération, écrite ou par
/// l'armure : le clavier ouvre alors ses touches noires.
bool hasAccidentals(System system) => system.staves.any(
  (staff) =>
      staff.key.fifths != 0 ||
      staff.notes.any((note) => note.pitch.accidental != null),
);
