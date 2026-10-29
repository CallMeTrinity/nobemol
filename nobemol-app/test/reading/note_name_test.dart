import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/reading/note_name.dart';

void main() {
  EventRef at(int measure, int event, {int staff = 0}) =>
      EventRef(staff: staff, measure: measure, event: event);

  test('noms au clavier : 7 blanches, 5 noires en deux orthographes', () {
    expect(NoteName.naturals, hasLength(7));
    expect(NoteName.values, hasLength(17));
    expect(NoteName.of(DiatonicStep.f, Accidental.sharp), NoteName.fSharp);
    expect(NoteName.of(DiatonicStep.g, Accidental.flat), NoteName.gFlat);
    expect(NoteName.of(DiatonicStep.f, Accidental.natural), NoteName.f);
    expect(NoteName.of(DiatonicStep.e, Accidental.sharp), isNull);
    expect(NoteName.of(DiatonicStep.c, Accidental.flat), isNull);
    expect(NoteName.of(DiatonicStep.c, Accidental.doubleSharp), isNull);
    // Même touche noire, deux noms différents.
    expect(NoteName.fSharp.blackKey, DiatonicStep.f);
    expect(NoteName.gFlat.blackKey, DiatonicStep.f);
    expect(NoteName.f.blackKey, isNull);
  });

  group('altération lue', () {
    test('écrite, puis reprise dans la mesure, pas au-delà', () {
      final system = parseAbc('X:1\nM:3/4\nL:1/4\nK:C\n^F F f | F3 |]\n');
      expect(
        soundingAccidental(system, at(0, 0))?.source,
        AccidentalSource.written,
      );
      expect(noteNameAt(system, at(0, 1)), NoteName.fSharp);
      expect(
        soundingAccidental(system, at(0, 1))?.source,
        AccidentalSource.measure,
      );
      // Autre octave : pas concernée.
      expect(noteNameAt(system, at(0, 2)), NoteName.f);
      // Après la barre : effacée.
      expect(noteNameAt(system, at(1, 0)), NoteName.f);
    });

    test('l’armure, annulée par un bécarre jusqu’à la barre', () {
      final system = parseAbc('X:1\nM:3/4\nL:1/4\nK:G\nF =F F | F3 |]\n');
      expect(noteNameAt(system, at(0, 0)), NoteName.fSharp);
      expect(
        soundingAccidental(system, at(0, 0))?.source,
        AccidentalSource.key,
      );
      expect(noteNameAt(system, at(0, 1)), NoteName.f);
      expect(noteNameAt(system, at(0, 2)), NoteName.f);
      expect(noteNameAt(system, at(1, 0)), NoteName.fSharp);
    });

    test('une liaison prolonge l’altération dans la mesure suivante', () {
      final system = parseAbc('X:1\nM:2/4\nL:1/4\nK:C\nC ^F- | F2 |]\n');
      expect(noteNameAt(system, at(1, 0)), NoteName.fSharp);
      expect(
        soundingAccidental(system, at(1, 0))?.source,
        AccidentalSource.tie,
      );
    });

    test('rien : note naturelle', () {
      final system = parseAbc('X:1\nM:2/4\nL:1/4\nK:C\nC D |]\n');
      expect(soundingAccidental(system, at(0, 1)), isNull);
      expect(hasAccidentals(system), isFalse);
    });
  });
}
