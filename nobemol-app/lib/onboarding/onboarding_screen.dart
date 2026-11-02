import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/backup/backup_actions.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/settings/choices.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/motion.dart';
import 'package:nobemol/ui/nobemol_icon.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Premier lancement : bienvenue, point de départ, objectif du jour.
///
/// Le point de départ se trouve par le test de positionnement, ou se
/// choisit à la main. Les choix sont gardés à la fin seulement : un
/// démarrage interrompu recommence. Avec une sauvegarde, rien à choisir :
/// elle a ses réglages.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Écrans après la bienvenue, dans la barre de progression.
const _steps = 2;

enum _Page {
  welcome,

  /// Débutant, ou le test.
  start,

  /// Les 4 points de départ, à la main.
  manual,
  goal,
}

/// Réponse à « Tu lis déjà la musique ? ».
enum _Start { beginner, test }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Pages ouvertes, la dernière à l'écran : le retour revient à celle
  /// d'avant.
  final _pages = [_Page.welcome];
  _Start? _answer;

  /// Point de départ choisi à la main.
  StartLevel? _start;

  /// Compétences du test, une fois passé.
  Set<String>? _placement;
  DailyGoal? _goal;

  _Page get _page => _pages.last;

  void _open(_Page page) => setState(() => _pages.add(page));

  void _back() => setState(() => _pages.removeLast());

  /// Le test, puis l'objectif. Quitté ou « Je préfère choisir » : le
  /// choix à la main.
  Future<void> _test() async {
    final placement = await context.push<Set<String>>('/positionnement');
    if (!mounted) return;
    setState(() {
      if (placement == null) {
        _pages.add(_Page.manual);
      } else {
        _placement = placement;
        _start = null;
        _pages.add(_Page.goal);
      }
    });
  }

  void _next() {
    switch (_answer) {
      case _Start.beginner:
        _start = StartLevel.beginner;
        _placement = null;
        _open(_Page.goal);
      case _Start.test when _placement != null:
        _start = null;
        _open(_Page.goal);
      case _Start.test:
        unawaited(_test());
      case null:
    }
  }

  Future<void> _finish() async {
    // Le dernier choix fait foi : le test, ou un point de départ.
    final placement = _start == null ? _placement : null;
    await ref
        .read(settingsProvider.notifier)
        .update(
          (settings) => settings.copyWith(
            onboarded: true,
            start: _start ?? StartLevel.beginner,
            placement: () => placement,
            goal: _goal,
          ),
        );
    if (mounted) context.go('/');
  }

  Future<void> _restore() async {
    if (await importBackup(context, ref) && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      // Retour du téléphone : l'écran d'avant, puis quitter l'appli.
      canPop: _pages.length == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          // Une page à la fois : la suivante arrive par la droite.
          child: FadeSwitcher(
            offset: const Offset(0.04, 0),
            child: KeyedSubtree(
              key: ValueKey(_page),
              child: switch (_page) {
                _Page.welcome => _Welcome(
                  onStart: () => _open(_Page.start),
                  onRestore: () => unawaited(_restore()),
                ),
                _Page.start => _Step(
                  step: 1,
                  title: l10n.onboardingStartTitle,
                  body: l10n.onboardingStartBody,
                  onBack: _back,
                  action: _answer == _Start.test && _placement == null
                      ? l10n.onboardingStartTest
                      : l10n.onboardingNext,
                  onAction: _answer == null ? null : _next,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ChoiceTile(
                        key: const ValueKey('start-new'),
                        title: l10n.startBeginnerTitle,
                        subtitle: l10n.startBeginnerDescription,
                        selected: _answer == _Start.beginner,
                        onTap: () => setState(() => _answer = _Start.beginner),
                      ),
                      ChoiceTile(
                        key: const ValueKey('start-test'),
                        title: l10n.startTestTitle,
                        subtitle: switch (_placement) {
                          final placement? => l10n.startTestDone(
                            placement.length,
                          ),
                          null => l10n.startTestDescription,
                        },
                        selected: _answer == _Start.test,
                        onTap: () => setState(() => _answer = _Start.test),
                      ),
                      const SizedBox(height: Space.s),
                      Center(
                        child: TextButton(
                          key: const ValueKey('start-choose'),
                          onPressed: () => _open(_Page.manual),
                          child: Text(l10n.onboardingChoose),
                        ),
                      ),
                    ],
                  ),
                ),
                _Page.manual => _Step(
                  step: 1,
                  title: l10n.onboardingLevelTitle,
                  body: l10n.onboardingLevelBody,
                  onBack: _back,
                  action: l10n.onboardingNext,
                  onAction: _start == null
                      ? null
                      : () {
                          _placement = null;
                          _open(_Page.goal);
                        },
                  child: StartLevelChoices(
                    selected: _start,
                    onSelect: (level) => setState(() => _start = level),
                  ),
                ),
                _Page.goal => _Step(
                  step: 2,
                  title: l10n.onboardingGoalTitle,
                  body: l10n.onboardingGoalBody,
                  onBack: _back,
                  action: l10n.onboardingDone,
                  onAction: _goal == null ? null : () => unawaited(_finish()),
                  child: DailyGoalChoices(
                    selected: _goal,
                    onSelect: (goal) => setState(() => _goal = goal),
                  ),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart, required this.onRestore});

  final VoidCallback onStart;

  /// « J'ai déjà une sauvegarde » : l'import, à la place du démarrage.
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NobemolIcon(size: 96),
                const SizedBox(height: Space.xxl),
                Text(
                  l10n.appTitle.toUpperCase(),
                  style: AppText.meta.copyWith(color: c.accentDeep),
                ),
                const SizedBox(height: Space.m),
                Text(
                  l10n.welcomeTitle,
                  style: AppText.displayXl.copyWith(color: c.ink),
                ),
                const SizedBox(height: Space.ml),
                Text(
                  l10n.welcomeBody,
                  style: AppText.bodyLarge.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          DepthButton(
            key: const ValueKey('onboarding-action'),
            label: l10n.welcomeStart,
            onPressed: onStart,
            large: true,
            expand: true,
          ),
          const SizedBox(height: Space.s),
          DepthButton(
            key: const ValueKey('onboarding-restore'),
            label: l10n.welcomeRestore,
            onPressed: onRestore,
            variant: ButtonVariant.text,
            expand: true,
          ),
        ],
      ),
    );
  }
}

/// Une étape : retour et avancement, la question, les choix, et le bouton
/// pour passer à la suite, inactif tant que rien n'est choisi.
class _Step extends StatelessWidget {
  const _Step({
    required this.step,
    required this.title,
    required this.body,
    required this.onBack,
    required this.action,
    required this.onAction,
    required this.child,
  });

  final int step;
  final String title;
  final String body;
  final VoidCallback onBack;
  final String action;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.xl, 0),
          child: Row(
            children: [
              SizedBox.square(
                dimension: Sizes.minTarget,
                child: IconButton(
                  key: const ValueKey('back'),
                  tooltip: l10n.back,
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: ProgressBar(value: step / _steps, color: c.accent),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xl,
              Space.xl,
              Space.l,
            ),
            children: [
              Text(
                l10n.onboardingStep(step, _steps).toUpperCase(),
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.s),
              Text(title, style: AppText.titlePrompt.copyWith(color: c.ink)),
              const SizedBox(height: Space.s),
              Text(body, style: AppText.body.copyWith(color: c.inkMuted)),
              const SizedBox(height: Space.xl),
              child,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: DepthButton(
            key: const ValueKey('onboarding-action'),
            label: action,
            onPressed: onAction,
            large: true,
            expand: true,
          ),
        ),
      ],
    );
  }
}
