import 'dart:math' as math;

import 'package:notation/src/layout/draw_list.dart';
import 'package:notation/src/layout/glyph.g.dart';
import 'package:notation/src/layout/text_font.g.dart';
import 'package:notation/src/model/clef.dart';
import 'package:notation/src/model/decoration.dart';
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
  const new({
    required this.commands,
    required this.bounds,
    this.heads = const {},
  });

  /// Éléments à dessiner.
  final List<DrawCommand> commands;

  /// Rectangle à afficher, marge comprise.
  final Box bounds;

  /// Tête de chaque note, altération comprise, ou glyphe de chaque silence.
  /// Sans hampe ni crochet : c'est là que se pose un halo.
  final Map<EventRef, Box> heads;
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

/// Distance entre une tête (ou un silence) et son point.
const _dotGap = 0.3;

/// Dénivelé maximal d'une ligature, d'un bout à l'autre.
const _beamMaxRise = 1.0;

/// Pente maximale d'une ligature : un groupe serré reste presque à plat.
const _beamMaxSlope = 0.25;

/// Longueur d'un tronçon de ligature (double croche isolée dans un groupe).
const _beamStub = 1.0;

/// Distance entre le centre d'une tête et les bouts de sa liaison.
const _tieOffset = 0.5;

/// Distance entre un accent et la tête ou la portée.
const _accentGap = 0.5;

/// Distance entre un point d'orgue et la portée ou ce qui dépasse au-dessus
/// de sa note.
const _fermataGap = 0.75;

/// Distance entre une ligne de signes (textes au-dessus, nuances
/// au-dessous) et ce qui dépasse de la portée.
const _lineGap = 0.75;

/// Taille du em des textes : leur hauteur d'x est proche de celle des
/// nuances.
const _textSize = 2.0;

/// Distance entre une nuance et le texte qui la suit.
const _textGap = 0.5;

/// Ouverture d'un soufflet.
const _hairpinOpening = 1.0;

/// Hauteur du milieu d'un soufflet au-dessus de la ligne de base des
/// nuances : à mi-hauteur des lettres sans hampe.
const _hairpinRise = 0.55;

/// Distance entre un soufflet et les signes de ses deux notes.
const _hairpinGap = 0.5;

/// Longueur minimale d'un soufflet.
const _hairpinMinLength = 1.0;

/// Taille du em des noms sous les notes.
const _labelSize = 1.15;

/// Distance minimale entre la ligne du bas de la portée et la ligne de base
/// des noms. Ils restent alignés d'une note à l'autre.
const _labelDrop = 3.6;

/// Calcule la liste de dessin de [system].
///
/// Le placement horizontal est commun à tout le système : deux événements
/// qui commencent au même instant sont alignés, quelle que soit leur
/// portée.
///
/// [labels] écrit un nom sous certaines notes, sur une ligne commune à
/// chaque portée, sous tout ce qui dépasse en bas.
SystemLayout layoutSystem(
  System system, {
  LayoutOptions options = const LayoutOptions(),
  Map<EventRef, String> labels = const {},
}) {
  final commands = <DrawCommand>[];
  final heads = <EventRef, Box>{};
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
        heads,
        staff,
        staffIndex++,
        header: header,
        timeline: timeline,
        labels: labels,
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

  return SystemLayout(commands: commands, bounds: bounds, heads: heads);
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
  new(List<Staff> staves, {required this.start}) {
    final columns = <Fraction, _Column>{};
    final barlines = <Fraction>{};

    for (final staff in staves) {
      var time = Fraction.zero;
      for (final measure in staff.measures) {
        Event? previous;
        for (final event in measure.events) {
          final column = columns[time] ??= _Column(time);
          switch (event) {
            case Note(:final pitch):
              final accidental = pitch.accidental;
              if (accidental != null) {
                column.left = math.max(
                  column.left,
                  _width(_accidentalGlyph(accidental)) + _accidentalGap,
                );
              }
              final beamed =
                  event.beamedToNext ||
                  (previous is Note && previous.beamedToNext);
              column.right = math.max(
                column.right,
                _noteRight(event, staff.clef, beamed: beamed),
              );
            case Rest(:final value, :final dotted):
              column.right = math.max(
                column.right,
                _dotRight(_width(_restGlyph(value)), dotted: dotted),
              );
          }
          previous = event;
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

  /// Fin de l'en-tête, début de la première mesure.
  final double start;

  /// Fin des portées : la dernière barre, ou un peu après la dernière note.
  late final double end;

  /// Abscisse des têtes de note qui commencent à [time].
  double columnX(Fraction time) => _columnX[time]!;

  /// Bord droit de la barre à [time].
  double barlineX(Fraction time) => _barlineX[time]!;

  /// Bord gauche d'un élément de largeur [width] centré dans la mesure qui
  /// va de [from] à [to].
  double centered(Fraction from, Fraction to, double width) {
    final left = _barlineX[from] ?? start;
    final right = _barlineX[to] ?? end;
    return (left + right - width) / 2;
  }
}

/// Place prise à droite du début d'une tête : la tête, son point et son
/// crochet, s'il est à droite (hampe vers le haut).
double _noteRight(Note note, Clef clef, {required bool beamed}) {
  final head = _notehead(note.value);
  final right = _dotRight(_width(head), dotted: note.dotted);
  if (note.value.flags == 0 ||
      beamed ||
      !_stemUp(clef.staffPosition(note.pitch))) {
    return right;
  }
  final flag = _flagGlyph(note.value, up: true);
  return math.max(
    right,
    head.stemUpSE!.$1 - EngravingDefaults.stemThickness + _width(flag),
  );
}

/// Place prise par un élément de largeur [width], suivi de son point si
/// [dotted].
double _dotRight(double width, {required bool dotted}) =>
    dotted ? width + _dotGap + _width(Glyph.augmentationDot) : width;

/// Place qui suit une note de durée [duration] : √2 de plus à chaque
/// doublement.
double _space(Fraction duration) =>
    _quarterSpace *
    math.sqrt(duration.toDouble() / NoteValue.quarter.duration.toDouble());

void _layoutStaff(
  List<DrawCommand> commands,
  Map<EventRef, Box> headBoxes,
  Staff staff,
  int staffIndex, {
  required _Header header,
  required _Timeline timeline,
  required Map<EventRef, String> labels,
  required double top,
}) {
  final from = commands.length;
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

  // Têtes de la portée, de gauche à droite, et groupes ligaturés (une
  // note seule forme un groupe d'un élément).
  final heads = <_Head>[];
  final groups = <List<_Head>>[];
  final placed = <_Placed>[];
  var time = Fraction.zero;
  for (final (measureIndex, measure) in staff.measures.indexed) {
    final measureStart = time;
    var beamOpen = false;
    for (final (eventIndex, event) in measure.events.indexed) {
      final ref = EventRef(
        staff: staffIndex,
        measure: measureIndex,
        event: eventIndex,
      );
      final x = timeline.columnX(time);
      switch (event) {
        case Note(:final value):
          final head = _layoutHead(
            commands,
            headBoxes,
            event,
            clef,
            ref,
            top: top,
            x: x,
          );
          heads.add(head);
          placed.add(_Placed(event, ref, head.glyph, x: x, head: head));
          if (beamOpen && value.flags > 0) {
            groups.last.add(head);
          } else {
            groups.add([head]);
          }
          beamOpen = event.beamedToNext && value.flags > 0;
        case Rest(:final value, :final dotted):
          // Silence d'une mesure entière : centré dans la mesure.
          final alone = staff.time != null && measure.events.length == 1;
          final glyph = _restGlyph(value);
          final restX = alone
              ? timeline.centered(
                  measureStart,
                  measureStart + measure.duration,
                  _dotRight(_width(glyph), dotted: dotted),
                )
              : x;
          _layoutRest(commands, headBoxes, event, ref, top: top, x: restX);
          placed.add(_Placed(event, ref, glyph, x: restX));
          beamOpen = false;
      }
      time += event.duration;
    }
  }

  for (final group in groups) {
    if (group.length == 1) {
      if (group.single.note.value != NoteValue.whole) {
        _layoutStem(commands, group.single);
      }
    } else {
      _layoutBeamGroup(commands, group, top: top);
    }
  }

  // Après les hampes : le sens de la hampe fixe le côté de la liaison.
  for (final (index, head) in heads.indexed) {
    if (head.note.tiedToNext && index + 1 < heads.length) {
      _layoutTie(commands, head, heads[index + 1]);
    }
  }

  _layoutDecorations(commands, placed, from: from, start: header.end, top: top);
  _layoutLabels(commands, placed, labels, from: from, top: top);
}

/// Noms sous les notes de la portée : une ligne de base commune, sous tout
/// ce qui dépasse (lignes supplémentaires, hampes, nuances), et jamais plus
/// près de la portée que [_labelDrop].
void _layoutLabels(
  List<DrawCommand> commands,
  List<_Placed> placed,
  Map<EventRef, String> labels, {
  required int from,
  required double top,
}) {
  final named = [
    for (final item in placed)
      if (labels[item.ref] case final text?) (item, text),
  ];
  if (named.isEmpty) return;

  final lowest = commands
      .skip(from)
      .map((command) => command.bounds.bottom)
      .fold(top + _staffHeight, math.max);
  final baseline = math.max(
    top + _staffHeight + _labelDrop,
    lowest + _lineGap + LabelCommand.ascent * _labelSize,
  );
  for (final (item, text) in named) {
    commands.add(
      LabelCommand(
        text,
        item.center,
        baseline,
        size: _labelSize,
        event: item.ref,
      ),
    );
  }
}

/// Note ou silence placé, pour ses décorations.
class _Placed {
  new(this.event, this.ref, this.glyph, {required this.x, this.head});

  final Event event;
  final EventRef ref;

  /// Tête de note ou silence.
  final Glyph glyph;

  /// Origine du glyphe.
  final double x;

  /// Tête de note, `null` pour un silence.
  final _Head? head;

  /// Bords et milieu du glyphe.
  double get left => x + glyph.bBoxSW.$1;
  double get right => x + glyph.bBoxNE.$1;
  double get center => (left + right) / 2;
}

/// Tête de note placée, avec le sens de sa hampe.
class _Head {
  new(
    this.note,
    this.ref, {
    required this.x,
    required this.y,
    required this.position,
  });

  final Note note;
  final EventRef ref;

  /// Abscisse de la tête.
  final double x;

  /// Ordonnée du centre de la tête.
  final double y;

  /// Position sur la portée.
  final int position;

  /// Sens de la hampe : selon la position, sauf dans une ligature, où le
  /// groupe impose le sien.
  late bool up = _stemUp(position);

  Glyph get glyph => _notehead(note.value);

  /// Ancre SMuFL de la hampe sur la tête. Axe y vers le haut.
  (double, double) get _anchor => up ? glyph.stemUpSE! : glyph.stemDownNW!;

  /// Abscisse de l'axe de la hampe.
  double get stemX {
    const thickness = EngravingDefaults.stemThickness;
    return x + _anchor.$1 + (up ? -thickness / 2 : thickness / 2);
  }

  /// Ordonnée du pied de la hampe, sur la tête.
  double get stemStartY => y - _anchor.$2;
}

bool _stemUp(int position) => position < _middleLine;

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

/// Tête, altération, lignes supplémentaires et point d'une note. Les
/// hampes et les liaisons viennent ensuite, groupe par groupe.
_Head _layoutHead(
  List<DrawCommand> commands,
  Map<EventRef, Box> heads,
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

  final headCommand = GlyphCommand(head, x, y, event: ref);
  var headBox = headCommand.bounds;
  if (accidental != null) {
    final glyph = _accidentalGlyph(accidental);
    final command = GlyphCommand(
      glyph,
      x - _accidentalGap - _width(glyph),
      y,
      event: ref,
    );
    commands.add(command);
    headBox = headBox.union(command.bounds);
  }
  commands.add(headCommand);
  heads[ref] = headBox;
  if (note.dotted) {
    // Sur une ligne, le point monte dans l'interligne du dessus.
    final dotPosition = position.isEven ? position + 1 : position;
    commands.add(
      GlyphCommand(
        Glyph.augmentationDot,
        x + _width(head) + _dotGap,
        _y(top, dotPosition),
        event: ref,
      ),
    );
  }
  return _Head(note, ref, x: x, y: y, position: position);
}

/// Silence : la pause pend sous la 4e ligne, la demi-pause est posée sur la
/// 3e, les autres sont centrés sur la 3e. Le point va dans le 3e
/// interligne.
void _layoutRest(
  List<DrawCommand> commands,
  Map<EventRef, Box> heads,
  Rest rest,
  EventRef ref, {
  required double top,
  required double x,
}) {
  final glyph = _restGlyph(rest.value);
  final position = rest.value == NoteValue.whole ? 6 : _middleLine;
  final command = GlyphCommand(glyph, x, _y(top, position), event: ref);
  commands.add(command);
  heads[ref] = command.bounds;
  if (rest.dotted) {
    commands.add(
      GlyphCommand(
        Glyph.augmentationDot,
        x + _width(glyph) + _dotGap,
        _y(top, _middleLine + 1),
        event: ref,
      ),
    );
  }
}

/// Hampe d'une note seule : vers le haut sous la ligne du milieu, vers le
/// bas à partir d'elle. Une octave de long, et jamais moins que jusqu'à la
/// ligne du milieu. Crochet au bout pour une croche ou une double croche.
void _layoutStem(List<DrawCommand> commands, _Head head) {
  const thickness = EngravingDefaults.stemThickness;
  final length = math.max(_stemLength, (head.position - _middleLine).abs() / 2);
  final up = head.up;
  final tip = up ? head.y - length : head.y + length;
  final stemX = head.stemX;
  commands.add(
    LineCommand(stemX, head.stemStartY, stemX, tip, thickness, event: head.ref),
  );

  final value = head.note.value;
  if (value.flags == 0) return;
  // Ancres SMuFL : le coin de la hampe, côté gauche, axe y vers le haut.
  final flag = _flagGlyph(value, up: up);
  final (anchorX, anchorY) = up ? flag.stemUpNW! : flag.stemDownSW!;
  commands.add(
    GlyphCommand(
      flag,
      stemX - thickness / 2 - anchorX,
      tip + anchorY,
      event: head.ref,
    ),
  );
}

/// Groupe de croches et de doubles croches ligaturées.
///
/// Les hampes vont toutes dans le sens de la note la plus éloignée de la
/// ligne du milieu. La ligature suit la pente des notes extrêmes, limitée,
/// et reste à plat si une note intérieure est plus près d'elle que les deux
/// extrêmes. Elle est placée pour que la hampe la plus courte fasse une
/// octave, et que chaque hampe atteigne la ligne du milieu.
void _layoutBeamGroup(
  List<DrawCommand> commands,
  List<_Head> group, {
  required double top,
}) {
  final above = group.map((h) => h.position - _middleLine).reduce(math.max);
  final below = group.map((h) => _middleLine - h.position).reduce(math.max);
  final up = below > above;
  for (final head in group) {
    head.up = up;
  }

  final first = group.first;
  final last = group.last;
  final x0 = first.stemX;
  final width = last.stemX - x0;
  final inner = group.sublist(1, group.length - 1);
  final flat = up
      ? inner.any((h) => h.y < math.min(first.y, last.y))
      : inner.any((h) => h.y > math.max(first.y, last.y));
  final maxRise = math.min(_beamMaxRise, width * _beamMaxSlope);
  final slope = flat
      ? 0.0
      : (last.y - first.y).clamp(-maxRise, maxRise) / width;

  // Ordonnée de la ligature au droit de la hampe de chaque note, si elle
  // passait par 0 en x0. On la décale ensuite d'un seul bloc.
  double rise(_Head head) => slope * (head.stemX - x0);
  final middle = top + _staffHeight - _middleLine / 2;
  final offsets = [
    for (final head in group) ...[
      (up ? head.y - _stemLength : head.y + _stemLength) - rise(head),
      middle - rise(head),
    ],
  ];
  final offset = up ? offsets.reduce(math.min) : offsets.reduce(math.max);
  double beamY(double x) => offset + slope * (x - x0);

  const thickness = EngravingDefaults.stemThickness;
  for (final head in group) {
    commands.add(
      LineCommand(
        head.stemX,
        head.stemStartY,
        head.stemX,
        beamY(head.stemX),
        thickness,
        event: head.ref,
      ),
    );
  }

  // Ligne médiane de la ligature de niveau [level] (0 pour la croche),
  // côté tête par rapport au bout des hampes.
  const beam = EngravingDefaults.beamThickness;
  final inward = up ? 1 : -1;
  void segment(double left, double right, int level) {
    final shift =
        inward * (beam / 2 + level * (beam + EngravingDefaults.beamSpacing));
    commands.add(
      BeamCommand(left, beamY(left) + shift, right, beamY(right) + shift, beam),
    );
  }

  segment(x0 - thickness / 2, last.stemX + thickness / 2, 0);

  // Deuxième ligature sur chaque suite de doubles croches, tronçon pour une
  // double croche isolée : vers la droite en tête de groupe, vers la gauche
  // sinon.
  var index = 0;
  while (index < group.length) {
    if (group[index].note.value.flags < 2) {
      index++;
      continue;
    }
    var end = index;
    while (end + 1 < group.length && group[end + 1].note.value.flags > 1) {
      end++;
    }
    final x = group[index].stemX;
    if (end > index) {
      segment(x - thickness / 2, group[end].stemX + thickness / 2, 1);
    } else {
      final neighbour = index == 0 ? group[1] : group[index - 1];
      final length = math.min(_beamStub, (neighbour.stemX - x).abs() / 2);
      if (index == 0) {
        segment(x - thickness / 2, x + length, 1);
      } else {
        segment(x - length, x + thickness / 2, 1);
      }
    }
    index = end + 1;
  }
}

/// Liaison de prolongation de [from] à [to], du côté opposé à la hampe de
/// [from]. Elle part après le point d'une note pointée.
void _layoutTie(List<DrawCommand> commands, _Head from, _Head to) {
  final sign = from.up ? 1 : -1;
  final headWidth = _width(from.glyph);
  final x1 = from.note.dotted
      ? from.x + _dotRight(headWidth, dotted: true) + _dotGap / 2
      : from.x + headWidth * 0.75;
  final x2 = to.x + _width(to.glyph) * 0.25;
  commands.add(
    TieCommand(
      x1,
      x2,
      from.y + sign * _tieOffset,
      height: sign * math.min(1, 0.3 + 0.1 * (x2 - x1)),
      endThickness: EngravingDefaults.tieEndpointThickness,
      midThickness: EngravingDefaults.tieMidpointThickness,
      event: from.ref,
    ),
  );
}

/// Décorations d'une portée, une fois ses notes placées : articulations
/// contre les têtes, points d'orgue, puis une ligne de textes au-dessus et
/// une ligne de nuances, de soufflets et de textes au-dessous.
///
/// Chaque ligne passe au-delà de tout ce qui dépasse de la portée : les
/// commandes de la portée à partir de [from], hors de l'en-tête (qui finit
/// en [start]) pour ne pas tenir compte de la clé.
void _layoutDecorations(
  List<DrawCommand> commands,
  List<_Placed> placed, {
  required int from,
  required double start,
  required double top,
}) {
  Iterable<Box> boxes() => commands
      .skip(from)
      .map((command) => command.bounds)
      .where((box) => box.left >= start);

  // Le point d'orgue passe au-dessus des autres articulations.
  for (final fermata in [false, true]) {
    for (final item in placed) {
      for (final decoration in item.event.decorations) {
        if (decoration case final Articulation articulation
            when (articulation == Articulation.fermata) == fermata) {
          _layoutArticulation(
            commands,
            item,
            articulation,
            from: from,
            top: top,
          );
        }
      }
    }
  }

  List<(_Placed, Annotation)> annotations(Placement placement) => [
    for (final item in placed)
      for (final decoration in item.event.decorations)
        if (decoration case final Annotation annotation
            when annotation.placement == placement)
          (item, annotation),
  ];

  final above = annotations(Placement.above);
  if (above.isNotEmpty) {
    final highest = boxes().map((box) => box.top).fold(top, math.min);
    final baseline = highest - _lineGap - TextFont.descender * _textSize;
    for (final (item, annotation) in above) {
      commands.add(
        TextCommand(
          annotation.text,
          item.left,
          baseline,
          size: _textSize,
          decoration: item.ref,
        ),
      );
    }
  }

  // Ligne du dessous : sa ligne de base laisse la place du plus haut des
  // signes qu'elle porte.
  final below = annotations(Placement.below);
  var ascent = below.isEmpty ? 0.0 : TextFont.ascender * _textSize;
  for (final item in placed) {
    for (final decoration in item.event.decorations) {
      ascent = math.max(ascent, switch (decoration) {
        Dynamic() => _dynamicGlyph(decoration).bBoxNE.$2,
        HairpinStart() => _hairpinRise + _hairpinOpening / 2,
        _ => 0,
      });
    }
  }
  if (ascent == 0) return;
  final lowest = boxes()
      .map((box) => box.bottom)
      .fold(top + _staffHeight, math.max);
  final baseline = lowest + _lineGap + ascent;

  // Bords des signes de chaque note sur la ligne : un soufflet s'arrête
  // avant eux.
  final signs = <EventRef, Box>{};
  void sign(DrawCommand command, EventRef ref) {
    commands.add(command);
    signs[ref] = signs[ref]?.union(command.bounds) ?? command.bounds;
  }

  for (final item in placed) {
    for (final decoration in item.event.decorations) {
      if (decoration is Dynamic) {
        final glyph = _dynamicGlyph(decoration);
        sign(
          GlyphCommand(
            glyph,
            item.center - glyph.opticalCenter!.$1,
            baseline,
            decoration: item.ref,
          ),
          item.ref,
        );
      }
    }
  }
  // Un texte suit la nuance de sa note : « p dolce ».
  for (final (item, annotation) in below) {
    sign(
      TextCommand(
        annotation.text,
        switch (signs[item.ref]) {
          final dynamic? => math.max(item.left, dynamic.right + _textGap),
          null => item.left,
        },
        baseline,
        size: _textSize,
        decoration: item.ref,
      ),
      item.ref,
    );
  }

  _Placed? open;
  for (final item in placed) {
    for (final decoration in item.event.decorations) {
      if (decoration case HairpinEnd(:final hairpin) when open != null) {
        final x1 = switch (signs[open.ref]) {
          final box? => box.right + _hairpinGap,
          null => open.left,
        };
        final x2 = switch (signs[item.ref]) {
          final box? => box.left - _hairpinGap,
          null => item.right,
        };
        _layoutHairpin(
          commands,
          hairpin,
          x1,
          math.max(x2, x1 + _hairpinMinLength),
          baseline - _hairpinRise,
          open.ref,
        );
        open = null;
      }
    }
    if (item.event.decorations.any((d) => d is HairpinStart)) open = item;
  }
}

/// Articulation de [item] : le point d'orgue au-dessus de la portée, les
/// autres côté tête, à l'opposé de la hampe. Centrée sur la tête.
void _layoutArticulation(
  List<DrawCommand> commands,
  _Placed item,
  Articulation articulation, {
  required int from,
  required double top,
}) {
  final head = item.head;
  final below = head != null && head.up && articulation != Articulation.fermata;
  final glyph = _articulationGlyph(articulation, below: below);
  final (sw, ne) = (glyph.bBoxSW, glyph.bBoxNE);

  // Ordonnée de l'origine SMuFL : bord ou centre du glyphe à sa place.
  final double y;
  switch (articulation) {
    case Articulation.fermata:
      final highest = commands
          .skip(from)
          .where(
            (command) =>
                command.event == item.ref || command.decoration == item.ref,
          )
          .map((command) => command.bounds.top)
          .fold(top, math.min);
      y = highest - _fermataGap + sw.$2;
    case _ when head == null:
      return;
    case Articulation.staccato || Articulation.tenuto:
      // Dans l'interligne voisin de la tête, jamais sur une ligne.
      final step = below ? -1 : 1;
      var position = head.position + 2 * step;
      if (position >= 0 && position <= 8 && position.isEven) position += step;
      y = _y(top, position) + (sw.$2 + ne.$2) / 2;
    case Articulation.accent:
      // Hors de la portée.
      y = below
          ? math.max(head.y + 0.5, top + _staffHeight) + _accentGap + ne.$2
          : math.min(head.y - 0.5, top) - _accentGap + sw.$2;
  }
  commands.add(
    GlyphCommand(
      glyph,
      item.center - (sw.$1 + ne.$1) / 2,
      y,
      decoration: item.ref,
    ),
  );
}

/// Soufflet de [x1] à [x2], centré sur [y] : deux traits qui partent d'un
/// même point, à gauche pour un crescendo, à droite pour un diminuendo.
void _layoutHairpin(
  List<DrawCommand> commands,
  Hairpin hairpin,
  double x1,
  double x2,
  double y,
  EventRef ref,
) {
  final (closed, opened) = switch (hairpin) {
    Hairpin.crescendo => (x1, x2),
    Hairpin.diminuendo => (x2, x1),
  };
  for (final side in [-1, 1]) {
    commands.add(
      LineCommand(
        closed,
        y,
        opened,
        y + side * _hairpinOpening / 2,
        EngravingDefaults.hairpinThickness,
        decoration: ref,
      ),
    );
  }
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
  NoteValue.quarter ||
  NoteValue.eighth ||
  NoteValue.sixteenth => Glyph.noteheadBlack,
};

Glyph _restGlyph(NoteValue value) => switch (value) {
  NoteValue.whole => Glyph.restWhole,
  NoteValue.half => Glyph.restHalf,
  NoteValue.quarter => Glyph.restQuarter,
  NoteValue.eighth => Glyph.rest8th,
  NoteValue.sixteenth => Glyph.rest16th,
};

/// Crochet d'une note seule, [value] croche ou plus courte.
Glyph _flagGlyph(NoteValue value, {required bool up}) => switch (value.flags) {
  1 => up ? Glyph.flag8thUp : Glyph.flag8thDown,
  _ => up ? Glyph.flag16thUp : Glyph.flag16thDown,
};

Glyph _dynamicGlyph(Dynamic dynamic) => switch (dynamic) {
  Dynamic.ppp => Glyph.dynamicPPP,
  Dynamic.pp => Glyph.dynamicPP,
  Dynamic.p => Glyph.dynamicPiano,
  Dynamic.mp => Glyph.dynamicMP,
  Dynamic.mf => Glyph.dynamicMF,
  Dynamic.f => Glyph.dynamicForte,
  Dynamic.ff => Glyph.dynamicFF,
  Dynamic.fff => Glyph.dynamicFFF,
};

Glyph _articulationGlyph(Articulation articulation, {required bool below}) =>
    switch (articulation) {
      Articulation.staccato =>
        below ? Glyph.articStaccatoBelow : Glyph.articStaccatoAbove,
      Articulation.tenuto =>
        below ? Glyph.articTenutoBelow : Glyph.articTenutoAbove,
      Articulation.accent =>
        below ? Glyph.articAccentBelow : Glyph.articAccentAbove,
      Articulation.fermata => Glyph.fermataAbove,
    };

Glyph _accidentalGlyph(Accidental accidental) => switch (accidental) {
  Accidental.doubleFlat => Glyph.accidentalDoubleFlat,
  Accidental.flat => Glyph.accidentalFlat,
  Accidental.natural => Glyph.accidentalNatural,
  Accidental.sharp => Glyph.accidentalSharp,
  Accidental.doubleSharp => Glyph.accidentalDoubleSharp,
};
