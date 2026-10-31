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
//
// Ces textes sont stockés : ne jamais changer leur format sans migration.

const _clefs = {
  'treble': Clef.treble,
  'bass': Clef.bass,
  'alto': Clef.alto,
  'tenor': Clef.tenor,
};

/// Carte de [question].
String cardOf(Question question) => switch (question) {
  NoteQuestion(:final system, :final target, :final pitch, :final answer) =>
    'note:${_clefName(system.staves.elementAt(target.staff).clef)}'
        ':${answer.name}${pitch.octave}',
  DurationQuestion(:final system, :final targets) =>
    'duration:${targets.map((ref) => _figure(system.event(ref)!)).join('+')}',
  MarkingQuestion(:final system, :final target) =>
    'marking:${_sign(signsOf(system.event(target)!).single)}',
};

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
    _ => null,
  };
}

NoteQuestion? _note(String clefName, String note) {
  final clef = _clefs[clefName];
  final match = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(note);
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
