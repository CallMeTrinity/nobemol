import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/licenses.dart';
import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/progress_provider.dart';
import 'package:nobemol/router.dart';
import 'package:nobemol/settings/settings.dart';
import 'package:nobemol/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Quelques Ko de YAML : chargés avant le premier écran, puis lus sans
  // attente partout dans l'appli.
  final content = await loadContent(rootBundle);
  // Progression : quelques centaines de lignes, lues de même au démarrage.
  final store = ProgressStore(NobemolDatabase(openDatabase()));
  final progress = await store.load();
  // Réglages : lus avant le premier écran, qui en dépend (démarrage, thème).
  final settingsStore = SettingsStore(await SharedPreferences.getInstance());
  final settings = settingsStore.load();
  registerFontLicenses(rootBundle);
  runApp(
    ProviderScope(
      overrides: [
        contentProvider.overrideWithValue(content),
        progressProvider.overrideWith(() => ProgressNotifier(store, progress)),
        settingsProvider.overrideWith(
          () => SettingsNotifier(settingsStore, settings),
        ),
      ],
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
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(settingsProvider.select((s) => s.theme)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
