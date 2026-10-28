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

  Staff staff(Clef clef, Pitch pitch) => Staff(
    clef: clef,
    measures: [
      Measure([Note(pitch)]),
    ],
  );

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
          upper: const [
            Measure([Note(Pitch(DiatonicStep.a, 3))]),
          ],
          lower: const [
            Measure([
              Note(
                Pitch(DiatonicStep.f, 2, accidental: Accidental.doubleSharp),
              ),
            ]),
          ],
        ),
      ]),
      'grand_staff',
    );
  });

  testWidgets('phrase : armure, chiffrage, hampes, barres', skip: _skip, (
    tester,
  ) async {
    await expectGolden(
      tester,
      parseAbc('X:1\nM:4/4\nL:1/4\nK:Bb\nB, D F B | d f b2 | =e2 _A2 |]\n'),
      'phrase_treble',
    );
  });

  testWidgets(
    'grande portée : colonnes communes et barres traversantes',
    skip: _skip,
    (tester) async {
      await expectGolden(
        tester,
        parseAbc(
          'X:1\n%%score {RH LH}\nM:3/4\nL:1/4\nK:D\n'
          "V:RH\nf2 a | ^g a b | d'2 a |]\n"
          'V:LH clef=bass\nD,2 A,, | E, F, G, | A,,2 D, |]\n',
        ),
        'phrase_grand_staff',
      );
    },
  );

  testWidgets('armures sur les quatre clés', skip: _skip, (tester) async {
    await expectGolden(
      tester,
      parseAbc(
        'X:1\n%%score A B C D\n'
        'V:A\nV:B clef=bass\nV:C clef=alto\nV:D clef=tenor\nK:C#\n',
      ),
      'key_signatures_sharps',
    );
    await expectGolden(
      tester,
      parseAbc(
        'X:1\n%%score A B C D\n'
        'V:A\nV:B clef=bass\nV:C clef=alto\nV:D clef=tenor\nK:Cb\n',
      ),
      'key_signatures_flats',
    );
  });
}
