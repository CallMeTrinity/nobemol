import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/audio/metronome.dart';
import 'package:nobemol/audio/piano.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/tapping.dart';

void main() {
  System abc(String music, {String meter = '4/4', String unit = '1/4'}) =>
      parseAbc('X:1\nM:$meter\nL:$unit\nK:C\n$music\n');

  Duration ms(int value) => Duration(milliseconds: value);

  group('attaques', () {
    test('un silence ne se tape pas, une note liée non plus', () {
      final system = abc('B2 z B- | B B B2 |]');
      final attacks = attacksOf(system);
      expect(attacks.map((attack) => attack.beat), [
        Fraction.zero,
        const Fraction(3),
        const Fraction(5),
        const Fraction(6),
      ]);
      // La note liée colorée avec la note qui attaque.
      expect(attacks[1].chain, [
        const EventRef(staff: 0, measure: 0, event: 2),
        const EventRef(staff: 0, measure: 1, event: 0),
      ]);
    });

    test('croches et noire pointée, en temps', () {
      final attacks = attacksOf(abc('B3 B BB B2 |]', unit: '1/8'));
      expect(attacks.map((attack) => attack.beat), [
        Fraction.zero,
        const Fraction(3, 2),
        const Fraction(2),
        const Fraction(5, 2),
        const Fraction(3),
      ]);
    });

    test('écart le plus court au tempo', () {
      // Croches à 72 : 417 ms.
      expect(
        shortestGap(abc('B2 BB B4 |]', unit: '1/8'), 72)!.inMilliseconds,
        416,
      );
      expect(shortestGap(abc('B4 |]'), 72), isNull);
    });

    test('la question : décompte d’une mesure, puis les attaques', () {
      final question = TapQuestion(system: abc('B2 B B |]'), tempo: 60);
      expect(question.track.beats, 8);
      expect(question.track.countIn, const Duration(seconds: 4));
      expect(question.expected, [
        const Duration(seconds: 4),
        const Duration(seconds: 6),
        const Duration(seconds: 7),
      ]);
    });
  });

  group('touches jugées', () {
    // Noires à 60 : une attaque par seconde.
    final expected = [ms(1000), ms(2000), ms(3000)];
    TapGrade grade(List<int> taps) => gradeTaps(
      expected: expected,
      taps: [for (final tap in taps) ms(tap)],
      beat: ms(1000),
    );

    test('dans la tolérance : en place', () {
      final taps = grade([1050, 1900, 3120]);
      expect(taps.timings, everyElement(TapTiming.inTime));
      expect(taps.verdict, TapVerdict.inTime);
      expect(taps.meanInTime, ms(90));
    });

    test('au-delà : en avance ou en retard', () {
      final taps = grade([1000, 1800, 3200]);
      expect(taps.timings, [TapTiming.inTime, TapTiming.early, TapTiming.late]);
      expect(taps.offsets, [ms(0), ms(-200), ms(200)]);
      // Autant d'avance que de retard : le retard.
      expect(taps.verdict, TapVerdict.late);
    });

    test('une note sans touche : oubliée, le défaut principal', () {
      final taps = grade([1000, 3300]);
      expect(taps.timings, [
        TapTiming.inTime,
        TapTiming.missed,
        TapTiming.late,
      ]);
      expect(taps.verdict, TapVerdict.missed);
    });

    test(
      'deux touches sur une note : la plus proche compte, l’autre en trop',
      () {
        final taps = grade([1000, 1700, 2010, 3000]);
        expect(taps.timings, everyElement(TapTiming.inTime));
        expect(taps.offsets[1], ms(10));
        expect(taps.extra, 1);
        // Une erreur sur 3 notes : permise.
        expect(taps.faults, 1);
        expect(taps.verdict, TapVerdict.inTime);
        // Deux : la phrase est ratée.
        expect(grade([1000, 1700, 2010, 2200, 3000]).verdict, TapVerdict.extra);
      },
    );

    // Croches à 60 : une attaque par demi-seconde.
    final eighths = [ms(1000), ms(1500), ms(2000)];
    TapGrade gradeEighths(List<int> taps) => gradeTaps(
      expected: eighths,
      taps: [for (final tap in taps) ms(tap)],
      beat: ms(1000),
    );

    test('une touche en retard reste à sa note, sans prendre la suivante', () {
      // 1 760 est plus près de la 3e note (2 000), mais la 3e a sa touche.
      final taps = gradeEighths([1000, 1760, 2000]);
      expect(taps.timings, [
        TapTiming.inTime,
        TapTiming.late,
        TapTiming.inTime,
      ]);
      expect(taps.offsets[1], ms(260));
      expect(taps.extra, 0);
    });

    test('un double appui est toujours en trop', () {
      // Le second appui ne prend pas la note suivante.
      for (final bounce in [1050, 1150, 1240]) {
        final taps = gradeEighths([1000, bounce, 1500, 2000]);
        expect(taps.timings, everyElement(TapTiming.inTime), reason: '$bounce');
        expect(taps.extra, 1, reason: '$bounce');
      }
    });

    test('erreurs permises : une par tranche de 5 notes, une au moins', () {
      TapGrade notes(int count) => TapGrade(
        timings: List.filled(count, TapTiming.inTime),
        offsets: List.filled(count, Duration.zero),
      );
      expect(notes(3).allowedFaults, 1);
      expect(notes(6).allowedFaults, 1);
      expect(notes(10).allowedFaults, 2);
    });

    test('pendant le décompte : ignorées', () {
      expect(grade([100, 400, 1000, 2000, 3000]).verdict, TapVerdict.inTime);
    });

    test('loin de toute note, après la première : en trop', () {
      // Les fenêtres s'arrêtent à mi-chemin : 1 500 ms tombe sur la
      // deuxième, en avance. Après la dernière, un demi-temps au plus.
      expect(grade([1000, 2000, 3000, 3600]).extra, 1);
    });
  });

  group('horodatage des touches', () {
    test('recalé sur la réception la plus rapide', () {
      // Touches à 500 ms d'écart exact, reçues avec 25, 0 puis 13 ms de
      // retard : les horodatages comptent, recalés sur la plus rapide.
      final taps = alignTaps([
        (stamp: ms(10000), received: ms(1030)),
        (stamp: ms(10500), received: ms(1505)),
        (stamp: ms(11000), received: ms(2018)),
      ]);
      expect(taps, [ms(1005), ms(1505), ms(2005)]);
    });

    test('sans horodatages utilisables : la réception', () {
      final taps = alignTaps([
        (stamp: Duration.zero, received: ms(1030)),
        (stamp: Duration.zero, received: ms(1505)),
      ]);
      expect(taps, [ms(1030), ms(1505)]);
    });
  });

  group('calage', () {
    test('la médiane des écarts, après le décompte', () {
      final track = calibrationTrack;
      final taps = [
        // Pendant le décompte : ignorées.
        track.click(0) + ms(300),
        for (var i = track.beatsPerMeasure; i < track.beats; i++)
          track.click(i) + ms(i.isEven ? 70 : 90),
      ];
      expect(calibrate(taps), ms(80));
    });

    test('trop peu de touches : pas de calage', () {
      final track = calibrationTrack;
      expect(
        calibrate([for (var i = 4; i < 9; i++) track.click(i) + ms(50)]),
        isNull,
      );
    });

    test('borné : un retard énorme n’est pas de la latence', () {
      final track = calibrationTrack;
      expect(
        calibrate([for (var i = 4; i < 16; i++) track.click(i) + ms(290)]),
        ms(290),
      );
      expect(
        calibrate([for (var i = 4; i < 16; i++) track.click(i) - ms(250)]),
        minTapLatency,
      );
    });
  });

  group('métronome', () {
    test('un seul WAV : un clic par temps, à l’échantillon près', () {
      const track = ClickTrack(tempo: 120, beatsPerMeasure: 2, beats: 4);
      final wav = clickWav(track);
      final bytes = ByteData.sublistView(wav);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(bytes.getUint32(24, Endian.little), clickSampleRate);
      // 2 s de clics, puis 200 ms de fin.
      final frames = bytes.getUint32(40, Endian.little) ~/ 2;
      expect(frames, clickSampleRate * 22 ~/ 10);
      int sample(int frame) => bytes.getInt16(44 + frame * 2, Endian.little);
      // Un clic démarre à chaque demi-seconde, silence entre deux.
      for (var beat = 0; beat < 4; beat++) {
        final start = beat * clickSampleRate ~/ 2;
        expect(
          [for (var n = 1; n < 20; n++) sample(start + n).abs()]
              .any((value) => value > 1000),
          isTrue,
          reason: 'clic $beat',
        );
        expect(sample(start + clickSampleRate ~/ 4), 0);
      }
    });
  });

  test('la phrase rejouée : notes, silences, liaisons', () {
    final question = TapQuestion(system: abc('B2 z B- | B4 |]'), tempo: 60);
    final steps = rhythmSound(question);
    expect(steps.map((step) => step.$1), const [
      Duration(seconds: 4),
      Duration(seconds: 6),
      Duration(seconds: 7),
      // La note liée prolonge la précédente : la fin, puis rien.
      Duration(seconds: 12),
    ]);
    expect(steps.map((step) => step.$2), [
      [71],
      <int>[],
      [71],
      <int>[],
    ]);
  });
}
