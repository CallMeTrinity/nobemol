import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

void main() {
  group('Clef.staffPosition', () {
    test('clé de sol : mi4 sur la ligne du bas, fa5 sur celle du haut', () {
      expect(Clef.treble.staffPosition(const Pitch(DiatonicStep.e, 4)), 0);
      expect(Clef.treble.staffPosition(const Pitch(DiatonicStep.g, 4)), 2);
      expect(Clef.treble.staffPosition(const Pitch(DiatonicStep.f, 5)), 8);
    });

    test('clé de sol : do central sur la 1re ligne supplémentaire', () {
      expect(Clef.treble.staffPosition(const Pitch(DiatonicStep.c, 4)), -2);
      expect(Clef.treble.staffPosition(const Pitch(DiatonicStep.a, 5)), 10);
    });

    test('clé de fa : sol2 sur la ligne du bas, la3 sur celle du haut', () {
      expect(Clef.bass.staffPosition(const Pitch(DiatonicStep.g, 2)), 0);
      expect(Clef.bass.staffPosition(const Pitch(DiatonicStep.f, 3)), 6);
      expect(Clef.bass.staffPosition(const Pitch(DiatonicStep.a, 3)), 8);
      expect(Clef.bass.staffPosition(const Pitch(DiatonicStep.c, 4)), 10);
    });

    test("clés d'ut : do4 sur la 3e ou la 4e ligne", () {
      expect(Clef.alto.staffPosition(const Pitch(DiatonicStep.c, 4)), 4);
      expect(Clef.alto.staffPosition(const Pitch(DiatonicStep.f, 3)), 0);
      expect(Clef.tenor.staffPosition(const Pitch(DiatonicStep.c, 4)), 6);
      expect(Clef.tenor.staffPosition(const Pitch(DiatonicStep.d, 3)), 0);
    });

    test("l'altération ne change pas la position", () {
      const sharp = Pitch(DiatonicStep.f, 4, accidental: Accidental.sharp);
      const flat = Pitch(DiatonicStep.g, 4, accidental: Accidental.flat);
      expect(Clef.treble.staffPosition(sharp), 1);
      expect(Clef.treble.staffPosition(flat), 2);
    });
  });

  test('pitchAt est la réciproque de staffPosition', () {
    for (final clef in [Clef.treble, Clef.bass, Clef.alto, Clef.tenor]) {
      for (var position = -8; position <= 16; position++) {
        expect(clef.staffPosition(clef.pitchAt(position)), position);
      }
    }
  });
}
