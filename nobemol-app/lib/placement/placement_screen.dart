import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/arcade/game.dart' show rightFlash, wrongFlash;
import 'package:nobemol/audio/note_player.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/placement/placement.dart';
import 'package:nobemol/reading/answer_buttons.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/reading/session.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Test en cours. Neuf à chaque ouverture de l'écran.
final placementProvider =
    NotifierProvider.autoDispose<PlacementNotifier, PlacementState>(
      PlacementNotifier.new,
    );

/// Ce que montre l'écran du test.
class PlacementState {
  const PlacementState({
    required this.skill,
    required this.question,
    required this.progress,
    required this.passed,
    required this.answered,
    this.flash = false,
    this.choice,
  });

  /// Compétence en cours, `null` à la fin.
  final PlacementSkill? skill;
  final Question? question;
  final double progress;

  /// Compétences réussies, dans l'ordre de l'arbre.
  final List<String> passed;

  /// Questions posées : une clé par question.
  final int answered;

  /// La correction rapide de l'arcade, puis la question suivante.
  final bool flash;

  /// Réponse donnée pendant la correction, `null` pour « Je ne sais pas ».
  final Enum? choice;

  bool get finished => skill == null;
  bool get right => flash && choice == question?.answer;
}

class PlacementNotifier extends Notifier<PlacementState> {
  late PlacementTest _test;
  var _answered = 0;

  @override
  PlacementState build() {
    _test = PlacementTest(
      placementSkills(ref.watch(contentProvider)),
      ref.watch(randomProvider),
    );
    _answered = 0;
    return _snapshot();
  }

  PlacementState _snapshot() => PlacementState(
    skill: _test.current,
    question: _test.question,
    progress: _test.progress,
    passed: [
      for (final skill in _test.skills)
        if (_test.passed.contains(skill.skill.id)) skill.skill.id,
    ],
    answered: _answered,
  );

  List<Enum> get choices => _test.choices;

  /// Répond [choice], `null` pour « Je ne sais pas » : une erreur.
  void answer(Enum? choice) {
    if (state.flash || state.finished) return;
    state = PlacementState(
      skill: state.skill,
      question: state.question,
      progress: state.progress,
      passed: state.passed,
      answered: _answered,
      flash: true,
      choice: choice,
    );
  }

  /// Après la correction : la question suivante, ou le résultat.
  void next() {
    if (!state.flash) return;
    _test.answer(right: state.right);
    _answered++;
    state = _snapshot();
  }
}

/// Test de positionnement : des questions de lecture, de plus en plus
/// dures tant que l'élève réussit, puis son point de départ.
///
/// Rend les compétences acquises, ou `null` si l'élève quitte ou préfère
/// choisir lui-même. Rien n'est gardé ici : ni XP, ni réponse, ni carte de
/// révision. L'appelant garde le résultat dans les réglages.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  Timer? _flash;

  @override
  void initState() {
    super.initState();
    ref.loadNotes();
  }

  @override
  void dispose() {
    _flash?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placementProvider);
    ref.listen(placementProvider, (previous, next) {
      if (previous?.flash == false && next.flash) {
        ref.playNote(next.question!);
        if (ref.read(settingsProvider).haptics) {
          unawaited(
            next.right
                ? HapticFeedback.lightImpact()
                : HapticFeedback.vibrate(),
          );
        }
        _flash?.cancel();
        _flash = Timer(
          next.right ? rightFlash : wrongFlash,
          ref.read(placementProvider.notifier).next,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: state.finished
            ? _Result(passed: state.passed)
            : _Question(state: state),
      ),
    );
  }
}

class _Question extends ConsumerWidget {
  const _Question({required this.state});

  final PlacementState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(placementProvider.notifier);
    final skill = state.skill!;
    final question = state.question!;
    final choices = notifier.choices;
    final (target, halo) = !state.flash
        ? (c.accent, c.accentSoft)
        : state.right
        ? (c.success, c.successSoft)
        : (c.danger, c.dangerSoft);

    AnswerTone tone(Enum choice) {
      if (!state.flash) return AnswerTone.rest;
      if (choice == question.answer) return AnswerTone.right;
      if (choice == state.choice) return AnswerTone.wrong;
      return AnswerTone.rest;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.ml, 0),
          child: Row(
            children: [
              SizedBox.square(
                dimension: Sizes.minTarget,
                child: IconButton(
                  key: const ValueKey('close'),
                  tooltip: l10n.placementQuit,
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close_rounded, color: c.ink),
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(child: ProgressBar(value: state.progress)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.m, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.skill.title.toUpperCase(),
                      key: const ValueKey('placement-skill'),
                      style: AppText.meta.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: Space.s),
                    Text(
                      questionTitle(l10n, question),
                      style: AppText.titlePrompt.copyWith(color: c.ink),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('placement-unknown'),
                onPressed: state.flash ? null : () => notifier.answer(null),
                child: Text(l10n.placementUnknown),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Space.ml),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NotationView(
                  system: question.system,
                  // Une note seule en grand, une phrase à sa taille.
                  staffSpace: skill.exercise is NoteReadingParams
                      ? StaffSpaces.exercise
                      : StaffSpaces.phrase,
                  options: skill.exercise.layoutOptions,
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
        AnswerDock(
          caption: answerCaption(l10n, question, choices),
          child: AnswerButtons(
            // Des réponses neuves par question : rien ne reste appuyé.
            key: ValueKey(state.answered),
            question: question,
            choices: choices,
            tone: tone,
            onAnswer: state.flash ? null : notifier.answer,
            naming: settings.naming,
            keyLabels: settings.keyLabels,
          ),
        ),
      ],
    );
  }
}

/// Le point de départ trouvé : les compétences acquises, ou le début.
class _Result extends ConsumerWidget {
  const _Result({required this.passed});

  final List<String> passed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final content = ref.watch(contentProvider);
    final titles = {for (final skill in content.skills) skill.id: skill.title};

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
                l10n.placementResultMeta.toUpperCase(),
                style: AppText.meta.copyWith(color: c.accentDeep),
              ),
              const SizedBox(height: Space.m),
              Text(
                passed.isEmpty
                    ? l10n.placementResultNoneTitle
                    : l10n.placementResultTitle(passed.length),
                key: const ValueKey('placement-result'),
                style: AppText.titleScreen.copyWith(color: c.ink),
              ),
              const SizedBox(height: Space.s),
              Text(
                passed.isEmpty
                    ? l10n.placementResultNoneBody
                    : l10n.placementResultBody,
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.xl),
              for (final id in passed)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: c.success),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Text(
                          titles[id] ?? id,
                          style: AppText.body.copyWith(color: c.ink),
                        ),
                      ),
                    ],
                  ),
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
                  key: const ValueKey('placement-done'),
                  label: l10n.placementContinue,
                  onPressed: () => context.pop(passed.toSet()),
                  large: true,
                  expand: true,
                ),
                const SizedBox(height: Space.s),
                DepthButton(
                  key: const ValueKey('placement-choose'),
                  label: l10n.placementChoose,
                  onPressed: () => context.pop(),
                  variant: ButtonVariant.text,
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
