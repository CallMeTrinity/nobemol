import 'dart:math';

import 'package:notation/core.dart';

import 'package:nobemol/reading/note_reading.dart';

/// Numéro MIDI d'une hauteur : do4 (do du milieu) = 60, la4 = 69.
int midiOf(DiatonicStep step, int octave, Accidental? accidental) {
  const semitones = {
    DiatonicStep.c: 0,
    DiatonicStep.d: 2,
    DiatonicStep.e: 4,
    DiatonicStep.f: 5,
    DiatonicStep.g: 7,
    DiatonicStep.a: 9,
    DiatonicStep.b: 11,
  };
  return 12 * (octave + 1) + semitones[step]! + (accidental?.alteration ?? 0);
}

/// Ce qu'on entend pour [question] : la note lue, armure et altérations de
/// la mesure comprises (la réponse), à l'octave écrite.
int midiOfQuestion(NoteQuestion question) => midiOf(
  question.answer.step,
  question.pitch.octave,
  question.answer.accidental,
);

/// Ce qu'on entend pour [question], étape par étape (chaque étape : des
/// notes ensemble). Vide pour une durée ou un signe : pas de hauteur.
List<List<int>> soundOf(Question question) => switch (question) {
  NoteQuestion() => [
    [midiOfQuestion(question)],
  ],
  IntervalQuestion(:final pitches, harmonic: true) => [
    [for (final pitch in pitches) midiOfPitch(pitch)],
  ],
  IntervalQuestion(:final pitches) => [
    for (final pitch in pitches) [midiOfPitch(pitch)],
  ],
  EarNoteQuestion(:final pitch) => [
    [midiOfPitch(referencePitch)],
    [midiOfPitch(pitch)],
  ],
  DurationQuestion() || MarkingQuestion() => const [],
};

/// Numéro MIDI d'une hauteur telle qu'on la lit.
int midiOfPitch(Pitch pitch) =>
    midiOf(pitch.step, pitch.octave, pitch.accidental);

/// Notes enregistrées du piano (Salamander Grand Piano, préparées par
/// `tool/piano_samples.sh`) : toutes les tierces mineures, du la0 (21) au
/// do8 (108). Tout le clavier.
final pianoSamples = List<int>.unmodifiable([
  for (var midi = 21; midi <= 108; midi += 3) midi,
]);

/// Le fichier d'une note enregistrée.
String pianoAsset(int sample) => 'assets/audio/piano/$sample.ogg';

/// Comment jouer [midi] : la note enregistrée la plus proche, accélérée ou
/// ralentie. Un demi-ton au plus sur le clavier, l'oreille n'entend pas
/// le timbre changer. Hors du clavier, la note du bout, plus décalée.
({int sample, double speed}) pianoSample(int midi) {
  final index = ((midi - pianoSamples.first) / 3).round().clamp(
    0,
    pianoSamples.length - 1,
  );
  final sample = pianoSamples[index];
  return (sample: sample, speed: pow(2, (midi - sample) / 12).toDouble());
}
