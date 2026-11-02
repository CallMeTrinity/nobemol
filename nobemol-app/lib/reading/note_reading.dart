import 'dart:math';

import 'package:notation/core.dart';

import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/intervals.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/tapping.dart';

/// Nombre de notes d'une session de lecture paramétrique.
const sessionLength = 20;

/// Nombre de questions d'une session d'oreille : chacune s'écoute, parfois
/// deux fois.
const earSessionLength = 12;

/// La note de référence des exercices d'oreille : le do central.
const referencePitch = Pitch(DiatonicStep.c, 4);

/// Exercice de lecture : des questions une par une, une réponse à choisir
/// parmi des boutons (nom de note, durée).
sealed class ReadingExercise {
  const ReadingExercise();

  /// Nombre de questions d'une session.
  int get length;

  /// Réponses possibles de [question], une par bouton, dans l'ordre
  /// d'affichage.
  List<Enum> choicesFor(Question question);

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

  List<NoteName> get choices =>
      accidentals ? NoteName.values : NoteName.naturals;

  @override
  List<Enum> choicesFor(Question question) => choices;

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
  const IdentifyNoteExercise({
    required this.system,
    required this.targets,
    this.explanations = const {},
  });

  /// La phrase, affichée telle quelle à chaque question.
  final System system;

  /// Notes à nommer, dans l'ordre. Chacune existe dans [system] et a un nom
  /// au clavier : c'est vérifié au chargement de la leçon.
  final List<EventRef> targets;

  /// Explications écrites par l'auteur, par cible. Sans elle, l'appli en
  /// génère une.
  final Map<EventRef, String> explanations;

  @override
  int get length => targets.length;

  /// Touches noires ouvertes dès que la phrase a une altération.
  List<NoteName> get choices =>
      hasAccidentals(system) ? NoteName.values : NoteName.naturals;

  @override
  List<Enum> choicesFor(Question question) => choices;

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
  const IdentifyDurationExercise({
    required this.system,
    required this.targets,
    this.explanations = const {},
  });

  /// La phrase, en x/4 : la noire vaut un temps.
  final System system;

  /// Événements à mesurer, dans l'ordre. Vérifié au chargement de la leçon :
  /// chacun existe, commence sa liaison et dure un nombre de temps de
  /// [Beats].
  final List<EventRef> targets;

  /// Explications écrites par l'auteur, par cible.
  final Map<EventRef, String> explanations;

  @override
  int get length => targets.length;

  List<Beats> get choices => Beats.values;

  @override
  List<Enum> choicesFor(Question question) => choices;

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
    this.explanations = const {},
  });

  /// La phrase, affichée telle quelle à chaque question.
  final System system;

  /// Événements dont le signe est à reconnaître, dans l'ordre. Vérifié au
  /// chargement de la leçon : chacun porte un seul signe, dont le sens est
  /// dans [choices].
  final List<EventRef> targets;

  /// Explications écrites par l'auteur, par cible.
  final Map<EventRef, String> explanations;

  /// Réponses proposées, choisies par l'auteur de la leçon, dans l'ordre de
  /// [Marking].
  final List<Marking> choices;

  @override
  int get length => targets.length;

  @override
  List<Enum> choicesFor(Question question) => choices;

  @override
  LayoutOptions get layoutOptions => const LayoutOptions();

  @override
  QuestionSource questions(Random random) => _MarkingQuestions(this);
}

/// Un intervalle visé dans une phrase : un accord de deux notes (intervalle
/// harmonique), ou deux notes de la même portée, la seconde après la
/// première (intervalle mélodique).
class IntervalTarget {
  const IntervalTarget(this.from, [this.to]);

  /// L'accord, ou la première note.
  final EventRef from;

  /// La seconde note, `null` pour un accord.
  final EventRef? to;

  bool get harmonic => to == null;

  /// Événements à colorer.
  List<EventRef> get refs => [from, ?to];

  @override
  bool operator ==(Object other) =>
      other is IntervalTarget && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Notes de [target] dans [system] telles qu'on les lit (altérations
/// comprises), dans l'ordre de lecture : du grave à l'aigu pour un accord.
/// `null` si l'une n'a pas de touche (mi dièse).
List<Pitch>? intervalPitches(System system, IntervalTarget target) {
  final refs = switch (target.to) {
    null => [
      for (final pitch in system.event(target.from)!.pitches)
        (target.from, pitch),
    ],
    final to => [
      for (final ref in [target.from, to])
        (ref, system.event(ref)!.pitches.single),
    ],
  };
  final pitches = [
    for (final (ref, pitch) in refs) soundingPitch(system, ref, pitch),
  ];
  return pitches.contains(null) ? null : pitches.nonNulls.toList();
}

/// Intervalles ciblés dans une phrase écrite en ABC : donner leur numéro,
/// dans l'ordre.
///
/// Clé de la session comparée par identité : la leçon est chargée une fois.
class IdentifyIntervalExercise extends ReadingExercise {
  const IdentifyIntervalExercise({
    required this.system,
    required this.targets,
    this.explanations = const {},
  });

  final System system;

  /// Intervalles à nommer, dans l'ordre. Vérifié au chargement de la leçon :
  /// deux notes d'une touche, une octave au plus.
  final List<IntervalTarget> targets;

  /// Explications écrites par l'auteur, par première note de la cible.
  final Map<EventRef, String> explanations;

  @override
  int get length => targets.length;

  @override
  List<Enum> choicesFor(Question question) => IntervalNumber.values;

  @override
  LayoutOptions get layoutOptions => const LayoutOptions();

  @override
  QuestionSource questions(Random random) => _IntervalQuestions(this);
}

/// Rythme tapé : des phrases à taper l'une après l'autre, sur un métronome.
///
/// Clé de la session comparée par identité : la leçon est chargée une fois.
class TapRhythmExercise extends ReadingExercise {
  const TapRhythmExercise({required this.phrases, required this.tempo});

  /// Les phrases, dans l'ordre : une portée, en x/4. Vérifié au chargement
  /// de la leçon, comme l'écart entre deux attaques.
  final List<System> phrases;

  /// Noires par minute.
  final int tempo;

  @override
  int get length => phrases.length;

  @override
  List<Enum> choicesFor(Question question) => TapVerdict.values;

  @override
  LayoutOptions get layoutOptions => const LayoutOptions();

  @override
  QuestionSource questions(Random random) => _TapQuestions(this);
}

/// Réserve la place d'une ligne supplémentaire sous la portée (do4) et de
/// deux au-dessus (do6) : la portée ne bouge pas d'une question d'oreille à
/// l'autre.
const _earLayout = LayoutOptions(reserveAbove: 4.5, reserveBelow: 3.5);

/// Oreille : le do central, puis une note de do4 à si4 à nommer au clavier.
class EarNoteParams extends ReadingExercise {
  const EarNoteParams({required this.notes});

  /// Notes possibles, touches blanches : par l'oreille, un fa dièse et un
  /// sol bémol ne se distinguent pas.
  final List<NoteName> notes;

  @override
  int get length => earSessionLength;

  @override
  List<Enum> choicesFor(Question question) => NoteName.naturals;

  @override
  LayoutOptions get layoutOptions => _earLayout;

  @override
  QuestionSource questions(Random random) => _EarNotes(this, random);

  @override
  bool operator ==(Object other) =>
      other is EarNoteParams && _sameList(other.notes, notes);

  @override
  int get hashCode => Object.hashAll(notes);
}

/// Oreille : deux notes entendues, l'une après l'autre en montant, ou
/// ensemble ([harmonic]). Nommer l'intervalle.
class EarIntervalParams extends ReadingExercise {
  const EarIntervalParams({required this.intervals, this.harmonic = false});

  /// Intervalles possibles, et les réponses proposées, du plus petit au plus
  /// grand.
  final List<IntervalNumber> intervals;

  /// Les deux notes ensemble.
  final bool harmonic;

  @override
  int get length => earSessionLength;

  @override
  List<Enum> choicesFor(Question question) => intervals;

  @override
  LayoutOptions get layoutOptions => _earLayout;

  @override
  QuestionSource questions(Random random) => _EarIntervals(this, random);

  @override
  bool operator ==(Object other) =>
      other is EarIntervalParams &&
      other.harmonic == harmonic &&
      _sameList(other.intervals, intervals);

  @override
  int get hashCode => Object.hash(harmonic, Object.hashAll(intervals));
}

bool _sameList<T>(List<T> a, List<T> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);

/// Révision : des cartes, chacune seule sur sa portée (voir
/// `lib/review/card.dart`). Notes, durées et signes s'y mélangent : les
/// réponses dépendent de la question.
///
/// Clé de la session comparée par identité : construite une fois, au
/// lancement de la révision.
class ReviewExercise extends ReadingExercise {
  const ReviewExercise({required this.cards, this.markingChoices = const {}});

  /// Questions des cartes, dans l'ordre.
  final List<Question> cards;

  /// Réponses proposées pour chaque signe des cartes.
  final Map<Marking, List<Marking>> markingChoices;

  @override
  int get length => cards.length;

  /// Touches noires ouvertes dès qu'une note de la révision est altérée,
  /// pour toutes ses notes : elles ne trahissent pas la réponse.
  @override
  List<Enum> choicesFor(Question question) => switch (question) {
    NoteQuestion() =>
      cards.any(
            (card) => card is NoteQuestion && card.answer.accidental != null,
          )
          ? NoteName.values
          : NoteName.naturals,
    DurationQuestion() => Beats.values,
    MarkingQuestion(:final answer) => markingChoices[answer] ?? [answer],
    IntervalQuestion() => IntervalNumber.values,
    EarNoteQuestion() => NoteName.naturals,
    TapQuestion() => TapVerdict.values,
  };

  /// La place de deux lignes supplémentaires, au-dessus et au-dessous : la
  /// portée bouge peu d'une carte à l'autre.
  @override
  LayoutOptions get layoutOptions =>
      const LayoutOptions(reserveAbove: 4.5, reserveBelow: 4.5);

  @override
  QuestionSource questions(Random random) => _CardQuestions(cards);
}

/// Une question : ce qui s'affiche, et la bonne réponse parmi les choix de
/// l'exercice.
sealed class Question {
  const Question({required this.system, this.explanation});

  /// Ce qui s'affiche.
  final System system;

  /// Explication écrite par l'auteur de la leçon, montrée à la correction.
  /// `null` : l'appli la génère.
  final String? explanation;

  /// Événements à colorer dans [system], vide si rien n'est ciblé.
  List<EventRef> get targets;

  /// Événements dont les décorations sont à colorer, sans leur note.
  List<EventRef> get decorationTargets => const [];

  /// Bonne réponse.
  Enum get answer;

  /// Vrai pour une question d'oreille : la portée est cachée jusqu'à la
  /// correction.
  bool get heard => false;
}

/// Une note à nommer.
class NoteQuestion extends Question {
  const NoteQuestion({
    required super.system,
    required this.pitch,
    required this.target,
    required this.answer,
    super.explanation,
  });

  /// La note à trouver, telle qu'écrite.
  final Pitch pitch;

  /// La note à colorer dans [system], même seule : la cible se lit d'un
  /// coup d'œil, et la correction la colore.
  final EventRef target;

  @override
  List<EventRef> get targets => [target];

  /// Le nom de la note, avec l'altération qu'on lit (armure comprise).
  @override
  final NoteName answer;
}

/// Une durée à donner en temps.
class DurationQuestion extends Question {
  const DurationQuestion({
    required super.system,
    required this.targets,
    required this.answer,
    super.explanation,
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
    super.explanation,
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

/// Un intervalle à nommer par son numéro : lu sur la portée, ou entendu.
class IntervalQuestion extends Question {
  const IntervalQuestion({
    required super.system,
    required this.targets,
    required this.pitches,
    required this.harmonic,
    required this.answer,
    this.heard = false,
    super.explanation,
  });

  /// L'accord, ou les deux notes.
  @override
  final List<EventRef> targets;

  /// Les deux notes telles qu'on les lit, dans l'ordre de lecture : du
  /// grave à l'aigu pour un accord.
  final List<Pitch> pitches;

  /// Les deux notes ensemble (un accord).
  final bool harmonic;

  @override
  final bool heard;

  @override
  final IntervalNumber answer;
}

/// Oreille : le do central, puis une note à nommer.
class EarNoteQuestion extends Question {
  const EarNoteQuestion({
    required super.system,
    required this.pitch,
    required this.answer,
  });

  /// La note entendue.
  final Pitch pitch;

  /// Le do, puis la note.
  @override
  List<EventRef> get targets => const [
    EventRef(staff: 0, measure: 0, event: 1),
  ];

  @override
  bool get heard => true;

  @override
  final NoteName answer;
}

/// Une phrase à taper en rythme. La réponse attendue est
/// [TapVerdict.inTime] : la réponse donnée est le bilan des touches.
class TapQuestion extends Question {
  TapQuestion({required super.system, required this.tempo})
    : attacks = attacksOf(system),
      track = ClickTrack.forPhrase(system, tempo);

  /// Noires par minute.
  final int tempo;

  /// Les attaques à taper, dans l'ordre.
  final List<Attack> attacks;

  /// Le métronome : une mesure de décompte, puis la phrase.
  final ClickTrack track;

  /// Instants des attaques, depuis le premier clic du décompte.
  List<Duration> get expected => [
    for (final attack in attacks) track.countIn + beatsAt(attack.beat, tempo),
  ];

  /// Rien n'est ciblé : toute la phrase se tape.
  @override
  List<EventRef> get targets => const [];

  @override
  TapVerdict get answer => TapVerdict.inTime;
}

/// Le do de référence puis [pitch], en rondes sur la clé de sol.
EarNoteQuestion earNoteQuestion(Pitch pitch) => EarNoteQuestion(
  system: System.single(
    Staff(
      clef: Clef.treble,
      measures: [
        Measure([const Note(referencePitch), Note(pitch)]),
      ],
    ),
  ),
  pitch: pitch,
  answer: NoteName.of(pitch.step, pitch.accidental)!,
);

/// Intervalle seul sur sa portée : deux rondes, ou un accord si
/// [harmonic]. `null` au-delà de l'octave, ou pour un unisson en accord.
IntervalQuestion? intervalQuestion(
  Clef clef,
  Pitch first,
  Pitch second, {
  required bool harmonic,
  bool heard = false,
}) {
  final answer = intervalBetween(first, second);
  if (answer == null || (harmonic && answer == IntervalNumber.unison)) {
    return null;
  }
  final ordered = harmonic && first.diatonic > second.diatonic
      ? [second, first]
      : [first, second];
  final system = System.single(
    Staff(
      clef: clef,
      measures: [
        Measure(
          harmonic ? [Chord(ordered)] : [Note(ordered[0]), Note(ordered[1])],
        ),
      ],
    ),
  );
  return IntervalQuestion(
    system: system,
    targets: [
      const EventRef(staff: 0, measure: 0, event: 0),
      if (!harmonic) const EventRef(staff: 0, measure: 0, event: 1),
    ],
    pitches: ordered,
    harmonic: harmonic,
    answer: answer,
    heard: heard,
  );
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
      accidental: _accidental(natural.step),
    );
    final measures = [
      Measure([Note(pitch)]),
    ];

    final grand = params.staff == StaffSetup.grand;
    final system = grand
        ? System([
            clef == Clef.treble
                ? StaffGroup.grand(upper: measures)
                : StaffGroup.grand(lower: measures),
          ])
        : System.single(Staff(clef: clef, measures: measures));
    return NoteQuestion(
      system: system,
      pitch: pitch,
      answer: NoteName.of(pitch.step, pitch.accidental)!,
      // Sur la grande portée, la clé de fa est la portée du bas.
      target: EventRef(
        staff: grand && clef == Clef.bass ? 1 : 0,
        measure: 0,
        event: 0,
      ),
    );
  }

  /// Une note sur trois porte un dièse ou un bémol, sur une touche noire :
  /// pas de mi dièse ni de do bémol.
  Accidental? _accidental(DiatonicStep step) {
    if (!params.accidentals || random.nextInt(3) != 0) return null;
    final drawn = random.nextBool() ? Accidental.sharp : Accidental.flat;
    if (NoteName.of(step, drawn) != null) return drawn;
    return drawn == Accidental.sharp ? Accidental.flat : Accidental.sharp;
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
    final system = exercise.system;
    final note = system.event(target)! as Note;
    return NoteQuestion(
      system: system,
      pitch: note.pitch,
      target: target,
      answer: noteNameAt(system, target)!,
      explanation: exercise.explanations[target],
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
    final target = exercise.targets[_index++];
    final targets = system.tieChain(target);
    return DurationQuestion(
      system: system,
      targets: targets,
      answer: Beats.of(beatsOf(system, targets))!,
      explanation: exercise.explanations[target],
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
      explanation: exercise.explanations[target],
    );
  }
}

/// Les cibles d'un [IdentifyIntervalExercise], dans l'ordre.
class _IntervalQuestions implements QuestionSource {
  _IntervalQuestions(this.exercise);

  final IdentifyIntervalExercise exercise;
  var _index = 0;

  @override
  IntervalQuestion next({Question? previous}) {
    final system = exercise.system;
    final target = exercise.targets[_index++];
    // Le chargement de la leçon a vérifié les notes et l'écart.
    final pitches = intervalPitches(system, target)!;
    return IntervalQuestion(
      system: system,
      targets: target.refs,
      pitches: pitches,
      harmonic: target.harmonic,
      answer: intervalBetween(pitches[0], pitches[1])!,
      explanation: exercise.explanations[target.from],
    );
  }
}

/// Tire les notes d'un [EarNoteParams], jamais deux fois la même d'affilée.
class _EarNotes implements QuestionSource {
  _EarNotes(this.params, this.random);

  final EarNoteParams params;
  final Random random;

  @override
  EarNoteQuestion next({Question? previous}) {
    final last = previous is EarNoteQuestion ? previous.answer : null;
    final notes = params.notes.length > 1
        ? params.notes.where((note) => note != last).toList()
        : params.notes;
    final name = notes[random.nextInt(notes.length)];
    return earNoteQuestion(Pitch(name.step, referencePitch.octave));
  }
}

/// Tire les intervalles d'un [EarIntervalParams] sur les touches blanches,
/// la note du bas de do4 à do5. Jamais de triton : quarte augmentée ou
/// quinte diminuée, son numéro ne s'entend pas. Jamais deux fois la même
/// paire d'affilée.
class _EarIntervals implements QuestionSource {
  _EarIntervals(this.params, this.random);

  final EarIntervalParams params;
  final Random random;

  @override
  IntervalQuestion next({Question? previous}) {
    final last = previous is IntervalQuestion ? previous.pitches : null;
    while (true) {
      final number = params.intervals[random.nextInt(params.intervals.length)];
      final low = referencePitch.diatonic + random.nextInt(8);
      final first = Pitch.fromDiatonic(low);
      final second = Pitch.fromDiatonic(low + number.size - 1);
      if (semitonesBetween(first, second) == 6) continue;
      if (last != null && last[0] == first && last[1] == second) continue;
      final question = intervalQuestion(
        Clef.treble,
        first,
        second,
        harmonic: params.harmonic,
        heard: true,
      );
      if (question != null) return question;
    }
  }
}

/// Les phrases d'un [TapRhythmExercise], dans l'ordre.
class _TapQuestions implements QuestionSource {
  _TapQuestions(this.exercise);

  final TapRhythmExercise exercise;
  var _index = 0;

  @override
  TapQuestion next({Question? previous}) =>
      TapQuestion(system: exercise.phrases[_index++], tempo: exercise.tempo);
}

/// Les cartes d'une [ReviewExercise], dans l'ordre.
class _CardQuestions implements QuestionSource {
  _CardQuestions(this.cards);

  final List<Question> cards;
  var _index = 0;

  @override
  Question next({Question? previous}) => cards[_index++];
}
