import 'dart:math' as math;

import 'package:notation/src/layout/draw_list.dart';
import 'package:notation/src/layout/glyph.g.dart';
import 'package:notation/src/model/clef.dart';
import 'package:notation/src/model/fraction.dart';
import 'package:notation/src/model/key_signature.dart';
import 'package:notation/src/model/pitch.dart';
import 'package:notation/src/model/system.dart';
import 'package:notation/src/model/time_signature.dart';

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

/// Distance entre la clé, l'armure et le chiffrage.
const _headerGap = 1.0;

/// Distance entre deux altérations d'une armure.
const _keyAccidentalGap = 0.15;

/// Distance entre la fin de l'en-tête et la première tête de note. Laisse
/// la place d'une altération, pour que la note ne bouge pas quand une
/// altération apparaît.
const _headerToNote = 3.0;

/// Place d'une noire. Chaque doublement de durée multiplie la place par √2
/// (blanche : 3,9, ronde : 5,5).
const _quarterSpace = 2.75;

/// Écart minimal entre deux colonnes : tête de la première, altération de
/// la seconde.
const _noteGap = 0.5;

/// Écart minimal entre une tête de note et la barre qui suit.
const _noteToBarline = 1.0;

/// Distance entre une barre et la note qui suit (son altération comprise).
const _barlineToNote = 1.0;

/// Distance entre la dernière tête de note et la fin de la portée, sans
/// barre finale.
const _trailing = 3.0;

/// Distance entre une altération et sa tête de note.
const _accidentalGap = 0.25;

/// Distance entre l'accolade et la barre initiale.
const _braceGap = 0.25;

/// Hauteur d'une portée de 5 lignes.
const _staffHeight = 4.0;

/// Position de la ligne du milieu.
const _middleLine = 4;

/// Longueur d'une hampe : une octave.
const _stemLength = 3.5;

/// Calcule la liste de dessin de [system].
///
/// Le placement horizontal est commun à tout le système : deux événements
/// qui commencent au même instant sont alignés, quelle que soit leur
/// portée.
SystemLayout layoutSystem(
  System system, {
  LayoutOptions options = const LayoutOptions(),
}) {
  final commands = <DrawCommand>[];
  final staves = system.staves.toList();
  final header = _Header(staves);
  final timeline = _Timeline(staves, start: header.end);

  var top = 0.0;
  var staffIndex = 0;
  for (final group in system.groups) {
    final groupTop = top;
    final staffTops = <double>[];
    for (final staff in group.staves) {
      staffTops.add(top);
      _layoutStaff(
        commands,
        staff,
        staffIndex++,
        header: header,
        timeline: timeline,
        top: top,
      );
      top += _staffHeight + options.staffDistance;
    }
    final groupBottom = top - options.staffDistance;
    if (group.staves.length > 1) {
      _layoutGroupStart(commands, group, groupTop, groupBottom);
    }
    _layoutBarlines(commands, group, timeline, groupTop, groupBottom);
  }
  final systemBottom = top - options.staffDistance;

  final reserved = Box(
    0,
    -options.reserveAbove,
    timeline.end,
    systemBottom + options.reserveBelow,
  );
  final bounds = commands
      .map((command) => command.bounds)
      .fold(reserved, (box, other) => box.union(other))
      .inflate(options.margin);

  return SystemLayout(commands: commands, bounds: bounds);
}

/// Début de chaque portée : clé, armure, chiffrage. Chaque élément occupe
/// une colonne commune à toutes les portées, de la largeur du plus large.
class _Header {
  new(List<Staff> staves) {
    double widest(double Function(Staff staff) width) =>
        staves.map(width).fold(0, math.max);

    var x = _clefX + widest((staff) => _width(_clefGlyph(staff.clef)));
    final keyWidth = widest((staff) => _keySignatureWidth(staff.key));
    if (keyWidth > 0) {
      keyX = x + _headerGap;
      x = keyX + keyWidth;
    }
    timeWidth = widest((staff) => _timeSignatureWidth(staff.time));
    if (timeWidth > 0) {
      timeX = x + _headerGap;
      x = timeX + timeWidth;
    }
    end = x;
  }

  /// Début de l'armure.
  double keyX = 0;

  /// Début et largeur du chiffrage.
  double timeX = 0;
  double timeWidth = 0;

  /// Fin de l'en-tête.
  late final double end;
}

/// Instants où commence un événement, sur toutes les portées.
class _Column {
  new(this.time);

  final Fraction time;

  /// Place prise à gauche de la tête (altérations).
  double left = 0;

  /// Place prise à droite du début de la tête.
  double right = 0;

  /// Abscisse des têtes de note.
  double x = 0;
}

/// Placement horizontal du système : une abscisse par instant (colonnes
/// d'événements et barres de mesure).
class _Timeline {
  new(List<Staff> staves, {required double start}) {
    final columns = <Fraction, _Column>{};
    final barlines = <Fraction>{};

    for (final staff in staves) {
      var time = Fraction.zero;
      for (final measure in staff.measures) {
        for (final event in measure.events) {
          final column = columns[time] ??= _Column(time);
          if (event case Note(:final pitch, :final value)) {
            final accidental = pitch.accidental;
            if (accidental != null) {
              column.left = math.max(
                column.left,
                _width(_accidentalGlyph(accidental)) + _accidentalGap,
              );
            }
            column.right = math.max(column.right, _width(_notehead(value)));
          }
          time += event.duration;
        }
        if (measure.barline != null) barlines.add(time);
      }
    }

    final sortedColumns = columns.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    // Parcours dans le temps. À un même instant, la barre passe avant la
    // note qui ouvre la mesure suivante.
    _Column? previous;
    double? previousBarline;
    var x = start;
    var columnIndex = 0;
    final sortedBarlines = barlines.toList()..sort();
    var barlineIndex = 0;

    while (columnIndex < sortedColumns.length ||
        barlineIndex < sortedBarlines.length) {
      final barlineTime = barlineIndex < sortedBarlines.length
          ? sortedBarlines[barlineIndex]
          : null;
      final column = columnIndex < sortedColumns.length
          ? sortedColumns[columnIndex]
          : null;

      if (barlineTime != null &&
          (column == null || barlineTime.compareTo(column.time) <= 0)) {
        x = previous == null
            ? x + _headerToNote
            : previous.x +
                  math.max(
                    _space(barlineTime - previous.time),
                    previous.right + _noteToBarline,
                  );
        _barlineX[barlineTime] = x;
        previous = null;
        previousBarline = x;
        barlineIndex++;
        continue;
      }

      column!.x = switch ((previous, previousBarline)) {
        (final previous?, _) =>
          previous.x +
              math.max(
                _space(column.time - previous.time),
                previous.right + _noteGap + column.left,
              ),
        (null, final barline?) => barline + _barlineToNote + column.left,
        (null, null) => x + math.max(_headerToNote, 1 + column.left),
      };
      _columnX[column.time] = column.x;
      previous = column;
      previousBarline = null;
      columnIndex++;
    }

    end = switch ((previous, previousBarline)) {
      (final previous?, _) => previous.x + previous.right + _trailing,
      (null, final barline?) => barline,
      // Portées vides : la place d'une ronde.
      (null, null) =>
        start + _headerToNote + _width(Glyph.noteheadWhole) + _trailing,
    };
  }

  final _columnX = <Fraction, double>{};
  final _barlineX = <Fraction, double>{};

  /// Fin des portées : la dernière barre, ou un peu après la dernière note.
  late final double end;

  /// Abscisse des têtes de note qui commencent à [time].
  double columnX(Fraction time) => _columnX[time]!;

  /// Bord droit de la barre à [time].
  double barlineX(Fraction time) => _barlineX[time]!;
}

/// Place qui suit une note de durée [duration] : √2 de plus à chaque
/// doublement.
double _space(Fraction duration) =>
    _quarterSpace *
    math.sqrt(duration.toDouble() / NoteValue.quarter.duration.toDouble());

void _layoutStaff(
  List<DrawCommand> commands,
  Staff staff,
  int staffIndex, {
  required _Header header,
  required _Timeline timeline,
  required double top,
}) {
  for (var line = 0; line < 5; line++) {
    commands.add(
      LineCommand(
        0,
        top + line,
        timeline.end,
        top + line,
        EngravingDefaults.staffLineThickness,
      ),
    );
  }

  final clef = staff.clef;
  commands.add(
    GlyphCommand(_clefGlyph(clef), _clefX, _y(top, (clef.line - 1) * 2)),
  );
  _layoutKeySignature(commands, staff.key, clef, x: header.keyX, top: top);
  if (staff.time case final time?) {
    _layoutTimeSignature(commands, time, header: header, top: top);
  }

  var time = Fraction.zero;
  for (final (measureIndex, measure) in staff.measures.indexed) {
    for (final (eventIndex, event) in measure.events.indexed) {
      final ref = EventRef(
        staff: staffIndex,
        measure: measureIndex,
        event: eventIndex,
      );
      switch (event) {
        case Note():
          _layoutNote(
            commands,
            event,
            clef,
            ref,
            top: top,
            x: timeline.columnX(time),
          );
      }
      time += event.duration;
    }
  }
}

void _layoutKeySignature(
  List<DrawCommand> commands,
  KeySignature key,
  Clef clef, {
  required double x,
  required double top,
}) {
  final accidental = key.accidental;
  if (accidental == null) return;

  final glyph = _accidentalGlyph(accidental);
  final low = _keySignatureLow(clef, accidental);
  var left = x;
  for (final step in key.steps) {
    // Chaque degré a une seule position dans la fenêtre de 7 positions.
    final position = low + (step.index - clef.pitchAt(low).step.index) % 7;
    commands.add(GlyphCommand(glyph, left, _y(top, position)));
    left += _width(glyph) + _keyAccidentalGap;
  }
}

/// Plus basse position de l'armure : chaque altération va dans la fenêtre
/// des 7 positions qui commence là.
///
/// En clé de sol, les dièses vont du la4 au sol5 (positions 3 à 9) et les
/// bémols du fa4 au mi5 (1 à 7). Les autres clés décalent la fenêtre pour
/// garder les mêmes notes. Exception : en clé d'ut 4e ligne, les dièses
/// sortiraient de la portée, on les descend d'une tierce.
int _keySignatureLow(Clef clef, Accidental accidental) {
  // Décalage de la clé par rapport à la clé de sol, ramené entre -3 et 3.
  final shift =
      (clef.staffPosition(const Pitch(DiatonicStep.g, 4)) - 2 + 3) % 7 - 3;
  if (accidental == Accidental.flat) return 1 + shift;
  final low = 3 + shift;
  return low + 6 > 9 ? low - 2 : low;
}

double _keySignatureWidth(KeySignature key) {
  final accidental = key.accidental;
  if (accidental == null) return 0;
  final count = key.steps.length;
  return count * _width(_accidentalGlyph(accidental)) +
      (count - 1) * _keyAccidentalGap;
}

void _layoutTimeSignature(
  List<DrawCommand> commands,
  TimeSignature time, {
  required _Header header,
  required double top,
}) {
  // Les chiffres sont centrés sur leur ligne de base : le haut sur la
  // 4e ligne, le bas sur la 2e.
  void number(int value, int position) {
    final glyphs = _digits(value);
    var left = header.timeX + (header.timeWidth - _digitsWidth(glyphs)) / 2;
    for (final glyph in glyphs) {
      commands.add(
        GlyphCommand(glyph, left - glyph.bBoxSW.$1, _y(top, position)),
      );
      left += _width(glyph);
    }
  }

  number(time.beats, 6);
  number(time.beatUnit, 2);
}

double _timeSignatureWidth(TimeSignature? time) => time == null
    ? 0
    : math.max(
        _digitsWidth(_digits(time.beats)),
        _digitsWidth(_digits(time.beatUnit)),
      );

List<Glyph> _digits(int value) => [
  for (final digit in '$value'.codeUnits)
    Glyph.values[Glyph.timeSig0.index + digit - 0x30],
];

double _digitsWidth(List<Glyph> glyphs) =>
    glyphs.fold(0, (width, glyph) => width + _width(glyph));

void _layoutNote(
  List<DrawCommand> commands,
  Note note,
  Clef clef,
  EventRef ref, {
  required double top,
  required double x,
}) {
  final position = clef.staffPosition(note.pitch);
  final y = _y(top, position);
  final accidental = note.pitch.accidental;
  final head = _notehead(note.value);

  // Lignes supplémentaires, raccourcies à gauche devant une altération.
  const extension = EngravingDefaults.legerLineExtension;
  final left = x - (accidental == null ? extension : extension / 2);
  final right = x + _width(head) + extension;
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
    commands.add(
      GlyphCommand(glyph, x - _accidentalGap - _width(glyph), y, event: ref),
    );
  }
  commands.add(GlyphCommand(head, x, y, event: ref));
  if (note.value != NoteValue.whole) {
    _layoutStem(commands, head, ref, x: x, y: y, position: position);
  }
}

/// Hampe : vers le haut sous la ligne du milieu, vers le bas à partir
/// d'elle. Une octave de long, et jamais moins que jusqu'à la ligne du
/// milieu.
void _layoutStem(
  List<DrawCommand> commands,
  Glyph head,
  EventRef ref, {
  required double x,
  required double y,
  required int position,
}) {
  const thickness = EngravingDefaults.stemThickness;
  final length = math.max(_stemLength, (position - _middleLine).abs() / 2);
  final up = position < _middleLine;

  // Ancres SMuFL : axe y vers le haut, d'où le changement de signe.
  final (anchorX, anchorY) = up ? head.stemUpSE! : head.stemDownNW!;
  final stemX = x + anchorX + (up ? -thickness / 2 : thickness / 2);
  commands.add(
    LineCommand(
      stemX,
      y - anchorY,
      stemX,
      up ? y - length : y + length,
      thickness,
      event: ref,
    ),
  );
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

/// Barres de mesure du groupe, d'un trait sur toute sa hauteur.
void _layoutBarlines(
  List<DrawCommand> commands,
  StaffGroup group,
  _Timeline timeline,
  double top,
  double bottom,
) {
  // Une barre par instant, prise sur la première portée qui en écrit une.
  final barlines = <Fraction, Barline>{};
  for (final staff in group.staves) {
    var time = Fraction.zero;
    for (final measure in staff.measures) {
      time += measure.duration;
      if (measure.barline case final barline?) {
        barlines.putIfAbsent(time, () => barline);
      }
    }
  }

  void line(double right, double thickness) => commands.add(
    LineCommand(
      right - thickness / 2,
      top,
      right - thickness / 2,
      bottom,
      thickness,
    ),
  );

  const thin = EngravingDefaults.thinBarlineThickness;
  const thick = EngravingDefaults.thickBarlineThickness;
  for (final MapEntry(key: time, value: barline) in barlines.entries) {
    final x = timeline.barlineX(time);
    switch (barline) {
      case Barline.regular:
        line(x, thin);
      case Barline.lightLight:
        line(x, thin);
        line(x - thin - EngravingDefaults.barlineSeparation, thin);
      case Barline.lightHeavy:
        line(x, thick);
        line(x - thick - EngravingDefaults.thinThickBarlineSeparation, thin);
    }
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

Glyph _notehead(NoteValue value) => switch (value) {
  NoteValue.whole => Glyph.noteheadWhole,
  NoteValue.half => Glyph.noteheadHalf,
  NoteValue.quarter => Glyph.noteheadBlack,
};

Glyph _accidentalGlyph(Accidental accidental) => switch (accidental) {
  Accidental.doubleFlat => Glyph.accidentalDoubleFlat,
  Accidental.flat => Glyph.accidentalFlat,
  Accidental.natural => Glyph.accidentalNatural,
  Accidental.sharp => Glyph.accidentalSharp,
  Accidental.doubleSharp => Glyph.accidentalDoubleSharp,
};
