@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

import '../helpers/bravura.dart';

/// Le rendu des polices varie selon l'OS : les goldens ne sont générés et
/// comparés que sous Linux (CI, workflow `goldens.yml`).
final bool _skip = !Platform.isLinux;

void main() {
  setUpAll(loadBravura);

  Future<void> expectGolden(
    WidgetTester tester,
    System system,
    String name,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: NotationView(system: system, staffSpace: 16),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  Staff staff(Clef clef, Pitch pitch) =>
      Staff(clef: clef, notes: [Note(pitch)]);

  testWidgets('clé de sol, do central', skip: _skip, (tester) async {
    await expectGolden(
      tester,
      System.single(staff(Clef.treble, const Pitch(DiatonicStep.c, 4))),
      'treble_c4',
    );
  });

  testWidgets('clé de fa, altération et lignes au-dessus', skip: _skip, (
    tester,
  ) async {
    await expectGolden(
      tester,
      System.single(
        staff(
          Clef.bass,
          const Pitch(DiatonicStep.e, 4, accidental: Accidental.flat),
        ),
      ),
      'bass_eb4',
    );
  });

  testWidgets("clés d'ut", skip: _skip, (tester) async {
    await expectGolden(
      tester,
      System([
        StaffGroup([
          staff(
            Clef.alto,
            const Pitch(DiatonicStep.c, 4, accidental: Accidental.sharp),
          ),
        ]),
        StaffGroup([
          staff(
            Clef.tenor,
            const Pitch(DiatonicStep.c, 4, accidental: Accidental.natural),
          ),
        ]),
      ]),
      'alto_tenor',
    );
  });

  testWidgets('grande portée', skip: _skip, (tester) async {
    await expectGolden(
      tester,
      System([
        StaffGroup.grand(
          upper: const [Note(Pitch(DiatonicStep.a, 3))],
          lower: const [
            Note(Pitch(DiatonicStep.f, 2, accidental: Accidental.doubleSharp)),
          ],
        ),
      ]),
      'grand_staff',
    );
  });
}
