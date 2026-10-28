import 'package:flutter/material.dart';

/// Tokens du design « Touches » (`tokens/nobemol-tokens.json`, projet
/// Claude Design). Ombres pleines décalées en Y, sans flou.

/// Couleurs, en clair et en sombre. Lues par `context.colors`.
@immutable
class NobemolColors extends ThemeExtension<NobemolColors> {
  const NobemolColors({
    required this.bg,
    required this.surface,
    required this.surfaceInverse,
    required this.onSurfaceInverse,
    required this.ink,
    required this.inkDeep,
    required this.inkMuted,
    required this.line,
    required this.surfaceShadow,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.onAccent,
    required this.success,
    required this.successDeep,
    required this.successSoft,
    required this.danger,
    required this.dangerDeep,
    required this.dangerSoft,
    required this.warningSoft,
    required this.warningInk,
    required this.keyWhite,
    required this.keyLabel,
    required this.keyPressed,
    required this.keyBorder,
    required this.keyShadow,
    required this.keyBlack,
    required this.keyBlackOff,
    required this.tabActive,
    required this.tabInactive,
  });

  static const light = NobemolColors(
    bg: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceInverse: Color(0xFF1C2033),
    onSurfaceInverse: Color(0xFFFFFFFF),
    ink: Color(0xFF1C2033),
    inkDeep: Color(0xFF070914),
    inkMuted: Color(0xFF5B6078),
    line: Color(0xFFE2E4EE),
    surfaceShadow: Color(0xFFD3D6E3),
    accent: Color(0xFFEF5B36),
    accentDeep: Color(0xFFB8401F),
    accentSoft: Color(0xFFFFE7DF),
    onAccent: Color(0xFF1C2033),
    success: Color(0xFF1F9D66),
    successDeep: Color(0xFF146B45),
    successSoft: Color(0xFFD5F0E3),
    danger: Color(0xFFD63B5A),
    dangerDeep: Color(0xFFA1203B),
    dangerSoft: Color(0xFFFBDDE3),
    warningSoft: Color(0xFFFFF0D6),
    warningInk: Color(0xFF8A5A00),
    keyWhite: Color(0xFFFFFFFF),
    keyLabel: Color(0xFF1C2033),
    keyPressed: Color(0xFFE9EBF3),
    keyBorder: Color(0xFFD3D6E3),
    keyShadow: Color(0xFFC9CCDA),
    keyBlack: Color(0xFF1C2033),
    keyBlackOff: Color(0xFFD3D6E3),
    tabActive: Color(0xFF1C2033),
    tabInactive: Color(0xFF9A9FBF),
  );

  static const dark = NobemolColors(
    bg: Color(0xFF12152A),
    surface: Color(0xFF1D2140),
    surfaceInverse: Color(0xFFEEF0FA),
    onSurfaceInverse: Color(0xFF12152A),
    ink: Color(0xFFEEF0FA),
    inkDeep: Color(0xFF8A8FB8),
    inkMuted: Color(0xFF9A9FBF),
    line: Color(0xFF2E3358),
    surfaceShadow: Color(0xFF070914),
    accent: Color(0xFFFF6A45),
    accentDeep: Color(0xFFB8401F),
    accentSoft: Color(0xFF3A2230),
    onAccent: Color(0xFF12152A),
    success: Color(0xFF34C483),
    successDeep: Color(0xFF1F9D66),
    successSoft: Color(0xFF16352A),
    danger: Color(0xFFFF5C7C),
    dangerDeep: Color(0xFFC2334D),
    dangerSoft: Color(0xFF3A1C26),
    warningSoft: Color(0xFF3A3020),
    warningInk: Color(0xFFFFD27A),
    keyWhite: Color(0xFFEEF0FA),
    keyLabel: Color(0xFF12152A),
    keyPressed: Color(0xFFD3D6E3),
    keyBorder: Color(0xFFEEF0FA),
    keyShadow: Color(0xFF8A8FB8),
    keyBlack: Color(0xFF070914),
    keyBlackOff: Color(0xFF3A3F66),
    tabActive: Color(0xFFFF6A45),
    tabInactive: Color(0xFF5D628A),
  );

  /// Fond d'écran.
  final Color bg;

  /// Dock, tuiles, barre d'onglets.
  final Color surface;

  /// Hero, résultats, pastilles sombres.
  final Color surfaceInverse;
  final Color onSurfaceInverse;

  /// Texte, notes.
  final Color ink;

  /// Ombre d'un bouton encre. Hors tokens.
  final Color inkDeep;

  /// Texte secondaire.
  final Color inkMuted;

  /// Contours, pistes.
  final Color line;

  /// Ombre d'une tuile ou d'une carte réponse. Hors tokens.
  final Color surfaceShadow;

  /// Cible, combo, bouton principal.
  final Color accent;
  final Color accentDeep;

  /// Halo de cible.
  final Color accentSoft;

  /// Texte sur l'accent. Hors tokens.
  final Color onAccent;

  /// Juste.
  final Color success;
  final Color successDeep;
  final Color successSoft;

  /// Faux.
  final Color danger;
  final Color dangerDeep;
  final Color dangerSoft;

  /// Précision moyenne.
  final Color warningSoft;
  final Color warningInk;

  /// Touche blanche et son nom.
  final Color keyWhite;
  final Color keyLabel;

  /// Touche blanche appuyée. Hors tokens (« appui » dans le design).
  final Color keyPressed;
  final Color keyBorder;

  /// Profondeur d'une touche.
  final Color keyShadow;

  /// Touche noire active, inactive.
  final Color keyBlack;
  final Color keyBlackOff;

  /// Onglet actif, inactifs.
  final Color tabActive;
  final Color tabInactive;

  @override
  NobemolColors copyWith() => this;

  /// Pas d'animation entre clair et sombre : le thème change d'un coup.
  @override
  NobemolColors lerp(NobemolColors? other, double t) =>
      t < 0.5 ? this : other ?? this;
}

extension NobemolTheme on BuildContext {
  NobemolColors get colors => Theme.of(this).extension<NobemolColors>()!;
}

/// Rayons.
abstract final class Radii {
  static const sm = 10.0;
  static const key = 12.0;
  static const button = 16.0;
  static const buttonLg = 18.0;
  static const card = 20.0;
  static const hero = 24.0;
  static const sheet = 28.0;
  static const screen = 32.0;
}

/// Profondeur : décalage de l'ombre pleine.
abstract final class Depths {
  static const tile = 3.0;
  static const badge = 4.0;
  static const button = 5.0;
  static const key = 6.0;
  static const hero = 6.0;

  /// Profondeur restante pendant l'appui.
  static const pressed = 2.0;
}

/// Espacements.
abstract final class Space {
  static const xxs = 4.0;
  static const xs = 6.0;
  static const s = 8.0;
  static const sm = 10.0;
  static const m = 12.0;
  static const ml = 16.0;
  static const l = 20.0;
  static const xl = 24.0;
  static const xxl = 28.0;
}

/// Tailles fixes.
abstract final class Sizes {
  static const tabBar = 76.0;
  static const button = 52.0;
  static const buttonLg = 56.0;
  static const chip = 36.0;
  static const keyHeight = 200.0;
  static const keyHeightCompact = 150.0;
  static const answerTile = 68.0;
  static const markingCard = 104.0;

  /// Zone de toucher minimale.
  static const minTarget = 44.0;
}

/// Taille d'un interligne, en pixels.
abstract final class StaffSpaces {
  /// Une note seule à lire.
  static const exercise = 17.0;
  static const theory = 15.0;

  /// Une phrase en mesures.
  static const phrase = 11.0;
  static const cards = 8.5;
  static const mini = 5.5;
}

/// Échelle typographique. Sans couleur : elle vient du texte ambiant.
///
/// Bricolage Grotesque et Instrument Sans sont des polices variables : la
/// graisse passe par l'axe `wght` (fontWeight seul ne la change pas), la
/// taille optique de Bricolage par l'axe `opsz`, comme le fait un
/// navigateur.
abstract final class AppText {
  static const displayXl = TextStyle(
    fontFamily: _display,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1,
    fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 44)],
  );
  static const titleScreen = TextStyle(
    fontFamily: _display,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1,
    fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 34)],
  );
  static const titlePrompt = TextStyle(
    fontFamily: _display,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.1,
    fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 26)],
  );
  static const titleTheory = TextStyle(
    fontFamily: _display,
    fontSize: 25,
    fontWeight: FontWeight.w700,
    height: 1.25,
    fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 25)],
  );
  static const titleCard = TextStyle(
    fontFamily: _display,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 17)],
  );
  static const labelKey = TextStyle(
    fontFamily: _display,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1,
    fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 17)],
  );
  static const labelButton = TextStyle(
    fontFamily: _display,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1,
    fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 16)],
  );

  /// Libellé d'une carte réponse (le sens d'un signe).
  static const labelCard = TextStyle(
    fontFamily: _display,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.15,
    fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 13)],
  );

  /// Libellé d'onglet.
  static const labelTab = TextStyle(
    fontFamily: _display,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1,
    fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 12)],
  );
  static const body = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    fontVariations: [FontVariation('wght', 400)],
  );
  static const bodyLarge = TextStyle(
    fontFamily: _body,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontVariations: [FontVariation('wght', 400)],
  );

  /// Méta, en capitales (à la charge de l'appelant : `toUpperCase()`).
  static const meta = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1,
  );

  /// Chiffres d'une pastille (chrono).
  static const metaLarge = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1,
  );

  /// Noms sous les notes, dans la portée.
  static const staffLabel = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const _display = 'Bricolage Grotesque';
  static const _body = 'Instrument Sans';
  static const _mono = 'DM Mono';
}
