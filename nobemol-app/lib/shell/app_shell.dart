import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/glyph_view.dart';
import 'package:nobemol/ui/motion.dart';

/// Écrans principaux et barre à 4 onglets : Parcours, Réviser, Arcade,
/// Profil. Chaque onglet garde sa pile de navigation, et apparaît en
/// fondu quand on le choisit.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: _TabFade(index: shell.currentIndex, child: shell),
      bottomNavigationBar: _TabBar(
        current: shell.currentIndex,
        // Retoucher l'onglet courant revient à sa racine.
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        tabs: [
          (l10n.tabCourse, Glyph.gClef, 3.75),
          (l10n.tabReview, Glyph.noteQuarterUp, 6.0),
          (l10n.tabArcade, Glyph.note8thUp, 6.0),
          (l10n.tabProfile, Glyph.fermataAbove, 5.5),
        ],
      ),
    );
  }
}

/// L'onglet choisi monte un peu en apparaissant. Les onglets restent
/// construits (`indexedStack`) : seul l'affichage s'anime.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1);
  late final _progress = CurvedAnimation(
    parent: _controller,
    curve: Motion.enter,
  );

  @override
  void didUpdateWidget(_TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index) return;
    final duration = Motion.of(context, Motion.base);
    if (duration == Duration.zero) return;
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * 8),
          child: child,
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.current,
    required this.onTap,
    required this.tabs,
  });

  final int current;
  final ValueChanged<int> onTap;

  /// Libellé, icône et taille de l'icône (interligne) de chaque onglet.
  final List<(String, Glyph, double)> tabs;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Sizes.tabBar,
          child: Row(
            children: [
              for (final (index, (label, glyph, staffSpace)) in tabs.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == current,
                    child: GestureDetector(
                      key: ValueKey('tab-$index'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      // La couleur passe d'un onglet à l'autre en douceur.
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(
                          end: index == current ? c.tabActive : c.tabInactive,
                        ),
                        duration: Motion.of(context, Motion.base),
                        curve: Motion.enter,
                        builder: (context, color, _) => _Tab(
                          label: label,
                          glyph: glyph,
                          staffSpace: staffSpace,
                          color: color!,
                          active: index == current,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.glyph,
    required this.staffSpace,
    required this.color,
    required this.active,
  });

  final String label;
  final Glyph glyph;
  final double staffSpace;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 30,
            child: Align(
              alignment: Alignment.bottomCenter,
              // L'icône de l'onglet choisi grandit à peine.
              child: AnimatedScale(
                scale: active ? 1.1 : 1,
                duration: Motion.of(context, Motion.base),
                curve: Motion.emphasis,
                alignment: Alignment.bottomCenter,
                child: GlyphView(glyph, staffSpace: staffSpace, color: color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.labelTab.copyWith(color: color)),
        ],
      ),
    );
  }
}
