import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/start_level.dart';

/// Noms des notes à l'écran : do-ré-mi ou C-D-E. Le modèle reste en
/// lettres.
enum NoteNaming { solfege, letters }

/// Réglages de l'élève, gardés dans `shared_preferences`.
class Settings {
  const Settings({
    this.onboarded = false,
    this.naming = NoteNaming.solfege,
    this.start = StartLevel.beginner,
    this.keyLabels = true,
    this.goal = DailyGoal.five,
    this.haptics = true,
    this.theme = ThemeMode.system,
    this.updateCheck = true,
  });

  /// Le démarrage (bienvenue, point de départ, objectif) est passé.
  final bool onboarded;
  final NoteNaming naming;
  final StartLevel start;

  /// Noms des notes sur les touches blanches du clavier.
  final bool keyLabels;
  final DailyGoal goal;

  /// Retour haptique juste / faux.
  final bool haptics;
  final ThemeMode theme;

  /// Interroger GitHub au lancement : une nouvelle version est-elle sortie ?
  final bool updateCheck;

  Settings copyWith({
    bool? onboarded,
    NoteNaming? naming,
    StartLevel? start,
    bool? keyLabels,
    DailyGoal? goal,
    bool? haptics,
    ThemeMode? theme,
    bool? updateCheck,
  }) => Settings(
    onboarded: onboarded ?? this.onboarded,
    naming: naming ?? this.naming,
    start: start ?? this.start,
    keyLabels: keyLabels ?? this.keyLabels,
    goal: goal ?? this.goal,
    haptics: haptics ?? this.haptics,
    theme: theme ?? this.theme,
    updateCheck: updateCheck ?? this.updateCheck,
  );
}

/// Lecture et écriture des réglages. Une valeur absente ou inconnue (réglage
/// retiré d'une version à l'autre) donne la valeur par défaut.
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _onboarded = 'onboarded';
  static const _naming = 'naming';
  static const _start = 'start';
  static const _keyLabels = 'keyLabels';
  static const _goal = 'goal';
  static const _haptics = 'haptics';
  static const _theme = 'theme';
  static const _updateCheck = 'updateCheck';

  Settings load() {
    const defaults = Settings();
    T? named<T extends Enum>(List<T> values, String key) =>
        values.asNameMap()[_prefs.getString(key)];
    return Settings(
      onboarded: _prefs.getBool(_onboarded) ?? defaults.onboarded,
      naming: named(NoteNaming.values, _naming) ?? defaults.naming,
      start: named(StartLevel.values, _start) ?? defaults.start,
      keyLabels: _prefs.getBool(_keyLabels) ?? defaults.keyLabels,
      goal: named(DailyGoal.values, _goal) ?? defaults.goal,
      haptics: _prefs.getBool(_haptics) ?? defaults.haptics,
      theme: named(ThemeMode.values, _theme) ?? defaults.theme,
      updateCheck: _prefs.getBool(_updateCheck) ?? defaults.updateCheck,
    );
  }

  Future<void> save(Settings settings) => Future.wait([
    _prefs.setBool(_onboarded, settings.onboarded),
    _prefs.setString(_naming, settings.naming.name),
    _prefs.setString(_start, settings.start.name),
    _prefs.setBool(_keyLabels, settings.keyLabels),
    _prefs.setString(_goal, settings.goal.name),
    _prefs.setBool(_haptics, settings.haptics),
    _prefs.setString(_theme, settings.theme.name),
    _prefs.setBool(_updateCheck, settings.updateCheck),
  ]);
}

/// Réglages, lus au démarrage (voir main.dart).
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  () => throw UnimplementedError('settingsProvider : à surcharger'),
);

class SettingsNotifier extends Notifier<Settings> {
  SettingsNotifier(this._store, this._initial);

  final SettingsStore _store;
  final Settings _initial;

  @override
  Settings build() => _initial;

  /// Change les réglages tout de suite, puis les écrit.
  Future<void> update(Settings Function(Settings settings) change) {
    state = change(state);
    return _store.save(state);
  }
}
