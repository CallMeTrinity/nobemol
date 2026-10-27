import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

void main() {
  test('diatonic compte 7 degrés par octave', () {
    expect(const Pitch(DiatonicStep.c, 0).diatonic, 0);
    expect(const Pitch(DiatonicStep.b, 3).diatonic, 27);
    expect(const Pitch(DiatonicStep.c, 4).diatonic, 28);
  });

  test('fromDiatonic est la réciproque de diatonic', () {
    for (var diatonic = -10; diatonic < 70; diatonic++) {
      expect(Pitch.fromDiatonic(diatonic).diatonic, diatonic);
    }
    expect(Pitch.fromDiatonic(-1), const Pitch(DiatonicStep.b, -1));
  });

  test("un fa# n'est pas un solb", () {
    const fSharp = Pitch(DiatonicStep.f, 4, accidental: Accidental.sharp);
    const gFlat = Pitch(DiatonicStep.g, 4, accidental: Accidental.flat);
    expect(fSharp, isNot(gFlat));
    expect(fSharp.toString(), 'F#4');
  });
}
