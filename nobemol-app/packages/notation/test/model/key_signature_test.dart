import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

void main() {
  test('les dièses : fa, do, sol...', () {
    expect(const KeySignature(3).steps, [
      DiatonicStep.f,
      DiatonicStep.c,
      DiatonicStep.g,
    ]);
    expect(const KeySignature(3).accidental, Accidental.sharp);
  });

  test('les bémols : si, mi, la...', () {
    expect(const KeySignature(-2).steps, [DiatonicStep.b, DiatonicStep.e]);
    expect(const KeySignature(-2).accidental, Accidental.flat);
  });

  test('sans altération', () {
    expect(KeySignature.none.steps, isEmpty);
    expect(KeySignature.none.accidental, isNull);
  });
}
