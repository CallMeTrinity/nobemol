// GÉNÉRÉ par tool/bravura.dart, ne pas modifier à la main.
// Bravura 1.482, SMuFL v1.4.

/// Glyphes SMuFL utilisés par le moteur.
///
/// Boîtes englobantes en interlignes, axe y vers le haut,
/// origine sur la ligne de base (convention SMuFL).
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
  );

  new({required this.codepoint, required this.bBoxSW, required this.bBoxNE});

  /// Codepoint dans la police.
  final int codepoint;

  /// Coin bas gauche de la boîte englobante (x, y).
  final (double, double) bBoxSW;

  /// Coin haut droit de la boîte englobante (x, y).
  final (double, double) bBoxNE;
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
}
