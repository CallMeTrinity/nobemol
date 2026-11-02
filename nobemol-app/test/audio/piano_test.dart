import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/audio/piano.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/review/card.dart';

void main() {
  test('hauteurs : do4 = 60, la4 = 69, altérations comprises', () {
    expect(midiOf(DiatonicStep.c, 4, null), 60);
    expect(midiOf(DiatonicStep.a, 4, null), 69);
    expect(midiOf(DiatonicStep.f, 5, Accidental.sharp), 78);
    expect(midiOf(DiatonicStep.b, 3, Accidental.flat), 58);
    expect(midiOf(DiatonicStep.e, 2, Accidental.natural), 40);
  });

  test('une question sonne la note lue, à l’octave écrite', () {
    // Le fa dièse d'une armure : la carte garde l'altération lue.
    final question = questionOf('note:bass:fSharp3')! as NoteQuestion;
    expect(midiOfQuestion(question), 54);
  });

  group('piano enregistré', () {
    final semitone = pow(2, 1 / 12).toDouble();

    test('une note enregistrée se joue telle quelle', () {
      expect(pianoSample(60), (sample: 60, speed: 1.0));
      expect(pianoSample(69), (sample: 69, speed: 1.0));
    });

    test('les autres : la plus proche, à un demi-ton près', () {
      expect(pianoSample(61).sample, 60);
      expect(pianoSample(61).speed, closeTo(semitone, 1e-9));
      expect(pianoSample(62).sample, 63);
      expect(pianoSample(62).speed, closeTo(1 / semitone, 1e-9));
      for (var midi = 21; midi <= 108; midi++) {
        final (:sample, :speed) = pianoSample(midi);
        expect((midi - sample).abs(), lessThanOrEqualTo(1), reason: '$midi');
        expect(speed, closeTo(pow(2, (midi - sample) / 12), 1e-9));
      }
    });

    test('hors du clavier : la note du bout', () {
      expect(pianoSample(15).sample, 21);
      expect(pianoSample(115).sample, 108);
      expect(pianoSample(120).speed, closeTo(pow(2, 1), 1e-9));
    });

    test('chaque note enregistrée a son fichier, déclaré en asset', () {
      expect(pianoSamples, hasLength(30));
      for (final sample in pianoSamples) {
        expect(
          File(pianoAsset(sample)).existsSync(),
          isTrue,
          reason: '$sample',
        );
      }
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/audio/piano/'),
      );
    });
  });
}
