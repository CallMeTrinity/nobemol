import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/explanations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/profile/stats.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// Précision à partir de laquelle une note est lue sans peine : le seuil
/// de maîtrise.
const _good = 0.8;

/// En dessous, une note à travailler.
const _weak = 0.5;

/// Statistiques sur 7 jours, 30 jours ou tout : XP face à l'objectif,
/// temps, précision par clé et par note.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  var _period = StatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final stats = Stats(
      ref.watch(progressProvider),
      period: _period,
      now: ref.watch(clockProvider)(),
      dailyGoal: ref.watch(settingsProvider.select((s) => s.goal.xp)),
    );
    final naming = ref.watch(settingsProvider.select((s) => s.naming));

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.m),
      child: Text(title, style: AppText.titleCard.copyWith(color: c.ink)),
    );
    Widget muted(String text) =>
        Text(text, style: AppText.body.copyWith(color: c.inkMuted));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.l, Space.xl),
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
                  l10n.statsTitle,
                  style: AppText.titleScreen.copyWith(color: c.ink),
                ),
                const SizedBox(height: Space.l),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    for (final period in StatsPeriod.values)
                      AppChip(
                        key: ValueKey('period-${period.name}'),
                        label: l10n.statsPeriod(period),
                        selected: period == _period,
                        onTap: () => setState(() => _period = period),
                      ),
                  ],
                ),
                const SizedBox(height: Space.xl),
                if (stats.sessions == 0)
                  muted(l10n.statsEmpty)
                else ...[
                  _XpTile(stats: stats),
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      _Figure(
                        value: _duration(l10n, stats.practice),
                        label: l10n.statsPractice,
                      ),
                      const SizedBox(width: Space.sm),
                      _Figure(
                        value: switch (stats.timePerNote) {
                          final time? => l10n.arcadeSeconds(
                            (time.inMilliseconds / 1000)
                                .toStringAsFixed(1)
                                .replaceAll('.', ','),
                          ),
                          null => '–',
                        },
                        label: l10n.statsTimePerNote,
                      ),
                    ],
                  ),
                ],
                section(l10n.statsNotes),
                if (stats.clefs.isEmpty)
                  muted(l10n.statsNotesEmpty)
                else ...[
                  Text(
                    l10n.statsNotesHint,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      color: c.inkMuted,
                    ),
                  ),
                  for (final MapEntry(key: clef, value: clefStats)
                      in stats.clefs.entries) ...[
                    const SizedBox(height: Space.m),
                    AppTile(
                      key: ValueKey('clef-${clef.sign.name}${clef.line}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _capitalize(l10n.clefName(clef)),
                                  style: AppText.titleCard.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                '${(clefStats.total.ratio * 100).round()} %',
                                style: AppText.metaLarge.copyWith(color: c.ink),
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.m),
                          Wrap(
                            spacing: Space.xs,
                            runSpacing: Space.xs,
                            children: [
                              for (final MapEntry(key: name, value: accuracy)
                                  in clefStats.notes.entries)
                                _NoteAccuracy(
                                  label: l10n.noteFullName(
                                    name,
                                    naming: naming,
                                  ),
                                  accuracy: accuracy,
                                  name: name,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// XP de la période, barres et objectif.
class _XpTile extends StatelessWidget {
  const _XpTile({required this.stats});

  final Stats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final dates = MaterialLocalizations.of(context);
    final weekly = stats.period == StatsPeriod.all;
    final goalDays = stats.goalDays;

    return AppTile(
      key: const ValueKey('stats-xp'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l10n.statsXp,
                  style: AppText.titleCard.copyWith(fontSize: 15),
                ),
              ),
              Text(
                l10n.statsXpTotal(stats.xp),
                style: AppText.metaLarge.copyWith(color: c.ink),
              ),
            ],
          ),
          if (goalDays != null) ...[
            const SizedBox(height: Space.xxs),
            Text(
              l10n.statsGoalDays(goalDays, stats.bars.length),
              style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
            ),
          ],
          const SizedBox(height: Space.m),
          Semantics(
            label: l10n.statsXpTotal(stats.xp),
            child: SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _BarsPainter(
                  bars: [for (final bar in stats.bars) bar.xp],
                  goal: stats.barGoal,
                  bar: c.accent,
                  reached: c.success,
                  goalLine: c.inkMuted,
                  track: c.line,
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.s),
          // Sur un petit écran, la légende passe sous la date.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: Space.m,
            runSpacing: Space.xs,
            children: [
              Text(
                dates.formatCompactDate(stats.bars.first.start),
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
              Text(
                (weekly
                        ? l10n.statsGoalWeek(stats.barGoal)
                        : l10n.statsGoalDay(stats.barGoal))
                    .toUpperCase(),
                style: AppText.meta.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une barre par jour (ou semaine), verte si l'objectif est atteint, et le
/// trait de l'objectif.
class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.bars,
    required this.goal,
    required this.bar,
    required this.reached,
    required this.goalLine,
    required this.track,
  });

  final List<int> bars;
  final int goal;
  final Color bar;
  final Color reached;
  final Color goalLine;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final top = max(goal, bars.reduce(max)) * 1.1;
    final slot = size.width / bars.length;
    final gap = min(slot * 0.25, 4.0);
    final radius = Radius.circular(min((slot - gap) / 2, 4));
    for (final (index, xp) in bars.indexed) {
      final height = xp == 0 ? 2.0 : max(size.height * xp / top, 3.0);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            index * slot + gap / 2,
            size.height - height,
            slot - gap,
            height,
          ),
          topLeft: radius,
          topRight: radius,
        ),
        Paint()..color = xp == 0 ? track : (xp >= goal ? reached : bar),
      );
    }
    final y = size.height - size.height * goal / top;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = goalLine
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.goal != goal ||
      old.bar != bar ||
      old.bars.length != bars.length ||
      !old.bars.indexed.every((entry) => bars[entry.$1] == entry.$2);
}

/// Un chiffre et ce qu'il compte.
class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: AppTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppText.titlePrompt.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une note et sa précision : verte, orangée ou rouge.
class _NoteAccuracy extends StatelessWidget {
  const _NoteAccuracy({
    required this.label,
    required this.accuracy,
    required this.name,
  });

  final String label;
  final Accuracy accuracy;
  final NoteName name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = accuracy.ratio;
    final (background, foreground) = ratio >= _good
        ? (c.successSoft, c.success)
        : ratio >= _weak
        ? (c.warningSoft, c.warningInk)
        : (c.dangerSoft, c.danger);
    return Container(
      key: ValueKey('note-${name.name}'),
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Column(
        children: [
          Text(label, style: AppText.labelTab.copyWith(color: c.ink)),
          const SizedBox(height: Space.xxs),
          Text(
            '${(ratio * 100).round()} %',
            style: AppText.meta.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// « 12 min », « 1 h 05 ».
String _duration(AppLocalizations l10n, Duration duration) {
  final minutes = duration.inMinutes;
  return minutes < 60
      ? l10n.statsMinutes(minutes)
      : l10n.statsHours(
          minutes ~/ 60,
          (minutes % 60).toString().padLeft(2, '0'),
        );
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

extension on AppLocalizations {
  String statsPeriod(StatsPeriod period) => switch (period) {
    StatsPeriod.week => statsWeek,
    StatsPeriod.month => statsMonth,
    StatsPeriod.all => statsAll,
  };
}
