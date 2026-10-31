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
import 'package:nobemol/ui/nobemol_icon.dart';
import 'package:nobemol/ui/progress_bar.dart';

/// Premier lancement : bienvenue, point de départ, objectif du jour. Les
/// deux choix sont gardés à la fin seulement : un démarrage interrompu
/// recommence. Avec une sauvegarde, rien à choisir : elle a ses réglages.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Écrans après la bienvenue.
const _steps = 2;

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// 0 : bienvenue, puis les étapes de 1 à [_steps].
  var _step = 0;
  StartLevel? _start;
  DailyGoal? _goal;

  Future<void> _finish() async {
    await ref
        .read(settingsProvider.notifier)
        .update(
          (settings) =>
              settings.copyWith(onboarded: true, start: _start, goal: _goal),
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
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (_step) {
            0 => _Welcome(
              onStart: () => setState(() => _step = 1),
              onRestore: () => unawaited(_restore()),
            ),
            1 => _Step(
              step: 1,
              title: l10n.onboardingLevelTitle,
              body: l10n.onboardingLevelBody,
              onBack: () => setState(() => _step = 0),
              action: l10n.onboardingNext,
              onAction: _start == null ? null : () => setState(() => _step = 2),
              child: StartLevelChoices(
                selected: _start,
                onSelect: (level) => setState(() => _start = level),
              ),
            ),
            _ => _Step(
              step: 2,
              title: l10n.onboardingGoalTitle,
              body: l10n.onboardingGoalBody,
              onBack: () => setState(() => _step = 1),
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
