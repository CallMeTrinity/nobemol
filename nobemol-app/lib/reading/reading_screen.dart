import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/explanations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/lessons/skill_tree.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/fit_words.dart';
import 'package:nobemol/ui/note_keyboard.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Écran de lecture : une note (seule ou ciblée dans une phrase), et les
/// réponses possibles en bas : le clavier pour un nom de note, des tuiles
/// pour une durée, des cartes pour le sens d'un signe. Après chaque
/// réponse, la correction et son explication.
///
/// La session est enregistrée à la dernière réponse. Une session quittée
/// avant n'est pas gardée : quitter demande confirmation.
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key, required this.exercise, this.lessonId});

  final ReadingExercise exercise;

  /// Leçon de l'exercice, `null` en lecture libre.
  final String? lessonId;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  /// Enregistrement de la session terminée, et ce qu'elle a changé.
  Future<SessionOutcome>? _outcome;

  /// Palier franchi, affiché après les résultats.
  SessionOutcome? _milestone;

  ReadingExercise get _exercise => widget.exercise;

  /// Des réponses données, pas encore enregistrées.
  bool _unsaved(SessionState session) =>
      session.answered > 0 && session.finishedAt == null;

  Future<void> _close() async {
    final session = ref.read(sessionProvider(_exercise));
    if (_unsaved(session) && !await _confirmQuit(context, session)) return;
    if (mounted) context.pop();
  }

  /// Après les résultats : le palier franchi s'il y en a un, sinon retour.
  Future<void> _continue() async {
    final outcome = await _outcome;
    if (!mounted) return;
    if (outcome != null && outcome.milestone && _milestone == null) {
      setState(() => _milestone = outcome);
    } else {
      context.pop();
    }
  }

  void _restart() {
    setState(() {
      _outcome = null;
      _milestone = null;
    });
    ref.invalidate(sessionProvider(_exercise));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider(_exercise));
    ref.listen(sessionProvider(_exercise), (previous, next) {
      if (previous?.phase == SessionPhase.asking &&
          next.phase == SessionPhase.feedback &&
          ref.read(settingsProvider).haptics) {
        // Courte si c'est juste, plus longue si c'est faux.
        unawaited(
          next.answers.last.correct
              ? HapticFeedback.lightImpact()
              : HapticFeedback.vibrate(),
        );
      }
      if (previous?.finishedAt != null) return;
      if (next.finishedAt case final finishedAt?) {
        setState(() {
          _outcome = ref
              .read(progressProvider.notifier)
              .recordSession(
                lessonId: widget.lessonId,
                startedAt: next.startedAt,
                finishedAt: finishedAt,
                answers: next.answers,
                bestCombo: next.bestCombo,
              );
        });
      }
    });

    return PopScope(
      // Retour du téléphone : même confirmation que la croix.
      canPop: !_unsaved(session),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: switch (_milestone) {
            final outcome? => _Milestone(outcome: outcome, onDone: _continue),
            null when session.phase == SessionPhase.finished => _Results(
              exercise: _exercise,
              session: session,
              onRestart: _restart,
              onContinue: _continue,
            ),
            null => _Exercise(
              exercise: _exercise,
              session: session,
              onClose: _close,
            ),
          },
        ),
      ),
    );
  }
}

class _Exercise extends ConsumerWidget {
  const _Exercise({
    required this.exercise,
    required this.session,
    required this.onClose,
  });

  final ReadingExercise exercise;
  final SessionState session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(sessionProvider(exercise).notifier);
    final (target, halo) = _targetColors(session, c);
    final question = session.question;
    final feedback = session.phase == SessionPhase.feedback;
    final caption = switch (exercise) {
      NoteReadingParams() || IdentifyNoteExercise() =>
        _accidentals(exercise)
            ? l10n.keyboardAccidentals
            : l10n.keyboardNaturals,
      IdentifyDurationExercise() => l10n.durationsHint,
      IdentifyMarkingExercise() => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          progress: session.answered / exercise.length,
          session: session,
          onClose: onClose,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.xl, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n
                    .readingProgress(
                      session.answered + (feedback ? 0 : 1),
                      exercise.length,
                      session.correct,
                    )
                    .toUpperCase(),
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.s),
              Text(switch (exercise) {
                IdentifyDurationExercise() => l10n.rhythmQuestion,
                IdentifyMarkingExercise() => l10n.markingQuestion,
                _ => l10n.noteQuestion,
              }, style: AppText.titlePrompt.copyWith(color: c.ink)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Space.ml),
            child: Center(
              // scaleDown : la portée garde sa taille, sauf si elle déborde.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NotationView(
                  system: question.system,
                  staffSpace: exercise is NoteReadingParams
                      ? StaffSpaces.exercise
                      : StaffSpaces.phrase,
                  options: exercise.layoutOptions,
                  color: c.ink,
                  highlights: {for (final ref in question.targets) ref: target},
                  halos: {for (final ref in question.targets) ref: halo},
                  decorationHighlights: {
                    for (final ref in question.decorationTargets) ref: target,
                  },
                  decorationHalos: {
                    for (final ref in question.decorationTargets) ref: halo,
                  },
                ),
              ),
            ),
          ),
        ),
        // Le panneau de correction recouvre les réponses, à leur place :
        // rien ne bouge au-dessus.
        Stack(
          children: [
            _Dock(
              caption: caption,
              child: _Answers(
                exercise: exercise,
                session: session,
                naming: settings.naming,
                keyLabels: settings.keyLabels,
                onAnswer: notifier.answer,
              ),
            ),
            if (feedback)
              Positioned.fill(
                child: _FeedbackSheet(
                  // Un panneau neuf par réponse : il remonte à chaque fois.
                  key: ValueKey(session.answered),
                  session: session,
                  naming: settings.naming,
                  onContinue: notifier.next,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Vrai si les touches noires du clavier sont ouvertes.
bool _accidentals(ReadingExercise exercise) => exercise.choices.any(
  (choice) => choice is NoteName && choice.accidental != null,
);

/// Couleur de la cible et de son halo : accent pendant la question, puis
/// vert ou rouge à la correction.
(Color, Color) _targetColors(SessionState session, NobemolColors c) =>
    switch (session.phase) {
      SessionPhase.asking => (c.accent, c.accentSoft),
      _ when session.choice == session.question.answer => (
        c.success,
        c.successSoft,
      ),
      _ => (c.danger, c.dangerSoft),
    };

/// Fermer, progression, combo, chrono.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.progress,
    required this.session,
    required this.onClose,
  });

  final double progress;
  final SessionState session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget pill({required Color color, required Widget child, Key? key}) =>
        Container(
          key: key,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: child,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.ml, 0),
      child: Row(
        children: [
          SizedBox.square(
            dimension: Sizes.minTarget,
            child: IconButton(
              key: const ValueKey('close'),
              tooltip: AppLocalizations.of(context).close,
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: c.ink),
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(child: ProgressBar(value: progress)),
          // Le combo se montre à partir de deux bonnes réponses d'affilée.
          if (session.combo >= 2) ...[
            const SizedBox(width: Space.s),
            pill(
              key: const ValueKey('combo'),
              color: c.accentSoft,
              child: Text(
                '×${session.combo}',
                style: AppText.metaLarge.copyWith(color: c.accentDeep),
              ),
            ),
          ],
          const SizedBox(width: Space.s),
          pill(
            color: c.surfaceInverse,
            child: _Chrono(
              session: session,
              style: AppText.metaLarge.copyWith(color: c.onSurfaceInverse),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bas de l'écran : une légende, puis les réponses. Toujours au moins
/// [Sizes.answerDock] de haut : la place du panneau de correction.
class _Dock extends StatelessWidget {
  const _Dock({required this.caption, required this.child});

  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.sheet),
        ),
        boxShadow: [BoxShadow(color: c.line, offset: const Offset(0, -1))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.m,
            Space.ml,
            Space.m,
            Space.l,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.answerDock),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (caption case final caption?) ...[
                  Text(
                    caption.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppText.meta.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: Space.m),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Réponses de l'exercice, colorées à la correction : la bonne en vert, la
/// mauvaise réponse donnée en rouge.
class _Answers extends StatelessWidget {
  const _Answers({
    required this.exercise,
    required this.session,
    required this.naming,
    required this.keyLabels,
    required this.onAnswer,
  });

  final ReadingExercise exercise;
  final SessionState session;
  final NoteNaming naming;

  /// Noms sur les touches blanches.
  final bool keyLabels;
  final ValueChanged<Enum> onAnswer;

  AnswerTone _tone(Enum choice) {
    if (session.phase != SessionPhase.feedback) return AnswerTone.rest;
    if (choice == session.question.answer) return AnswerTone.right;
    if (choice == session.choice) return AnswerTone.wrong;
    return AnswerTone.rest;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = exercise.choices;

    return switch (exercise) {
      NoteReadingParams() || IdentifyNoteExercise() => NoteKeyboard(
        label: (name) => l10n.noteFullName(name, naming: naming),
        whiteLabels: keyLabels,
        onKey: onAnswer,
        accidentals: _accidentals(exercise),
        tones: {
          for (final name in NoteName.values)
            if (_tone(name) != AnswerTone.rest) name: _tone(name),
        },
      ),
      IdentifyDurationExercise() => _Grid(
        columns: 4,
        children: [
          for (final choice in choices)
            _AnswerTile(
              key: ValueKey('answer-${choice.name}'),
              tone: _tone(choice),
              height: Sizes.answerTile,
              onPressed: () => onAnswer(choice),
              child: Text(
                l10n.beatsLabel(choice as Beats),
                style: AppText.labelKey.copyWith(fontSize: 24),
              ),
            ),
        ],
      ),
      IdentifyMarkingExercise() => _Grid(
        columns: 3,
        children: [
          for (final choice in choices)
            _AnswerTile(
              key: ValueKey('answer-${choice.name}'),
              tone: _tone(choice),
              height: Sizes.markingCard,
              radius: Radii.buttonLg,
              onPressed: () => onAnswer(choice),
              // Le sens seul : le signe se montre dans la correction.
              child: FitWordsText(
                l10n.markingLabel(choice as Marking),
                textAlign: TextAlign.center,
                style: AppText.labelCard,
              ),
            ),
        ],
      ),
    };
  }
}

/// Grille de colonnes égales, remplie ligne par ligne.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += columns)
          Padding(
            padding: EdgeInsets.only(top: start == 0 ? 0 : Space.s),
            child: Row(
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) const SizedBox(width: Space.xs),
                  Expanded(
                    child: i < children.length
                        ? children[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    super.key,
    required this.tone,
    required this.height,
    required this.onPressed,
    required this.child,
    this.radius = Radii.button,
  });

  final AnswerTone tone;
  final double height;
  final double radius;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      colors: context.colors.answer(tone),
      onPressed: onPressed,
      height: height,
      borderRadius: BorderRadius.circular(radius),
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Center(child: child),
    );
  }
}

/// Le panneau monte sur les réponses en ce temps.
const _sheetSlide = Duration(milliseconds: 200);

/// « Continuer » ne répond qu'après ce délai : le panneau arrive sous le
/// doigt, et une réponse touchée deux fois ne doit pas sauter la
/// correction.
const _continueLock = Duration(milliseconds: 300);

/// Panneau de correction, posé sur les réponses : juste ou faux, l'XP ou
/// le combo perdu, l'explication, et « Continuer », toujours au même
/// endroit. La question suivante l'attend, juste ou faux.
class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({
    super.key,
    required this.session,
    required this.naming,
    required this.onContinue,
  });

  final SessionState session;
  final NoteNaming naming;
  final VoidCallback onContinue;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  late final Timer _lock;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: _sheetSlide)..forward();
    _lock = Timer(_continueLock, () => _ready = true);
  }

  @override
  void dispose() {
    _slide.dispose();
    _lock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final session = widget.session;
    final naming = widget.naming;
    final question = session.question;
    final choice = session.choice!;
    final right = choice == question.answer;
    final xp = session.answers.last.xp;
    final meta = right
        ? [
            l10n.feedbackXp(xp),
            if (session.combo >= 2) l10n.feedbackCombo(session.combo),
          ].join(' · ')
        : session.lostCombo >= 2
        ? l10n.feedbackComboLost(session.lostCombo)
        : null;
    final tone = right ? c.success : c.danger;

    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic)),
      // Opaque : les réponses dessous ne se touchent plus.
      child: GestureDetector(
        key: const ValueKey('feedback'),
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: right ? c.successSoft : c.dangerSoft,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Radii.sheet),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.l,
                Space.l,
                Space.l,
                Space.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        right
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: tone,
                      ),
                      const SizedBox(width: Space.s),
                      Expanded(
                        child: Text(
                          l10n.feedbackTitle(
                            question,
                            right: right,
                            naming: naming,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.titleCard.copyWith(color: tone),
                        ),
                      ),
                      if (meta != null) ...[
                        const SizedBox(width: Space.s),
                        Text(
                          meta.toUpperCase(),
                          style: AppText.meta.copyWith(
                            color: right ? c.accentDeep : c.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!right) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      l10n.feedbackGiven(
                        l10n.answerLabel(choice, naming: naming),
                      ),
                      style: AppText.body.copyWith(fontSize: 14, color: c.ink),
                    ),
                  ],
                  const SizedBox(height: Space.s),
                  // Le signe d'un exercice de signes se voit déjà, coloré, sur
                  // la portée.
                  Expanded(
                    child: Text(
                      l10n.explain(question, naming: naming),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        color: c.inkMuted,
                      ),
                    ),
                  ),
                  DepthButton(
                    key: const ValueKey('continue'),
                    label: l10n.resultContinue,
                    variant: ButtonVariant.ink,
                    onPressed: () {
                      if (_ready) widget.onContinue();
                    },
                    expand: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fin de session : score, chrono, détail de l'XP, et ce qui est à revoir.
class _Results extends ConsumerWidget {
  const _Results({
    required this.exercise,
    required this.session,
    required this.onRestart,
    required this.onContinue,
  });

  final ReadingExercise exercise;
  final SessionState session;
  final VoidCallback onRestart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final naming = ref.watch(settingsProvider.select((s) => s.naming));
    final elapsed = session.finishedAt!.difference(session.startedAt);
    final base = session.correct * xpPerAnswer;
    final bonus = session.xp - base;
    final misses = _misses(session);

    Widget xpRow(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? AppText.titleCard.copyWith(fontSize: 15, color: c.ink)
                  : AppText.body.copyWith(color: c.inkMuted),
            ),
          ),
          Text(
            value,
            style: AppText.metaLarge.copyWith(
              color: strong ? c.accentDeep : c.ink,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xxl,
              Space.xl,
              Space.l,
            ),
            children: [
              Text(
                l10n.resultTitle.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.ml),
              Text(
                l10n.resultScore(session.correct, exercise.length),
                textAlign: TextAlign.center,
                style: AppText.displayXl.copyWith(color: c.ink, fontSize: 64),
              ),
              const SizedBox(height: Space.m),
              Text(
                l10n.resultTime(formatDuration(elapsed)),
                textAlign: TextAlign.center,
                style: AppText.bodyLarge.copyWith(color: c.inkMuted),
              ),
              if (session.bestCombo >= 2)
                Text(
                  l10n.resultCombo(session.bestCombo),
                  textAlign: TextAlign.center,
                  style: AppText.bodyLarge.copyWith(color: c.inkMuted),
                ),
              const SizedBox(height: Space.xl),
              AppTile(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.resultXpTitle.toUpperCase(),
                      style: AppText.meta.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: Space.s),
                    xpRow(
                      l10n.resultXpAnswers(session.correct, xpPerAnswer),
                      l10n.feedbackXp(base),
                    ),
                    if (bonus > 0)
                      xpRow(l10n.resultXpCombo, l10n.feedbackXp(bonus)),
                    Divider(color: c.line, height: Space.m),
                    xpRow(
                      l10n.resultXpTotal,
                      l10n.resultXp(session.xp),
                      strong: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(
                l10n.resultReview,
                style: AppText.titleCard.copyWith(color: c.ink),
              ),
              const SizedBox(height: Space.m),
              if (misses.isEmpty)
                Text(
                  l10n.resultNoMistake,
                  style: AppText.body.copyWith(color: c.inkMuted),
                )
              else
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    for (final (question, given) in misses)
                      _ReviewTile(
                        question: question,
                        given: given,
                        naming: naming,
                      ),
                  ],
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.s,
              Space.xl,
              Space.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DepthButton(
                  key: const ValueKey('result-continue'),
                  label: l10n.resultContinue,
                  onPressed: onContinue,
                  large: true,
                  expand: true,
                ),
                const SizedBox(height: Space.s),
                DepthButton(
                  label: l10n.resultRestart,
                  onPressed: onRestart,
                  variant: ButtonVariant.outline,
                  large: true,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Questions ratées, une fois chacune, dans l'ordre, avec la réponse
/// donnée. Une note compte par hauteur et par clé : un ré ratée deux fois
/// en clé de fa ne revient qu'une fois.
List<(Question, Enum)> _misses(SessionState session) {
  final seen = <Object>{};
  return [
    for (final (index, answer) in session.answers.indexed)
      if (!answer.correct)
        if (seen.add(_reviewKey(session.asked[index])))
          (session.asked[index], answer.given),
  ];
}

Object _reviewKey(Question question) => switch (question) {
  NoteQuestion(:final system, :final target, :final pitch, :final answer) => (
    system.staves.elementAt(target.staff).clef,
    pitch.diatonic,
    answer,
  ),
  _ => question.answer,
};

/// Une question à revoir : la note seule sur sa portée quand elle est
/// seule, la bonne réponse, et celle donnée.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.question,
    required this.given,
    required this.naming,
  });

  final Question question;
  final Enum given;
  final NoteNaming naming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final question = this.question;
    // Une phrase entière serait trop large : seulement la note seule.
    final alone =
        question is NoteQuestion &&
        question.system.staves.every((staff) => staff.notes.length <= 1);

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alone)
            NotationView(
              system: question.system,
              staffSpace: StaffSpaces.mini,
              color: c.ink,
              highlights: {question.target: c.danger},
            ),
          Text(
            l10n.answerLabel(question.answer, naming: naming),
            style: AppText.titleCard.copyWith(fontSize: 15, color: c.ink),
          ),
          Text(
            l10n.resultReviewGiven(l10n.answerLabel(given, naming: naming)),
            style: AppText.body.copyWith(fontSize: 12, color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Palier franchi : un niveau, une compétence maîtrisée, et ce qui se
/// débloque.
class _Milestone extends StatelessWidget {
  const _Milestone({required this.outcome, required this.onDone});

  final SessionOutcome outcome;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;

    Widget skills(String title, List<Skill> skills, IconData icon) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.xl),
        Text(
          title.toUpperCase(),
          style: AppText.meta.copyWith(color: c.inkMuted),
        ),
        for (final skill in skills)
          Padding(
            padding: const EdgeInsets.only(top: Space.s),
            child: AppTile(
              child: Row(
                children: [
                  Icon(icon, color: c.accent),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Text(
                      skill.title,
                      style: AppText.titleCard.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return Column(
      key: const ValueKey('milestone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xxl * 2,
              Space.xl,
              Space.l,
            ),
            children: [
              Text(
                (outcome.levelUp ? l10n.milestoneLevel : l10n.milestoneSkill)
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: AppText.meta.copyWith(color: c.accentDeep),
              ),
              const SizedBox(height: Space.ml),
              Text(
                outcome.levelUp
                    ? l10n.courseLevel(outcome.level.number)
                    : outcome.mastered.first.title,
                textAlign: TextAlign.center,
                style: AppText.displayXl.copyWith(color: c.ink),
              ),
              if (outcome.levelUp) ...[
                const SizedBox(height: Space.xl),
                ProgressBar(
                  value: outcome.level.progress / outcome.level.span,
                  color: c.accent,
                ),
                const SizedBox(height: Space.xs),
                Text(
                  l10n.courseLevelXp(
                    outcome.level.progress,
                    outcome.level.span,
                  ),
                  textAlign: TextAlign.center,
                  style: AppText.meta.copyWith(color: c.inkMuted),
                ),
              ],
              if (outcome.mastered.isNotEmpty)
                skills(
                  l10n.milestoneMastered,
                  outcome.mastered,
                  Icons.check_circle_rounded,
                ),
              if (outcome.unlocked.isNotEmpty)
                skills(
                  l10n.milestoneUnlocked,
                  outcome.unlocked,
                  Icons.lock_open_rounded,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.s,
              Space.xl,
              Space.xl,
            ),
            child: DepthButton(
              key: const ValueKey('milestone-continue'),
              label: l10n.resultContinue,
              onPressed: onDone,
              large: true,
              expand: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Demande avant de quitter une session commencée : ses réponses et son XP
/// seront perdus. Vrai pour quitter.
Future<bool> _confirmQuit(BuildContext context, SessionState session) async {
  final l10n = AppLocalizations.of(context);
  final c = context.colors;
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.quitTitle,
              style: AppText.titlePrompt.copyWith(color: c.ink),
            ),
            const SizedBox(height: Space.m),
            Text(
              l10n.quitBody(session.answered, session.xp),
              style: AppText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.xl),
            DepthButton(
              key: const ValueKey('quit-stay'),
              label: l10n.quitStay,
              onPressed: () => Navigator.pop(context, false),
              expand: true,
            ),
            const SizedBox(height: Space.s),
            DepthButton(
              key: const ValueKey('quit-leave'),
              label: l10n.quitLeave,
              variant: ButtonVariant.text,
              onPressed: () => Navigator.pop(context, true),
              expand: true,
            ),
          ],
        ),
      ),
    ),
  );
  return leave ?? false;
}

/// Chrono de la session, rafraîchi chaque seconde jusqu'à la fin.
class _Chrono extends ConsumerStatefulWidget {
  const _Chrono({required this.session, required this.style});

  final SessionState session;
  final TextStyle style;

  @override
  ConsumerState<_Chrono> createState() => _ChronoState();
}

class _ChronoState extends ConsumerState<_Chrono> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = widget.session.finishedAt ?? ref.read(clockProvider)();
    return Text(
      formatDuration(end.difference(widget.session.startedAt)),
      style: widget.style.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Durée au format m:ss.
String formatDuration(Duration duration) {
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '${duration.inMinutes}:$seconds';
}
