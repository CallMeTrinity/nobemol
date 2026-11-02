import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/audio/synth.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/review/card.dart';

void main() {
  test('hauteurs : do4 = 60, la4 = 69, altérations comprises', () {
    expect(midiOf(DiatonicStep.c, 4, null), 60);
    expect(midiOf(DiatonicStep.a, 4, null), 69);
    expect(midiOf(DiatonicStep.f, 5, Accidental.sharp), 78);
    expect(midiOf(DiatonicStep.b, 3, Accidental.flat), 58);
    expect(midiOf(DiatonicStep.e, 2, Accidental.natural), 40);
    expect(frequencyOf(69), 440);
    expect(frequencyOf(57), closeTo(220, 1e-9));
  });

  test('une question sonne la note lue, à l’octave écrite', () {
    // Le fa dièse d'une armure : la carte garde l'altération lue.
    final question = questionOf('note:bass:fSharp3')! as NoteQuestion;
    expect(midiOfQuestion(question), 54);
  });

  group('son de piano', () {
    final wav = pianoWav(69);
    final data = ByteData.sublistView(wav);
    final samples = (wav.length - 44) ~/ 2;
    int sample(int i) => data.getInt16(44 + i * 2, Endian.little);

    test('fichier WAV : PCM 16 bits mono, la bonne durée', () {
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 16)), 'WAVEfmt ');
      expect(data.getUint16(22, Endian.little), 1);
      expect(data.getUint32(24, Endian.little), sampleRate);
      expect(data.getUint32(40, Endian.little), samples * 2);
      expect(samples, sampleRate * noteLength.inMilliseconds ~/ 1000);
    });

    test('on entend un la 440 : la fondamentale domine', () {
      // Passages par zéro vers le haut sur 0,2 s, après l'attaque.
      final from = sampleRate ~/ 20;
      final to = from + sampleRate ~/ 5;
      var crossings = 0;
      for (var i = from + 1; i < to; i++) {
        if (sample(i - 1) < 0 && sample(i) >= 0) crossings++;
      }
      expect(crossings * 5, closeTo(440, 15));
    });

    test('attaque douce, s’éteint, finit sans clic', () {
      expect(sample(0), 0);
      var peak = 0;
      for (var i = 0; i < samples; i++) {
        peak = sample(i).abs() > peak ? sample(i).abs() : peak;
      }
      expect(peak, closeTo(0.8 * 32767, 2));
      expect(sample(samples - 1).abs(), lessThan(50));
    });
  });
}
