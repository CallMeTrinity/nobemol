import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

void main() {
  SystemLayout layoutNote(Pitch pitch, {Clef clef = Clef.treble}) =>
      layoutSystem(
        System.single(
          Staff(
            clef: clef,
            measures: [
              Measure([Note(pitch)]),
            ],
          ),
        ),
      );

  System parse(String abc) => parseAbc('X:1\n$abc');

  Iterable<GlyphCommand> glyphs(SystemLayout layout, Glyph glyph) =>
      layout.commands.whereType<GlyphCommand>().where((c) => c.glyph == glyph);

  Iterable<LineCommand> ledgers(SystemLayout layout) => layout.commands
      .whereType<LineCommand>()
      .where((c) => c.thickness == EngravingDefaults.legerLineThickness);

  test('une portée : 5 lignes espacées d’un interligne', () {
    final layout = layoutNote(const Pitch(DiatonicStep.g, 4));
    final lines = layout.commands.whereType<LineCommand>().toList();
    expect(lines, hasLength(5));
    expect(lines.map((l) => l.y1), [0, 1, 2, 3, 4]);
  });

  test('la clé de sol est posée sur la 2e ligne', () {
    final clef = glyphs(
      layoutNote(const Pitch(DiatonicStep.g, 4)),
      Glyph.gClef,
    );
    expect(clef.single.y, 3);
  });

  test('la clé de fa est posée sur la 4e ligne', () {
    final layout = layoutNote(const Pitch(DiatonicStep.f, 3), clef: Clef.bass);
    expect(glyphs(layout, Glyph.fClef).single.y, 1);
  });

  test('la note est placée selon la clé et la hauteur', () {
    expect(
      glyphs(
        layoutNote(const Pitch(DiatonicStep.e, 4)),
        Glyph.noteheadWhole,
      ).single.y,
      4,
    );
    expect(
      glyphs(
        layoutNote(const Pitch(DiatonicStep.f, 5)),
        Glyph.noteheadWhole,
      ).single.y,
      0,
    );
    final bass = layoutNote(const Pitch(DiatonicStep.g, 2), clef: Clef.bass);
    expect(glyphs(bass, Glyph.noteheadWhole).single.y, 4);
  });

  group('lignes supplémentaires', () {
    test('aucune dans la portée ni juste autour', () {
      expect(ledgers(layoutNote(const Pitch(DiatonicStep.d, 4))), isEmpty);
      expect(ledgers(layoutNote(const Pitch(DiatonicStep.g, 5))), isEmpty);
    });

    test('do central en clé de sol : une ligne, sous la portée', () {
      final lines = ledgers(layoutNote(const Pitch(DiatonicStep.c, 4)));
      expect(lines.map((l) => l.y1), [5]);
    });

    test('note dans un interligne : pas de ligne sous la note', () {
      final lines = ledgers(layoutNote(const Pitch(DiatonicStep.b, 3)));
      expect(lines.map((l) => l.y1), [5]);
    });

    test('au-dessus de la portée', () {
      final lines = ledgers(layoutNote(const Pitch(DiatonicStep.e, 6)));
      expect(lines.map((l) => l.y1), [-1, -2, -3]);
    });

    test('dépassent de chaque côté de la tête', () {
      final layout = layoutNote(const Pitch(DiatonicStep.c, 4));
      final head = glyphs(layout, Glyph.noteheadWhole).single.bounds;
      final line = ledgers(layout).single;
      expect(line.x1, lessThan(head.left));
      expect(line.x2, greaterThan(head.right));
    });
  });

  test("l'altération est à gauche de la tête, à la même hauteur", () {
    final layout = layoutNote(
      const Pitch(DiatonicStep.f, 4, accidental: Accidental.sharp),
    );
    final head = glyphs(layout, Glyph.noteheadWhole).single;
    final sharp = glyphs(layout, Glyph.accidentalSharp).single;
    expect(sharp.y, head.y);
    expect(sharp.bounds.right, lessThan(head.x));
    expect(
      sharp.bounds.left,
      greaterThan(glyphs(layout, Glyph.gClef).single.bounds.right),
    );
  });

  group('grande portée', () {
    final layout = layoutSystem(
      System([
        StaffGroup.grand(
          lower: const [
            Measure([Note(Pitch(DiatonicStep.c, 3))]),
          ],
        ),
      ]),
    );

    test('deux portées séparées de staffDistance', () {
      final staffLines = layout.commands.whereType<LineCommand>().where(
        (c) => c.thickness == EngravingDefaults.staffLineThickness,
      );
      expect(staffLines.map((l) => l.y1), [0, 1, 2, 3, 4, 10, 11, 12, 13, 14]);
    });

    test('barre initiale sur toute la hauteur du groupe', () {
      final barline = layout.commands.whereType<LineCommand>().singleWhere(
        (c) => c.thickness == EngravingDefaults.thinBarlineThickness,
      );
      expect(barline.y1, 0);
      expect(barline.y2, 14);
    });

    test('accolade étirée sur le groupe, à gauche de la barre', () {
      final brace = glyphs(layout, Glyph.brace).single.bounds;
      expect(brace.top, closeTo(0, 1e-9));
      expect(brace.bottom, closeTo(14, 1e-9));
      expect(brace.right, lessThan(0));
    });

    test('la note est sur la portée du bas', () {
      final head = glyphs(layout, Glyph.noteheadWhole).single;
      expect(head.y, 10 + 2.5);
    });

    test("l'encombrement contient l'accolade et la marge", () {
      final brace = glyphs(layout, Glyph.brace).single.bounds;
      expect(layout.bounds.left, brace.left - 1);
    });
  });

  test('reserveAbove et reserveBelow fixent la hauteur minimale', () {
    final low = layoutSystem(
      parse('L:1/1\nK:C\nC\n'),
      options: const LayoutOptions(reserveAbove: 3, reserveBelow: 3),
    );
    final high = layoutSystem(
      parse('L:1/1\nK:C\na\n'),
      options: const LayoutOptions(reserveAbove: 3, reserveBelow: 3),
    );
    expect(low.bounds.top, high.bounds.top);
    expect(low.bounds.bottom, high.bounds.bottom);
  });

  group('hampes', () {
    LineCommand stem(SystemLayout layout) => layout.commands
        .whereType<LineCommand>()
        .singleWhere((c) => c.thickness == EngravingDefaults.stemThickness);

    test('sous la ligne du milieu : vers le haut, à droite de la tête', () {
      final layout = layoutSystem(parse('L:1/4\nK:C\nG\n'));
      final head = glyphs(layout, Glyph.noteheadBlack).single;
      final line = stem(layout);
      expect(line.x1, closeTo(head.bounds.right, 0.1));
      expect(line.y2, lessThan(line.y1));
      expect(line.y1 - line.y2, closeTo(3.5 - 0.168, 1e-9));
    });

    test('sur la ligne du milieu : vers le bas, à gauche de la tête', () {
      final layout = layoutSystem(parse('L:1/2\nK:C\nB\n'));
      final head = glyphs(layout, Glyph.noteheadHalf).single;
      final line = stem(layout);
      expect(line.x1, closeTo(head.bounds.left, 0.1));
      expect(line.y2, greaterThan(line.y1));
    });

    test('loin de la portée : la hampe rejoint la ligne du milieu', () {
      final line = stem(layoutSystem(parse("L:1/4\nK:C\nc'\n")));
      // Do6 : deux lignes supplémentaires au-dessus, hampe vers le bas
      // jusqu'à la 3e ligne (y = 2).
      expect(line.y2, 2);
    });

    test('pas de hampe sur une ronde', () {
      final layout = layoutSystem(parse('L:1/1\nK:C\nG\n'));
      expect(
        layout.commands.whereType<LineCommand>().where(
          (c) => c.thickness == EngravingDefaults.stemThickness,
        ),
        isEmpty,
      );
    });
  });

  group('armure', () {
    List<double> sharps(SystemLayout layout) =>
        glyphs(layout, Glyph.accidentalSharp).map((g) => g.y).toList();
    List<double> flats(SystemLayout layout) =>
        glyphs(layout, Glyph.accidentalFlat).map((g) => g.y).toList();

    // y = 4 - position / 2 : la ligne du haut est à y = 0.
    test('clé de sol : fa#5, do#5, sol#5', () {
      expect(sharps(layoutSystem(parse('K:A\n'))), [0, 1.5, -0.5]);
    });

    test('clé de sol : sib4, mib5, lab4', () {
      expect(flats(layoutSystem(parse('K:Eb\n'))), [2, 0.5, 2.5]);
    });

    test('clé de fa : mêmes notes, deux octaves plus bas', () {
      expect(sharps(layoutSystem(parse('K:A clef=bass\n'))), [1, 2.5, 0.5]);
      expect(flats(layoutSystem(parse('K:Eb clef=bass\n'))), [3, 1.5, 3.5]);
    });

    test("clé d'ut 4e ligne : les dièses commencent en bas", () {
      // fa3 sur la 2e ligne (position 2), puis do4 (6), sol3 (3).
      expect(sharps(layoutSystem(parse('K:A clef=tenor\n'))), [3, 1, 2.5]);
    });

    test('les altérations se suivent de gauche à droite, après la clé', () {
      final layout = layoutSystem(parse('K:C#\n'));
      final xs = glyphs(layout, Glyph.accidentalSharp).map((g) => g.x).toList();
      expect(xs, hasLength(7));
      expect(xs, orderedEquals([...xs]..sort()));
      expect(
        glyphs(layout, Glyph.accidentalSharp).first.bounds.left,
        greaterThan(glyphs(layout, Glyph.gClef).single.bounds.right),
      );
    });
  });

  test('chiffrage : haut sur la 4e ligne, bas sur la 2e', () {
    final layout = layoutSystem(parse('M:3/4\nK:C\n'));
    expect(glyphs(layout, Glyph.timeSig3).single.y, 1);
    expect(glyphs(layout, Glyph.timeSig4).single.y, 3);
  });

  test('chiffrage à deux chiffres : centré au-dessus du chiffre du bas', () {
    final layout = layoutSystem(parse('M:12/8\nK:C\n'));
    final top = [
      ...glyphs(layout, Glyph.timeSig1),
      ...glyphs(layout, Glyph.timeSig2),
    ].map((g) => g.bounds).reduce((a, b) => a.union(b));
    final bottom = glyphs(layout, Glyph.timeSig8).single.bounds;
    expect(
      (top.left + top.right) / 2,
      closeTo((bottom.left + bottom.right) / 2, 1e-9),
    );
  });

  group('colonnes temporelles', () {
    final layout = layoutSystem(
      parse(
        '%%score {RH LH}\nM:2/4\nL:1/4\nK:C\n'
        'V:RH\nc2 | ^c d |]\n'
        'V:LH clef=bass\nC, D, | E,2 |]\n',
      ),
    );
    List<double> heads(Glyph glyph) =>
        glyphs(layout, glyph).map((g) => g.x).toList();

    test('les notes qui commencent ensemble sont alignées', () {
      final black = heads(Glyph.noteheadBlack);
      final half = heads(Glyph.noteheadHalf);
      // RH : c2 (blanche), puis ^c d. LH : C, D, puis E,2 (blanche).
      expect(half[0], black[2]); // temps 1 : c2 et C,
      expect(black[0], half[1]); // mesure 2 : ^c et E,2
    });

    test("l'altération pousse la colonne entière, sur les deux portées", () {
      final sharp = glyphs(layout, Glyph.accidentalSharp).single.bounds;
      final barline = layout.commands.whereType<LineCommand>().firstWhere(
        (c) => c.y2 == 14 && c.x1 > 1,
      );
      // Une barre, un interligne, l'altération, puis les têtes alignées.
      expect(sharp.left, closeTo(barline.x1 + barline.thickness / 2 + 1, 1e-9));
      expect(heads(Glyph.noteheadHalf)[1], heads(Glyph.noteheadBlack)[0]);
    });

    test('les barres traversent la grande portée', () {
      final barlines = layout.commands.whereType<LineCommand>().where(
        (c) => c.x1 == c.x2 && c.y1 == 0 && c.y2 == 14,
      );
      // Barre initiale, barre simple, barre finale (fine + épaisse).
      expect(barlines, hasLength(4));
    });

    test('la portée finit sur la barre finale', () {
      final thick = layout.commands.whereType<LineCommand>().singleWhere(
        (c) => c.thickness == EngravingDefaults.thickBarlineThickness,
      );
      final staffLine = layout.commands.whereType<LineCommand>().firstWhere(
        (c) => c.thickness == EngravingDefaults.staffLineThickness,
      );
      expect(thick.x1 + thick.thickness / 2, staffLine.x2);
    });
  });

  test('la place suit la durée : √2 de plus à chaque doublement', () {
    final layout = layoutSystem(parse('L:1/4\nK:C\nC4 D2 E F\n'));
    final heads = layout.commands
        .whereType<GlyphCommand>()
        .where((c) => c.glyph.name.startsWith('notehead'))
        .map((c) => c.x)
        .toList();
    final whole = heads[1] - heads[0];
    final half = heads[2] - heads[1];
    final quarter = heads[3] - heads[2];
    expect(quarter, 2.75);
    expect(half / quarter, closeTo(math.sqrt2, 1e-9));
    expect(whole / half, closeTo(math.sqrt2, 1e-9));
  });

  test('chaque note désigne son événement', () {
    final layout = layoutSystem(parse('M:2/4\nL:1/4\nK:C\n^C D | E2 |\n'));
    final tagged = layout.commands.where((c) => c.event != null);
    expect(tagged.map((c) => c.event).toSet(), {
      const EventRef(staff: 0, measure: 0, event: 0),
      const EventRef(staff: 0, measure: 0, event: 1),
      const EventRef(staff: 0, measure: 1, event: 0),
    });
    // Do4 : tête, dièse et hampe, pas la ligne supplémentaire.
    expect(
      tagged.where(
        (c) => c.event == const EventRef(staff: 0, measure: 0, event: 0),
      ),
      hasLength(3),
    );
  });
}
