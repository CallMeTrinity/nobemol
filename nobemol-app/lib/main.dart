import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/router.dart';
import 'package:nobemol/theme/theme.dart';

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

class NobemolApp extends ConsumerWidget {
  const NobemolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      // Clair ou sombre selon le téléphone, en attendant les réglages.
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
