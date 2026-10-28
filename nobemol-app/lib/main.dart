import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Quelques Ko de YAML : chargés avant le premier écran, puis lus sans
  // attente partout dans l'appli.
  final content = await loadContent(rootBundle);
  runApp(
    ProviderScope(
      overrides: [contentProvider.overrideWithValue(content)],
      child: const NobemolApp(),
    ),
  );
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
