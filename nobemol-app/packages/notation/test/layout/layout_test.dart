import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

void main() {
  SystemLayout layoutNote(Pitch pitch, {Clef clef = Clef.treble}) =>
      layoutSystem(System.single(Staff(clef: clef, notes: [Note(pitch)])));

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
        StaffGroup.grand(lower: const [Note(Pitch(DiatonicStep.c, 3))]),
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
      System.single(
        const Staff(clef: Clef.treble, notes: [Note(Pitch(DiatonicStep.c, 4))]),
      ),
      options: const LayoutOptions(reserveAbove: 3, reserveBelow: 3),
    );
    final high = layoutSystem(
      System.single(
        const Staff(clef: Clef.treble, notes: [Note(Pitch(DiatonicStep.a, 5))]),
      ),
      options: const LayoutOptions(reserveAbove: 3, reserveBelow: 3),
    );
    expect(low.bounds.top, high.bounds.top);
    expect(low.bounds.bottom, high.bounds.bottom);
  });
}
