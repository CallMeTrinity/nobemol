import 'package:flutter/material.dart';

import 'package:nobemol/theme/tokens.dart';

/// Couleurs d'un élément à ombre pleine.
@immutable
class DepthColors {
  const DepthColors({
    required this.background,
    required this.foreground,
    required this.shadow,
    this.border,
    this.pressed,
  });

  final Color background;
  final Color foreground;

  /// Ombre pleine, décalée sous l'élément.
  final Color shadow;

  /// Contour intérieur, `null` sans contour.
  final Color? border;

  /// Fond pendant l'appui, `null` si le fond ne change pas.
  final Color? pressed;
}

/// État d'une réponse (touche, tuile, carte) : au repos, ou corrigée.
enum AnswerTone { rest, right, wrong }

extension AnswerColors on NobemolColors {
  /// Tuile ou carte réponse.
  DepthColors answer(AnswerTone tone) => switch (tone) {
    AnswerTone.rest => DepthColors(
      background: surface,
      foreground: ink,
      shadow: surfaceShadow,
      border: line,
      pressed: keyPressed.withValues(alpha: 0.5),
    ),
    AnswerTone.right => DepthColors(
      background: success,
      foreground: const Color(0xFFFFFFFF),
      shadow: successDeep,
    ),
    AnswerTone.wrong => DepthColors(
      background: danger,
      foreground: const Color(0xFFFFFFFF),
      shadow: dangerDeep,
    ),
  };
}

/// Élément pressable à ombre pleine. À l'appui, il s'enfonce : l'ombre
/// passe à [Depths.pressed]. La place de l'ombre est toujours réservée en
/// dessous, l'élément ne pousse donc pas ses voisins.
///
/// Sans [onPressed], il est inactif : il ne s'enfonce plus.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.colors,
    required this.child,
    this.onPressed,
    this.depth = Depths.button,
    this.borderRadius = const BorderRadius.all(Radius.circular(Radii.button)),
    this.borderWidth = 1.5,
    this.height,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  });

  final DepthColors colors;
  final Widget child;
  final VoidCallback? onPressed;
  final double depth;
  final BorderRadius borderRadius;
  final double borderWidth;

  /// Hauteur de l'élément, ombre non comprise.
  final double? height;
  final EdgeInsets padding;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;

  void _press(bool pressed) {
    if (widget.onPressed == null || pressed == _pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final depth = widget.depth;
    final shadow = _pressed ? Depths.pressed : depth;
    final border = colors.border;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onPressed,
        child: Padding(
          padding: EdgeInsets.only(bottom: depth),
          child: Transform.translate(
            offset: Offset(0, depth - shadow),
            child: Container(
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _pressed
                    ? colors.pressed ?? colors.background
                    : colors.background,
                borderRadius: widget.borderRadius,
                border: border == null
                    ? null
                    : Border.all(color: border, width: widget.borderWidth),
                boxShadow: [
                  if (shadow > 0)
                    BoxShadow(color: colors.shadow, offset: Offset(0, shadow)),
                ],
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: colors.foreground),
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.foreground),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonVariant { primary, ink, outline, text }

/// Bouton à ombre pleine : principal (accent), encre, contour ou texte.
class DepthButton extends StatelessWidget {
  const DepthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.large = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;

  /// 56 px de haut au lieu de 52.
  final bool large;

  /// Prend toute la largeur disponible.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final colors = switch (variant) {
      ButtonVariant.primary => DepthColors(
        background: c.accent,
        foreground: c.onAccent,
        shadow: c.accentDeep,
      ),
      ButtonVariant.ink => DepthColors(
        background: c.surfaceInverse,
        foreground: c.onSurfaceInverse,
        shadow: c.inkDeep,
      ),
      ButtonVariant.outline => DepthColors(
        background: const Color(0x00000000),
        foreground: c.ink,
        shadow: const Color(0x00000000),
        border: c.line,
      ),
      ButtonVariant.text => DepthColors(
        background: const Color(0x00000000),
        foreground: c.inkMuted,
        shadow: const Color(0x00000000),
      ),
    };
    final flat =
        variant == ButtonVariant.outline || variant == ButtonVariant.text;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Pressable(
        colors: colors,
        onPressed: onPressed,
        depth: flat ? 0 : Depths.button,
        borderWidth: 2,
        borderRadius: BorderRadius.circular(
          large ? Radii.buttonLg : Radii.button,
        ),
        height: large ? Sizes.buttonLg : Sizes.button,
        padding: EdgeInsets.symmetric(horizontal: flat ? 18 : 24),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(label, style: AppText.labelButton)],
        ),
      ),
    );
  }
}

/// Tuile : une surface à ombre légère. Bordée d'accent si [highlighted].
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.height,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool highlighted;

  /// Hauteur fixe, ombre non comprise. Par défaut, celle du contenu.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      colors: DepthColors(
        background: c.surface,
        foreground: c.ink,
        shadow: c.line,
        border: highlighted ? c.accent : null,
        pressed: c.keyPressed.withValues(alpha: 0.4),
      ),
      onPressed: onTap,
      depth: Depths.tile,
      borderWidth: 2,
      borderRadius: BorderRadius.circular(Radii.card),
      height: height,
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

/// Puce : un choix court parmi quelques-uns (période, réglage).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      colors: selected
          ? DepthColors(
              background: c.surfaceInverse,
              foreground: c.onSurfaceInverse,
              shadow: c.inkDeep,
            )
          : DepthColors(
              background: c.surface,
              foreground: c.ink,
              shadow: c.line,
              border: c.line,
            ),
      onPressed: onTap,
      depth: Depths.tile,
      borderRadius: BorderRadius.circular(Sizes.chip / 2),
      height: Sizes.chip,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label, style: AppText.labelTab.copyWith(fontSize: 14))],
      ),
    );
  }
}
