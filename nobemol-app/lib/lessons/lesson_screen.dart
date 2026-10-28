import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/lesson.dart';

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
    final lesson = widget.lesson;
    final pages = lesson.theory;
    final last = _page == pages.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(value: (_page + 1) / pages.length),
              const SizedBox(height: 24),
              Expanded(child: _TheoryPageView(page: pages[_page])),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_page > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _page--),
                      child: Text(l10n.lessonPrevious),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: last
                        ? () => context.go('/lecon/${lesson.id}/exercice')
                        : () => setState(() => _page++),
                    child: Text(last ? l10n.lessonPractice : l10n.lessonNext),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TheoryPageView extends StatelessWidget {
  const _TheoryPageView({required this.page});

  final TheoryPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final system = page.system;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(page.text, style: theme.textTheme.titleMedium),
        if (system != null)
          Expanded(
            child: Center(
              // scaleDown : la portée garde sa taille, sauf si elle déborde.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NotationView(
                  system: system,
                  staffSpace: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
