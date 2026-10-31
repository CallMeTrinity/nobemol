import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/review/card.dart';
import 'package:nobemol/review/card_tile.dart';
import 'package:nobemol/review/deck.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// Réponse et correction, en secondes : le rythme de l'objectif du jour.
const _secondsPerCard = 10;

/// Les plus difficiles montrées, au plus.
const _hardestShown = 6;

/// Onglet Réviser : la révision du jour, les cartes nouvelles et acquises,
/// et les plus difficiles.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final deck = Deck(
      ref.watch(contentProvider),
      ref.watch(progressProvider).cards.values,
      ref.watch(clockProvider)(),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 36, Space.l, Space.xl),
        children: [
          Text(
            l10n.tabReview,
            style: AppText.titleScreen.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.xl),
          if (deck.cards.isEmpty)
            Text(
              l10n.reviewEmpty,
              style: AppText.body.copyWith(color: c.inkMuted),
            )
          else ...[
            _Today(deck: deck),
            const SizedBox(height: Space.m),
            Row(
              children: [
                _Count(label: l10n.reviewDue, count: deck.due.length),
                const SizedBox(width: Space.sm),
                _Count(label: l10n.reviewFresh, count: deck.fresh),
                const SizedBox(width: Space.sm),
                _Count(label: l10n.reviewAcquired, count: deck.acquired),
              ],
            ),
            const SizedBox(height: Space.m),
            Text(
              l10n.reviewRule,
              style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
            ),
            if (deck.hardest.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: Space.xl, bottom: Space.m),
                child: Text(
                  l10n.reviewHardest,
                  style: AppText.titleCard.copyWith(color: c.ink),
                ),
              ),
              Wrap(
                spacing: Space.s,
                runSpacing: Space.s,
                children: [
                  for (final card in deck.hardest.take(_hardestShown))
                    if (questionOf(card.card) case final question?)
                      CardTile(
                        key: ValueKey('hard-${card.card}'),
                        question: question,
                        caption: l10n.reviewMisses(card.misses),
                      ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// La révision du jour, ou quand revient la prochaine carte.
class _Today extends StatelessWidget {
  const _Today({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final session = deck.session();
    final days = deck.daysToNext;

    return AppTile(
      highlighted: session != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.reviewToday.toUpperCase(),
            style: AppText.meta.copyWith(
              color: session != null ? c.accentDeep : c.inkMuted,
            ),
          ),
          const SizedBox(height: Space.s),
          Text(switch (session) {
            final session? => l10n.reviewSession(
              session.length,
              (session.length * _secondsPerCard / 60).ceil(),
            ),
            null => l10n.reviewNothing,
          }, style: AppText.titleCard.copyWith(fontSize: 15, color: c.ink)),
          if (session == null && days != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              l10n.reviewNext(days),
              style: AppText.body.copyWith(fontSize: 13, color: c.inkMuted),
            ),
          ],
          if (session != null) ...[
            const SizedBox(height: Space.m),
            DepthButton(
              key: const ValueKey('review-start'),
              label: l10n.reviewStart,
              // La route garde cette session telle quelle, même quand la
              // progression change à la fin.
              onPressed: () => context.push('/reviser/session', extra: session),
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Un nombre de cartes et ce qu'il compte.
class _Count extends StatelessWidget {
  const _Count({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: AppTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count', style: AppText.titleScreen.copyWith(color: c.ink)),
            const SizedBox(height: Space.xxs),
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
