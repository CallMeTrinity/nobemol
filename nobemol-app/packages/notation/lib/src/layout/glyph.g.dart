// GÉNÉRÉ par tool/bravura.dart, ne pas modifier à la main.
// Bravura 1.482, SMuFL v1.4.

/// Glyphes SMuFL utilisés par le moteur.
///
/// Boîtes englobantes en interlignes, axe y vers le haut,
/// origine sur la ligne de base (convention SMuFL).
/// Ancres `null` si le glyphe n'en a pas.
enum Glyph {
  /// Brace.
  brace(
    codepoint: 0xE000,
    bBoxSW: (0.0, -0.002531),
    bBoxNE: (0.277415, 4.00244),
  ),

  /// G clef.
  gClef(codepoint: 0xE050, bBoxSW: (0.0, -2.632), bBoxNE: (2.684, 4.392)),

  /// C clef.
  cClef(codepoint: 0xE05C, bBoxSW: (0.0, -2.024), bBoxNE: (2.796, 2.024)),

  /// F clef.
  fClef(codepoint: 0xE062, bBoxSW: (-0.02, -2.54), bBoxNE: (2.736, 1.048)),

  /// Whole (semibreve) notehead.
  noteheadWhole(codepoint: 0xE0A2, bBoxSW: (0.0, -0.5), bBoxNE: (1.688, 0.5)),

  /// Half (minim) notehead.
  noteheadHalf(
    codepoint: 0xE0A3,
    bBoxSW: (0.0, -0.5),
    bBoxNE: (1.18, 0.5),
    stemUpSE: (1.18, 0.168),
    stemDownNW: (0.0, -0.168),
  ),

  /// Black notehead.
  noteheadBlack(
    codepoint: 0xE0A4,
    bBoxSW: (0.0, -0.5),
    bBoxNE: (1.18, 0.5),
    stemUpSE: (1.18, 0.168),
    stemDownNW: (0.0, -0.168),
  ),

  /// Double flat.
  accidentalDoubleFlat(
    codepoint: 0xE264,
    bBoxSW: (0.0, -0.7),
    bBoxNE: (1.644, 1.748),
  ),

  /// Flat.
  accidentalFlat(
    codepoint: 0xE260,
    bBoxSW: (0.0, -0.7),
    bBoxNE: (0.904, 1.756),
  ),

  /// Natural.
  accidentalNatural(
    codepoint: 0xE261,
    bBoxSW: (0.0, -1.34),
    bBoxNE: (0.672, 1.364),
  ),

  /// Sharp.
  accidentalSharp(
    codepoint: 0xE262,
    bBoxSW: (0.0, -1.392),
    bBoxNE: (0.996, 1.4),
  ),

  /// Double sharp.
  accidentalDoubleSharp(
    codepoint: 0xE263,
    bBoxSW: (0.0, -0.5),
    bBoxNE: (0.988, 0.508),
  ),

  /// Augmentation dot.
  augmentationDot(codepoint: 0xE1E7, bBoxSW: (0.0, -0.2), bBoxNE: (0.4, 0.2)),

  /// Combining flag 1 (8th) above.
  flag8thUp(
    codepoint: 0xE240,
    bBoxSW: (0.0, -3.24),
    bBoxNE: (1.056, 0.036),
    stemUpNW: (0.0, -0.04),
  ),

  /// Combining flag 1 (8th) below.
  flag8thDown(
    codepoint: 0xE241,
    bBoxSW: (0.0, -0.056),
    bBoxNE: (1.224, 3.232),
    stemDownSW: (0.0, 0.132),
  ),

  /// Combining flag 2 (16th) above.
  flag16thUp(
    codepoint: 0xE242,
    bBoxSW: (0.0, -3.252),
    bBoxNE: (1.116, 0.008),
    stemUpNW: (0.0, -0.088),
  ),

  /// Combining flag 2 (16th) below.
  flag16thDown(
    codepoint: 0xE243,
    bBoxSW: (0.0, -0.036),
    bBoxNE: (1.164, 3.248026),
    stemDownSW: (0.0, 0.128),
  ),

  /// Whole (semibreve) rest.
  restWhole(codepoint: 0xE4E3, bBoxSW: (0.0, -0.54), bBoxNE: (1.128, 0.036)),

  /// Half (minim) rest.
  restHalf(codepoint: 0xE4E4, bBoxSW: (0.0, -0.008), bBoxNE: (1.128, 0.568)),

  /// Quarter (crotchet) rest.
  restQuarter(codepoint: 0xE4E5, bBoxSW: (0.004, -1.5), bBoxNE: (1.08, 1.492)),

  /// Eighth (quaver) rest.
  rest8th(codepoint: 0xE4E6, bBoxSW: (0.0, -1.004), bBoxNE: (0.988, 0.696)),

  /// 16th (semiquaver) rest.
  rest16th(codepoint: 0xE4E7, bBoxSW: (0.0, -2.0), bBoxNE: (1.28, 0.716)),

  /// Staccato above.
  articStaccatoAbove(
    codepoint: 0xE4A2,
    bBoxSW: (0.0, 0.0),
    bBoxNE: (0.336, 0.336),
  ),

  /// Staccato below.
  articStaccatoBelow(
    codepoint: 0xE4A3,
    bBoxSW: (0.0, -0.336),
    bBoxNE: (0.336, 0.0),
  ),

  /// Tenuto above.
  articTenutoAbove(
    codepoint: 0xE4A4,
    bBoxSW: (-0.004, 0.0),
    bBoxNE: (1.352, 0.192),
  ),

  /// Tenuto below.
  articTenutoBelow(
    codepoint: 0xE4A5,
    bBoxSW: (-0.004, -0.192),
    bBoxNE: (1.352, 0.0),
  ),

  /// Accent above.
  articAccentAbove(
    codepoint: 0xE4A0,
    bBoxSW: (0.0, 0.004),
    bBoxNE: (1.356, 0.98),
  ),

  /// Accent below.
  articAccentBelow(
    codepoint: 0xE4A1,
    bBoxSW: (0.0, -0.976),
    bBoxNE: (1.356, 0.0),
  ),

  /// Fermata above.
  fermataAbove(
    codepoint: 0xE4C0,
    bBoxSW: (0.012, -0.012),
    bBoxNE: (2.42, 1.316),
  ),

  /// Fermata below.
  fermataBelow(codepoint: 0xE4C1, bBoxSW: (0.012, -1.328), bBoxNE: (2.42, 0.0)),

  /// ppp.
  dynamicPPP(
    codepoint: 0xE52A,
    bBoxSW: (-0.368, -0.568),
    bBoxNE: (4.292, 1.096),
    opticalCenter: (2.368, 0.0),
  ),

  /// pp.
  dynamicPP(
    codepoint: 0xE52B,
    bBoxSW: (-0.328, -0.568),
    bBoxNE: (2.912, 1.096),
    opticalCenter: (1.708, 0.0),
  ),

  /// Piano.
  dynamicPiano(
    codepoint: 0xE520,
    bBoxSW: (-0.356, -0.568),
    bBoxNE: (1.464, 1.096),
    opticalCenter: (1.22, 0.0),
  ),

  /// mp.
  dynamicMP(
    codepoint: 0xE52C,
    bBoxSW: (-0.08, -0.568),
    bBoxNE: (3.3, 1.096),
    opticalCenter: (1.848, 0.0),
  ),

  /// mf.
  dynamicMF(
    codepoint: 0xE52D,
    bBoxSW: (-0.08, -0.66),
    bBoxNE: (3.272, 1.724),
    opticalCenter: (1.796, 0.0),
  ),

  /// Forte.
  dynamicForte(
    codepoint: 0xE522,
    bBoxSW: (-0.564, -0.608),
    bBoxNE: (1.456, 1.776),
    opticalCenter: (1.256, 0.0),
  ),

  /// ff.
  dynamicFF(
    codepoint: 0xE52F,
    bBoxSW: (-0.54, -0.608),
    bBoxNE: (2.44, 1.776),
    opticalCenter: (1.852, 0.0),
  ),

  /// fff.
  dynamicFFF(
    codepoint: 0xE530,
    bBoxSW: (-0.62, -0.608),
    bBoxNE: (3.32, 1.776),
    opticalCenter: (2.472, 0.0),
  ),

  /// Time signature 0.
  timeSig0(codepoint: 0xE080, bBoxSW: (0.08, -1.0), bBoxNE: (1.8, 1.004)),

  /// Time signature 1.
  timeSig1(codepoint: 0xE081, bBoxSW: (0.08, -1.0), bBoxNE: (1.256, 1.004)),

  /// Time signature 2.
  timeSig2(codepoint: 0xE082, bBoxSW: (0.08, -1.028), bBoxNE: (1.704, 1.016)),

  /// Time signature 3.
  timeSig3(codepoint: 0xE083, bBoxSW: (0.08, -1.004), bBoxNE: (1.604, 0.996)),

  /// Time signature 4.
  timeSig4(codepoint: 0xE084, bBoxSW: (0.08, -1.0), bBoxNE: (1.8, 1.004)),

  /// Time signature 5.
  timeSig5(codepoint: 0xE085, bBoxSW: (0.08, -1.004), bBoxNE: (1.532, 0.984)),

  /// Time signature 6.
  timeSig6(codepoint: 0xE086, bBoxSW: (0.08, -0.996), bBoxNE: (1.656, 1.004)),

  /// Time signature 7.
  timeSig7(codepoint: 0xE087, bBoxSW: (0.08, -1.0), bBoxNE: (1.684, 0.996)),

  /// Time signature 8.
  timeSig8(codepoint: 0xE088, bBoxSW: (0.08, -1.036), bBoxNE: (1.664, 1.036)),

  /// Time signature 9.
  timeSig9(codepoint: 0xE089, bBoxSW: (0.08, -0.996), bBoxNE: (1.656, 1.004));

  new({
    required this.codepoint,
    required this.bBoxSW,
    required this.bBoxNE,
    this.stemUpSE,
    this.stemDownNW,
    this.stemUpNW,
    this.stemDownSW,
    this.opticalCenter,
  });

  /// Codepoint dans la police.
  final int codepoint;

  /// Coin bas gauche de la boîte englobante (x, y).
  final (double, double) bBoxSW;

  /// Coin haut droit de la boîte englobante (x, y).
  final (double, double) bBoxNE;

  /// Attache d'une hampe vers le haut (x, y).
  final (double, double)? stemUpSE;

  /// Attache d'une hampe vers le bas (x, y).
  final (double, double)? stemDownNW;

  /// Attache d'un crochet sur une hampe vers le haut (x, y).
  final (double, double)? stemUpNW;

  /// Attache d'un crochet sur une hampe vers le bas (x, y).
  final (double, double)? stemDownSW;

  /// Centre visuel, pour centrer une nuance sous sa note (x, y).
  final (double, double)? opticalCenter;
}

/// Valeurs de gravure par défaut de Bravura, en interlignes.
abstract final class EngravingDefaults {
  /// `staffLineThickness`.
  static const staffLineThickness = 0.13;

  /// `legerLineThickness`.
  static const legerLineThickness = 0.16;

  /// `legerLineExtension`.
  static const legerLineExtension = 0.4;

  /// `thinBarlineThickness`.
  static const thinBarlineThickness = 0.16;

  /// `thickBarlineThickness`.
  static const thickBarlineThickness = 0.5;

  /// `barlineSeparation`.
  static const barlineSeparation = 0.4;

  /// `thinThickBarlineSeparation`.
  static const thinThickBarlineSeparation = 0.4;

  /// `stemThickness`.
  static const stemThickness = 0.12;

  /// `beamThickness`.
  static const beamThickness = 0.5;

  /// `beamSpacing`.
  static const beamSpacing = 0.25;

  /// `tieEndpointThickness`.
  static const tieEndpointThickness = 0.1;

  /// `tieMidpointThickness`.
  static const tieMidpointThickness = 0.22;

  /// `hairpinThickness`.
  static const hairpinThickness = 0.16;
}
