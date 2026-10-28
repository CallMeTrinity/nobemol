import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// Pages de théorie d'une leçon, puis accès à l'exercice.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final lesson = widget.lesson;
    final pages = lesson.theory;
    final page = pages[_page];
    final last = _page == pages.length - 1;
    final (:title, :body) = page.parts;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(title: lesson.title, page: page),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.xxl,
                Space.xl,
                Space.ml,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageDots(count: pages.length, current: _page),
                  const SizedBox(height: Space.ml),
                  Text(
                    title,
                    style: AppText.titleTheory.copyWith(color: c.ink),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: Space.m),
                    Text(
                      body,
                      style: AppText.bodyLarge.copyWith(color: c.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
              child: Row(
                children: [
                  if (_page > 0)
                    DepthButton(
                      label: l10n.lessonPrevious,
                      variant: ButtonVariant.text,
                      large: true,
                      onPressed: () => setState(() => _page--),
                    ),
                  const Spacer(),
                  DepthButton(
                    label: last ? l10n.lessonPractice : l10n.lessonNext,
                    variant: last ? ButtonVariant.primary : ButtonVariant.ink,
                    large: true,
                    onPressed: last
                        ? () => context.go('/lecon/${lesson.id}/exercice')
                        : () => setState(() => _page++),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau du haut : fermer, titre de la leçon, et la musique de la page.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.page});

  final String title;
  final TheoryPage page;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final system = page.system;

    return ColoredBox(
      color: c.accentSoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s,
            Space.m,
            Space.s,
            Space.l,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox.square(
                    dimension: Sizes.minTarget,
                    child: IconButton(
                      key: const ValueKey('close'),
                      tooltip: l10n.close,
                      onPressed: () => context.go('/'),
                      icon: Icon(Icons.close_rounded, color: c.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppText.titleCard.copyWith(
                        color: c.ink,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sizes.minTarget),
                ],
              ),
              if (system != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.ml,
                    Space.xl,
                    Space.ml,
                    0,
                  ),
                  // scaleDown : la portée garde sa taille, sauf si elle
                  // déborde.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: NotationView(
                      system: system,
                      staffSpace: StaffSpaces.theory,
                      color: c.ink,
                      labels: page.names ? _names(system, l10n) : const {},
                      labelStyle: AppText.staffLabel.copyWith(
                        color: c.inkMuted,
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

/// Nom de chaque note de [system], sans l'altération.
Map<EventRef, String> _names(System system, AppLocalizations l10n) => {
  for (final (index, staff) in system.staves.indexed)
    for (final (:measure, :event, :value) in staff.events)
      if (value case Note(:final pitch))
        EventRef(staff: index, measure: measure, event: event): l10n.noteName(
          pitch.step,
        ),
};

/// Page courante : un trait d'accent. Pages lues en encre, à venir en gris.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(right: Space.xs),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? c.accent
                  : i < current
                  ? c.ink
                  : c.keyBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
