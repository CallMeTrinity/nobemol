import 'package:flutter/material.dart';

import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';

/// Demande avant une action qui perd quelque chose. Le bouton principal
/// est le plus sûr ([stay]) ; [leave] fait l'action. Vrai pour [leave].
///
/// Boutons `$keyPrefix-stay` et `$keyPrefix-leave`.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String stay,
  required String leave,
  required String keyPrefix,
}) async {
  final c = context.colors;
  final confirmed = await showDialog<bool>(
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
            Text(title, style: AppText.titlePrompt.copyWith(color: c.ink)),
            const SizedBox(height: Space.m),
            Text(body, style: AppText.body.copyWith(color: c.inkMuted)),
            const SizedBox(height: Space.xl),
            DepthButton(
              key: ValueKey('$keyPrefix-stay'),
              label: stay,
              onPressed: () => Navigator.pop(context, false),
              expand: true,
            ),
            const SizedBox(height: Space.s),
            DepthButton(
              key: ValueKey('$keyPrefix-leave'),
              label: leave,
              variant: ButtonVariant.text,
              onPressed: () => Navigator.pop(context, true),
              expand: true,
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}
