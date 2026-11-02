import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/reading/rhythm_tapper.dart';
import 'package:nobemol/reading/tapping.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// Calage du rythme tapé : taper sur 12 clics, après une mesure de
/// décompte. Le retard médian entre clic et touche devient le calage du
/// téléphone (`Settings.tapLatency`), déduit de chaque touche du rythme
/// tapé.
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  /// Essais passés : chacun a son bouton neuf.
  var _attempt = 0;

  /// Résultat du dernier essai : le décalage, ou `null` s'il a échoué.
  Duration? _measured;
  var _done = false;

  void _retry() => setState(() {
    _attempt++;
    _done = false;
    _measured = null;
  });

  Future<void> _save() async {
    final latency = _measured!.inMilliseconds;
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(tapLatency: latency));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final measured = _measured;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s,
            Space.m,
            Space.l,
            Space.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: Sizes.minTarget,
                  child: IconButton(
                    key: const ValueKey('back'),
                    tooltip: l10n.back,
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(Space.m, Space.m, 0, 0),
                  children: [
                    Text(
                      l10n.calibrationTitle,
                      style: AppText.titleScreen.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: Space.m),
                    Text(
                      l10n.calibrationIntro,
                      style: AppText.bodyLarge.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: Space.s),
                    Text(
                      l10n.calibrationHow,
                      style: AppText.bodyLarge.copyWith(color: c.inkMuted),
                    ),
                    if (_done) ...[
                      const SizedBox(height: Space.xl),
                      if (measured != null) ...[
                        Text(
                          l10n.calibrationResult(measured.inMilliseconds),
                          key: const ValueKey('calibration-result'),
                          textAlign: TextAlign.center,
                          style: AppText.displayXl.copyWith(color: c.ink),
                        ),
                        const SizedBox(height: Space.s),
                        Text(
                          l10n.calibrationResultHint,
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(color: c.inkMuted),
                        ),
                      ] else
                        Text(
                          l10n.calibrationFailed,
                          key: const ValueKey('calibration-failed'),
                          textAlign: TextAlign.center,
                          style: AppText.bodyLarge.copyWith(color: c.danger),
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: Space.m),
                child: _done
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (measured != null) ...[
                            DepthButton(
                              key: const ValueKey('calibration-save'),
                              label: l10n.calibrationSave,
                              onPressed: () => unawaited(_save()),
                              large: true,
                              expand: true,
                            ),
                            const SizedBox(height: Space.s),
                          ],
                          DepthButton(
                            key: const ValueKey('calibration-retry'),
                            label: l10n.calibrationRetry,
                            variant: measured == null
                                ? ButtonVariant.primary
                                : ButtonVariant.outline,
                            onPressed: _retry,
                            large: true,
                            expand: true,
                          ),
                        ],
                      )
                    : RhythmTapper(
                        key: ValueKey('calibration-$_attempt'),
                        track: calibrationTrack,
                        idleLabel: l10n.calibrationStart,
                        tapLabel: l10n.calibrationTap,
                        // Une vibration, pas de son : un son de touche se
                        // calerait sur le clic à l'oreille, et fausserait
                        // la mesure.
                        onTap: (_) {
                          if (ref.read(settingsProvider).haptics) {
                            unawaited(HapticFeedback.lightImpact());
                          }
                        },
                        onDone: (taps) => setState(() {
                          _done = true;
                          _measured = calibrate(taps);
                        }),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
