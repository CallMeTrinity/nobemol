import 'dart:math' as math;

import 'package:notation/src/layout/draw_list.dart';
import 'package:notation/src/layout/glyph.g.dart';
import 'package:notation/src/model/clef.dart';
import 'package:notation/src/model/pitch.dart';
import 'package:notation/src/model/system.dart';

/// Réglages du layout, en interlignes.
class LayoutOptions {
  /// Crée des réglages.
  const new({
    this.staffDistance = 6,
    this.margin = 1,
    this.reserveAbove = 0,
    this.reserveBelow = 0,
  });

  /// Distance entre la ligne du bas d'une portée et la ligne du haut de la
  /// suivante.
  final double staffDistance;

  /// Marge autour du contenu.
  final double margin;

  /// Hauteur toujours réservée au-dessus de la première portée, même sans
  /// note. Garde la portée immobile quand les notes changent.
  final double reserveAbove;

  /// Hauteur toujours réservée sous la dernière portée.
  final double reserveBelow;
}

/// Résultat du layout : la liste de dessin et son encombrement.
///
/// Origine : début de la ligne du haut de la première portée.
class SystemLayout {
  /// Crée un résultat.
  const new({required this.commands, required this.bounds});

  /// Éléments à dessiner.
  final List<DrawCommand> commands;

  /// Rectangle à afficher, marge comprise.
  final Box bounds;
}

/// Distance entre le début de la portée et la clé.
const _clefX = 0.75;

/// Distance entre la clé la plus large et la première tête de note. Laisse
/// la place d'une altération.
const _clefToNote = 3.0;

/// Distance entre deux notes successives, en attendant l'espacement
/// rythmique.
const _noteAdvance = 4.0;

/// Distance entre la dernière tête de note et la fin de la portée.
const _trailing = 3.0;

/// Distance entre une altération et sa tête de note.
const _accidentalGap = 0.25;

/// Distance entre l'accolade et la barre initiale.
const _braceGap = 0.25;

/// Hauteur d'une portée de 5 lignes.
const _staffHeight = 4.0;

/// Calcule la liste de dessin de [system].
SystemLayout layoutSystem(
  System system, {
  LayoutOptions options = const LayoutOptions(),
}) {
  final commands = <DrawCommand>[];
  final staves = system.staves.toList();

  final clefWidth = staves
      .map((staff) => _width(_clefGlyph(staff.clef)))
      .fold<double>(0, math.max);
  final noteX = _clefX + clefWidth + _clefToNote;
  final columns = staves.map((staff) => staff.notes.length).fold(1, math.max);
  final end =
      noteX +
      (columns - 1) * _noteAdvance +
      _width(Glyph.noteheadWhole) +
      _trailing;

  var top = 0.0;
  for (final group in system.groups) {
    final groupTop = top;
    for (final staff in group.staves) {
      _layoutStaff(commands, staff, top: top, noteX: noteX, end: end);
      top += _staffHeight + options.staffDistance;
    }
    final groupBottom = top - options.staffDistance;
    if (group.staves.length > 1) {
      _layoutGroupStart(commands, group, groupTop, groupBottom);
    }
  }
  final systemBottom = top - options.staffDistance;

  final reserved = Box(
    0,
    -options.reserveAbove,
    end,
    systemBottom + options.reserveBelow,
  );
  final bounds = commands
      .map((command) => command.bounds)
      .fold(reserved, (box, other) => box.union(other))
      .inflate(options.margin);

  return SystemLayout(commands: commands, bounds: bounds);
}

void _layoutStaff(
  List<DrawCommand> commands,
  Staff staff, {
  required double top,
  required double noteX,
  required double end,
}) {
  for (var line = 0; line < 5; line++) {
    commands.add(
      LineCommand(
        0,
        top + line,
        end,
        top + line,
        EngravingDefaults.staffLineThickness,
      ),
    );
  }

  final clef = staff.clef;
  commands.add(
    GlyphCommand(_clefGlyph(clef), _clefX, _y(top, (clef.line - 1) * 2)),
  );

  for (final (index, note) in staff.notes.indexed) {
    _layoutNote(
      commands,
      note,
      clef,
      top: top,
      x: noteX + index * _noteAdvance,
    );
  }
}

void _layoutNote(
  List<DrawCommand> commands,
  Note note,
  Clef clef, {
  required double top,
  required double x,
}) {
  final position = clef.staffPosition(note.pitch);
  final y = _y(top, position);
  final accidental = note.pitch.accidental;

  // Lignes supplémentaires, raccourcies à gauche devant une altération.
  const extension = EngravingDefaults.legerLineExtension;
  final left = x - (accidental == null ? extension : extension / 2);
  final right = x + _width(Glyph.noteheadWhole) + extension;
  final ledgers = [
    for (var p = -2; p >= position; p -= 2) p,
    for (var p = 10; p <= position; p += 2) p,
  ];
  for (final p in ledgers) {
    final ledgerY = _y(top, p);
    commands.add(
      LineCommand(
        left,
        ledgerY,
        right,
        ledgerY,
        EngravingDefaults.legerLineThickness,
      ),
    );
  }

  if (accidental != null) {
    final glyph = _accidentalGlyph(accidental);
    commands.add(GlyphCommand(glyph, x - _accidentalGap - _width(glyph), y));
  }
  commands.add(GlyphCommand(Glyph.noteheadWhole, x, y));
}

/// Barre initiale et signe de regroupement.
void _layoutGroupStart(
  List<DrawCommand> commands,
  StaffGroup group,
  double top,
  double bottom,
) {
  const thickness = EngravingDefaults.thinBarlineThickness;
  commands.add(
    LineCommand(thickness / 2, top, thickness / 2, bottom, thickness),
  );

  switch (group.symbol) {
    case GroupSymbol.none:
      break;
    case GroupSymbol.brace:
      // Le glyphe mesure une portée de haut : on l'agrandit au groupe.
      const glyph = Glyph.brace;
      final scale = (bottom - top) / _height(glyph);
      commands.add(
        GlyphCommand(
          glyph,
          -_braceGap - glyph.bBoxNE.$1 * scale,
          bottom + glyph.bBoxSW.$2 * scale,
          scaleX: scale,
          scaleY: scale,
        ),
      );
  }
}

/// Ordonnée de la [position] sur la portée dont la ligne du haut est à [top].
double _y(double top, int position) => top + _staffHeight - position / 2;

double _width(Glyph glyph) => glyph.bBoxNE.$1 - glyph.bBoxSW.$1;

double _height(Glyph glyph) => glyph.bBoxNE.$2 - glyph.bBoxSW.$2;

Glyph _clefGlyph(Clef clef) => switch (clef.sign) {
  ClefSign.g => Glyph.gClef,
  ClefSign.f => Glyph.fClef,
  ClefSign.c => Glyph.cClef,
};

Glyph _accidentalGlyph(Accidental accidental) => switch (accidental) {
  Accidental.doubleFlat => Glyph.accidentalDoubleFlat,
  Accidental.flat => Glyph.accidentalFlat,
  Accidental.natural => Glyph.accidentalNatural,
  Accidental.sharp => Glyph.accidentalSharp,
  Accidental.doubleSharp => Glyph.accidentalDoubleSharp,
};
