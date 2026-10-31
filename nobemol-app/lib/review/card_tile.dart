import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/tokens.dart';

/// Une question ratée : sa portée en petit si [staff], la bonne réponse,
/// et une légende (la réponse donnée, le nombre d'erreurs).
class CardTile extends ConsumerWidget {
  const CardTile({
    super.key,
    required this.question,
    required this.caption,
    this.staff = true,
  });

  final Question question;
  final String caption;
  final bool staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final naming = ref.watch(settingsProvider.select((s) => s.naming));

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
          if (staff)
            NotationView(
              system: question.system,
              staffSpace: StaffSpaces.mini,
              color: c.ink,
              highlights: {for (final ref in question.targets) ref: c.danger},
              decorationHighlights: {
                for (final ref in question.decorationTargets) ref: c.danger,
              },
            ),
          Text(
            l10n.answerLabel(question.answer, naming: naming),
            style: AppText.titleCard.copyWith(fontSize: 15, color: c.ink),
          ),
          Text(
            caption,
            style: AppText.body.copyWith(fontSize: 12, color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
