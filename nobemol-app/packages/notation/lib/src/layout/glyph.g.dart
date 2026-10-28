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
}
