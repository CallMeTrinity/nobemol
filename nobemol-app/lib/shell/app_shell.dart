import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/glyph_view.dart';

/// Écrans principaux et barre à 4 onglets : Parcours, Réviser, Arcade,
/// Profil. Chaque onglet garde sa pile de navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
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
                      child: _Tab(
                        label: label,
                        glyph: glyph,
                        staffSpace: staffSpace,
                        color: index == current ? c.tabActive : c.tabInactive,
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
  });

  final String label;
  final Glyph glyph;
  final double staffSpace;
  final Color color;

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
              child: GlyphView(glyph, staffSpace: staffSpace, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.labelTab.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Onglet pas encore construit : son titre et ce qui viendra.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.description,
    this.footer,
  });

  final String title;
  final String description;

  /// Sous la carte « Bientôt » : ce qui existe déjà dans l'onglet.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 36, Space.xl, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.titleScreen.copyWith(color: c.ink)),
            const SizedBox(height: Space.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.ml),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: c.keyBorder, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.comingSoon.toUpperCase(),
                    style: AppText.meta.copyWith(color: c.accentDeep),
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    description,
                    style: AppText.body.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            if (footer case final footer?) ...[
              const SizedBox(height: Space.xl),
              footer,
            ],
          ],
        ),
      ),
    );
  }
}
