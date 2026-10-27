import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/router.dart';

void main() {
  runApp(const ProviderScope(child: NobemolApp()));
}

/// Couleurs de l'identité visuelle (nobemol-icone.svg).
const _ink = Color(0xFF1C2033);
const _paper = Color(0xFFF4EEE2);
const _accent = Color(0xFFEF5B36);

class NobemolApp extends ConsumerWidget {
  const NobemolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _ink,
          primary: _ink,
          secondary: _accent,
          surface: _paper,
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
