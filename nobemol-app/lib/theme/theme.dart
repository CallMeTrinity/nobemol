import 'package:flutter/material.dart';

import 'package:nobemol/theme/tokens.dart';

/// Thème Material de l'appli, en clair ou en sombre. Les écrans lisent
/// surtout les tokens (`context.colors`, [AppText]) ; le thème Material
/// sert aux widgets du framework (sélection, défilement, dialogues).
ThemeData buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.light
      ? NobemolColors.light
      : NobemolColors.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: brightness,
      ).copyWith(
        primary: colors.accent,
        onPrimary: colors.ink,
        secondary: colors.accent,
        surface: colors.bg,
        onSurface: colors.ink,
        error: colors.danger,
      );

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.bg,
    fontFamily: AppText.body.fontFamily,
    textTheme: Typography.material2021().black
        .apply(fontFamily: AppText.body.fontFamily)
        .apply(bodyColor: colors.ink, displayColor: colors.ink),
    splashFactory: NoSplash.splashFactory,
    extensions: [colors],
  );
}
