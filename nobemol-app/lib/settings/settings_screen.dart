import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/settings/choices.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/nobemol_icon.dart';

/// Version de l'appli, lue dans l'APK : « 1.0.0 (2) ».
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// Réglages : noms des notes, point de départ, objectif, retours, thème,
/// et à propos. Chaque changement est gardé tout de suite.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    void update(Settings Function(Settings settings) change) =>
        unawaited(ref.read(settingsProvider.notifier).update(change));

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.m),
      child: Text(
        title.toUpperCase(),
        style: AppText.meta.copyWith(color: c.inkMuted),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.s,
            Space.m,
            Space.l,
            Space.xl,
          ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.m, Space.m, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: AppText.titleScreen.copyWith(color: c.ink),
                  ),
                  section(l10n.settingsReading),
                  _Group(
                    children: [
                      _Row(
                        title: l10n.settingsNaming,
                        below: _Chips(
                          values: NoteNaming.values,
                          selected: settings.naming,
                          label: l10n.namingLabel,
                          keyPrefix: 'naming',
                          onSelect: (naming) =>
                              update((s) => s.copyWith(naming: naming)),
                        ),
                      ),
                      _Row(
                        title: l10n.settingsKeyLabels,
                        hint: l10n.settingsKeyLabelsHint,
                        trailing: _Switch(
                          key: const ValueKey('keyLabels'),
                          value: settings.keyLabels,
                          onChanged: (value) =>
                              update((s) => s.copyWith(keyLabels: value)),
                        ),
                      ),
                    ],
                  ),
                  section(l10n.settingsStart),
                  StartLevelChoices(
                    selected: settings.start,
                    onSelect: (level) =>
                        update((s) => s.copyWith(start: level)),
                  ),
                  section(l10n.settingsGoal),
                  DailyGoalChoices(
                    selected: settings.goal,
                    onSelect: (goal) => update((s) => s.copyWith(goal: goal)),
                  ),
                  section(l10n.settingsFeedback),
                  _Group(
                    children: [
                      _Row(
                        title: l10n.settingsHaptics,
                        hint: l10n.settingsHapticsHint,
                        trailing: _Switch(
                          key: const ValueKey('haptics'),
                          value: settings.haptics,
                          onChanged: (value) =>
                              update((s) => s.copyWith(haptics: value)),
                        ),
                      ),
                      // Pas encore d'audio : le réglage s'annonce.
                      _Row(
                        title: l10n.settingsSound,
                        muted: true,
                        trailing: Text(
                          l10n.comingSoon.toUpperCase(),
                          style: AppText.meta.copyWith(color: c.accentDeep),
                        ),
                      ),
                    ],
                  ),
                  section(l10n.settingsAppearance),
                  _Group(
                    children: [
                      _Row(
                        title: l10n.settingsTheme,
                        below: _Chips(
                          values: ThemeMode.values,
                          selected: settings.theme,
                          label: l10n.themeLabel,
                          keyPrefix: 'theme',
                          onSelect: (theme) =>
                              update((s) => s.copyWith(theme: theme)),
                        ),
                      ),
                    ],
                  ),
                  section(l10n.settingsAbout),
                  _Group(
                    children: [
                      _Row(
                        title: l10n.settingsUpdateCheck,
                        hint: l10n.settingsUpdateCheckHint,
                        trailing: _Switch(
                          key: const ValueKey('updateCheck'),
                          value: settings.updateCheck,
                          onChanged: (value) =>
                              update((s) => s.copyWith(updateCheck: value)),
                        ),
                      ),
                      _Row(
                        title: l10n.settingsVersion,
                        trailing: Text(
                          ref.watch(appVersionProvider).value ?? '',
                          style: AppText.metaLarge.copyWith(color: c.inkMuted),
                        ),
                      ),
                      _Row(
                        key: const ValueKey('licenses'),
                        title: l10n.settingsLicenses,
                        hint: l10n.settingsLicensesHint,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: c.inkMuted,
                        ),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: l10n.appTitle,
                          applicationVersion: ref
                              .read(appVersionProvider)
                              .value,
                          applicationIcon: const Padding(
                            padding: EdgeInsets.all(Space.m),
                            child: NobemolIcon(size: 64),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lignes de réglages dans une même surface, séparées d'un filet.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [
          BoxShadow(color: c.line, offset: const Offset(0, Depths.tile)),
        ],
      ),
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) Divider(height: 1, color: c.line),
            child,
          ],
        ],
      ),
    );
  }
}

/// Un réglage : son nom, une précision, et sa commande à droite ou dessous.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.title,
    this.hint,
    this.trailing,
    this.below,
    this.onTap,
    this.muted = false,
  });

  final String title;
  final String? hint;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  /// Réglage pas encore disponible.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.card),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.minTarget),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.titleCard.copyWith(
                            fontSize: 15,
                            color: muted ? c.inkMuted : c.ink,
                          ),
                        ),
                        if (hint case final hint?) ...[
                          const SizedBox(height: Space.xxs),
                          Text(
                            hint,
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              height: 1.3,
                              color: c.inkMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing case final trailing?) ...[
                    const SizedBox(width: Space.m),
                    trailing,
                  ],
                ],
              ),
            ),
            if (below case final below?) ...[
              const SizedBox(height: Space.s),
              below,
            ],
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: c.surface,
      activeTrackColor: c.accent,
      inactiveThumbColor: c.surface,
      inactiveTrackColor: c.line,
      trackOutlineColor: const WidgetStatePropertyAll(Color(0x00000000)),
    );
  }
}

/// Un choix court parmi quelques-uns, en puces.
class _Chips<T extends Enum> extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.selected,
    required this.label,
    required this.keyPrefix,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;

  /// Clé de chaque puce : `$keyPrefix-${value.name}`.
  final String keyPrefix;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: [
        for (final value in values)
          AppChip(
            key: ValueKey('$keyPrefix-${value.name}'),
            label: label(value),
            selected: value == selected,
            onTap: () => onSelect(value),
          ),
      ],
    );
  }
}
