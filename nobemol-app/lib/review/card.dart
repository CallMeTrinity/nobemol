import 'package:notation/core.dart';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';

// Carte de révision : ce qu'une question demande de lire, sans la phrase
// autour. Une note dans une clé, une durée écrite, un signe écrit. Gardée en
// base comme texte, sur chaque réponse (colonne `answers.card`) :
//
//   note:treble:fSharp5          nom au clavier (altération lue) et octave
//   duration:quarter.dotted      figures, `rest.` devant un silence,
//   duration:half+quarter        `+` entre deux notes liées
//   marking:dynamic:p            nuance, articulation, soufflet,
//   marking:above:rit.           terme au-dessus ou au-dessous
//   interval:melodic:treble:e4+c4  intervalle lu : deux notes dans
//   interval:harmonic:bass:g2+bFlat2  l'ordre de lecture, ou un accord
//   ear:interval:c4+g4           intervalle entendu, en montant
//   ear:chord:c4+e4              intervalle entendu, notes ensemble
//   ear:note:e4                  note entendue après le do4
//
// Les notes d'un intervalle portent l'altération lue, comme une carte de
// note.
//
// Ces textes sont stockés : ne jamais changer leur format sans migration.

const _clefs = {
  'treble': Clef.treble,
  'bass': Clef.bass,
  'alto': Clef.alto,
  'tenor': Clef.tenor,
};

/// Carte de [question], `null` pour une phrase tapée : elle ne se lit pas
/// sans la leçon, et un rythme raté ne se réduit pas à une figure.
String? cardOf(Question question) => switch (question) {
  NoteQuestion(:final system, :final target, :final pitch, :final answer) =>
    'note:${_clefName(system.staves.elementAt(target.staff).clef)}'
        ':${answer.name}${pitch.octave}',
  DurationQuestion(:final system, :final targets) =>
    'duration:${targets.map((ref) => _figure(system.event(ref)!)).join('+')}',
  MarkingQuestion(:final system, :final target) =>
    'marking:${_sign(signsOf(system.event(target)!).single)}',
  IntervalQuestion(heard: true, :final harmonic, :final pitches) =>
    'ear:${harmonic ? 'chord' : 'interval'}:${_notes(pitches)}',
  IntervalQuestion(
    :final system,
    :final targets,
    :final harmonic,
    :final pitches,
  ) =>
    'interval:${harmonic ? 'harmonic' : 'melodic'}'
        ':${_clefName(system.staves.elementAt(targets.first.staff).clef)}'
        ':${_notes(pitches)}',
  EarNoteQuestion(:final pitch) => 'ear:note:${_keyNote(pitch)}',
  TapQuestion() => null,
};

/// Note au clavier et octave : `fSharp5`. La hauteur porte l'altération
/// lue.
String _keyNote(Pitch pitch) =>
    '${NoteName.of(pitch.step, pitch.accidental)!.name}${pitch.octave}';

String _notes(List<Pitch> pitches) => pitches.map(_keyNote).join('+');

String _clefName(Clef clef) =>
    _clefs.entries.firstWhere((entry) => entry.value == clef).key;

String _figure(Event event) => [
  if (event is Rest) 'rest',
  event.value.name,
  if (event.dotted) 'dotted',
].join('.');

String _sign(Decoration sign) => switch (sign) {
  Dynamic() => 'dynamic:${sign.name}',
  Articulation() => 'articulation:${sign.name}',
  HairpinStart(:final hairpin) => 'hairpin:${hairpin.name}',
  Annotation(:final text, :final placement) => '${placement.name}:$text',
  // Jamais ciblée : la fin appartient au soufflet de sa première note.
  HairpinEnd() => throw ArgumentError.value(sign),
};

/// Question de [card], seule sur sa portée. `null` si la carte ne se lit
/// plus : format inconnu, durée ou signe sans réponse.
Question? questionOf(String card) {
  final [kind, ...rest] = card.split(':');
  return switch (kind) {
    'note' when rest.length == 2 => _note(rest[0], rest[1]),
    'duration' when rest.length == 1 => _duration(rest[0]),
    'marking' when rest.length >= 2 => _marking(
      rest[0],
      rest.skip(1).join(':'),
    ),
    'interval' when rest.length == 3 => _interval(rest[0], rest[1], rest[2]),
    'ear' when rest.length == 2 => _ear(rest[0], rest[1]),
    _ => null,
  };
}

/// Hauteur d'une note au clavier et son octave, `fSharp5`. `null` si le
/// texte ne se lit pas.
Pitch? _pitchOf(String note) {
  final match = _noteName.firstMatch(note);
  final name = NoteName.values.asNameMap()[match?[1]];
  if (name == null) return null;
  return Pitch(name.step, int.parse(match![2]!), accidental: name.accidental);
}

/// Les deux notes d'un intervalle, `c4+e4`.
(Pitch, Pitch)? _pair(String notes) {
  final pitches = notes.split('+').map(_pitchOf).toList();
  if (pitches case [final first?, final second?]) return (first, second);
  return null;
}

IntervalQuestion? _interval(String kind, String clefName, String notes) {
  final clef = _clefs[clefName];
  final pair = _pair(notes);
  if (clef == null || pair == null || !{'melodic', 'harmonic'}.contains(kind)) {
    return null;
  }
  return intervalQuestion(clef, pair.$1, pair.$2, harmonic: kind == 'harmonic');
}

/// Une question d'oreille s'affiche, à la correction, en clé de sol : ses
/// notes vont de do4 à do6.
Question? _ear(String kind, String notes) {
  if (kind == 'note') {
    final pitch = _pitchOf(notes);
    return pitch == null || pitch.accidental != null
        ? null
        : earNoteQuestion(pitch);
  }
  final pair = _pair(notes);
  if (pair == null || !{'interval', 'chord'}.contains(kind)) return null;
  return intervalQuestion(
    Clef.treble,
    pair.$1,
    pair.$2,
    harmonic: kind == 'chord',
    heard: true,
  );
}

/// Clé et nom d'une carte de note (statistiques), `null` pour une autre
/// carte ou une note qui ne se lit plus.
(Clef, NoteName)? noteOfCard(String card) {
  final parts = card.split(':');
  if (parts case ['note', final clefName, final note]) {
    final clef = _clefs[clefName];
    final name = NoteName.values.asNameMap()[_noteName.firstMatch(note)?[1]];
    if (clef != null && name != null) return (clef, name);
  }
  return null;
}

/// Nom au clavier et octave : `fSharp5`.
final _noteName = RegExp(r'^([a-zA-Z]+)(\d+)$');

NoteQuestion? _note(String clefName, String note) {
  final clef = _clefs[clefName];
  final match = _noteName.firstMatch(note);
  final name = NoteName.values.asNameMap()[match?[1]];
  if (clef == null || name == null) return null;
  // L'altération est écrite, même quand elle venait de l'armure.
  final pitch = Pitch(
    name.step,
    int.parse(match![2]!),
    accidental: name.accidental,
  );
  return NoteQuestion(
    system: System.single(
      Staff(
        clef: clef,
        measures: [
          Measure([Note(pitch)]),
        ],
      ),
    ),
    pitch: pitch,
    target: _first,
    answer: name,
  );
}

DurationQuestion? _duration(String figures) {
  final parts = figures.split('+');
  final events = <Event>[];
  for (final (index, figure) in parts.indexed) {
    final match = RegExp(r'^(rest\.)?([a-z]+)(\.dotted)?$').firstMatch(figure);
    final value = NoteValue.values.asNameMap()[match?[2]];
    if (value == null) return null;
    final dotted = match![3] != null;
    events.add(
      match[1] != null
          ? Rest(value: value, dotted: dotted)
          : Note(
              _middle,
              value: value,
              dotted: dotted,
              tiedToNext: index < parts.length - 1,
            ),
    );
  }
  final system = System.single(
    Staff(clef: Clef.treble, measures: [Measure(events)]),
  );
  final targets = system.tieChain(_first);
  if (targets.length != events.length) return null;
  final answer = Beats.of(beatsOf(system, targets));
  if (answer == null) return null;
  return DurationQuestion(system: system, targets: targets, answer: answer);
}

MarkingQuestion? _marking(String type, String value) {
  final Decoration? sign = switch (type) {
    'dynamic' => Dynamic.values.asNameMap()[value],
    'articulation' => Articulation.values.asNameMap()[value],
    'hairpin' => switch (Hairpin.values.asNameMap()[value]) {
      final hairpin? => HairpinStart(hairpin),
      null => null,
    },
    _ => switch (Placement.values.asNameMap()[type]) {
      final placement? => Annotation(value, placement: placement),
      null => null,
    },
  };
  final answer = sign == null ? null : markingOf(sign);
  if (answer == null) return null;
  // Un soufflet va de sa note à la troisième.
  final events = sign is HairpinStart
      ? [
          Note(_middle, value: NoteValue.quarter, decorations: [sign]),
          const Note(_middle, value: NoteValue.quarter),
          Note(
            _middle,
            value: NoteValue.quarter,
            decorations: [HairpinEnd(sign.hairpin)],
          ),
        ]
      : [
          Note(_middle, value: NoteValue.quarter, decorations: [sign!]),
        ];
  return MarkingQuestion(
    system: System.single(
      Staff(clef: Clef.treble, measures: [Measure(events)]),
    ),
    target: _first,
    answer: answer,
  );
}

/// Si, sur la ligne du milieu en clé de sol : la note des durées et des
/// signes.
const _middle = Pitch(DiatonicStep.b, 4);

const _first = EventRef(staff: 0, measure: 0, event: 0);

/// Réponses proposées pour [marking] : celles de la première leçon qui le
/// demande, choisies par son auteur. Vide si aucune leçon ne le demande.
List<Marking> markingChoices(Content content, Marking marking) =>
    content.lessons
        .map((lesson) => lesson.exercise)
        .whereType<IdentifyMarkingExercise>()
        .map((exercise) => exercise.choices)
        .where((choices) => choices.contains(marking))
        .firstOrNull ??
    const [];
