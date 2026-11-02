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
    this.placement,
    this.keyLabels = true,
    this.goal = DailyGoal.five,
    this.haptics = true,
    this.sound = true,
    this.theme = ThemeMode.system,
    this.updateCheck = true,
    this.tapLatency,
  });

  /// Le démarrage (bienvenue, point de départ, objectif) est passé.
  final bool onboarded;
  final NoteNaming naming;
  final StartLevel start;

  /// Compétences réussies au test de positionnement. Elles remplacent le
  /// point de départ choisi à la main. `null` tant que le test n'est pas
  /// passé, et dès qu'un point de départ est choisi.
  final Set<String>? placement;

  /// Compétences acquises au départ : celles du test, sinon celles du
  /// point de départ.
  Set<String> get acquired => placement ?? start.acquired;

  /// Noms des notes sur les touches blanches du clavier.
  final bool keyLabels;
  final DailyGoal goal;

  /// Retour haptique juste / faux.
  final bool haptics;

  /// La note juste jouée à la correction.
  final bool sound;
  final ThemeMode theme;

  /// Interroger GitHub au lancement : une nouvelle version est-elle sortie ?
  final bool updateCheck;

  /// Calage du rythme tapé, en millisecondes : le retard mesuré entre un
  /// clic et la touche qui l'accompagne. `null` tant qu'il n'est pas fait.
  /// Propre au téléphone : il ne part pas dans la sauvegarde.
  final int? tapLatency;

  Settings copyWith({
    bool? onboarded,
    NoteNaming? naming,
    StartLevel? start,
    Set<String>? Function()? placement,
    bool? keyLabels,
    DailyGoal? goal,
    bool? haptics,
    bool? sound,
    ThemeMode? theme,
    bool? updateCheck,
    int? tapLatency,
  }) => Settings(
    onboarded: onboarded ?? this.onboarded,
    naming: naming ?? this.naming,
    start: start ?? this.start,
    placement: placement == null ? this.placement : placement(),
    keyLabels: keyLabels ?? this.keyLabels,
    goal: goal ?? this.goal,
    haptics: haptics ?? this.haptics,
    sound: sound ?? this.sound,
    theme: theme ?? this.theme,
    updateCheck: updateCheck ?? this.updateCheck,
    tapLatency: tapLatency ?? this.tapLatency,
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
  static const _placement = 'placement';
  static const _keyLabels = 'keyLabels';
  static const _goal = 'goal';
  static const _haptics = 'haptics';
  static const _sound = 'sound';
  static const _theme = 'theme';
  static const _updateCheck = 'updateCheck';
  static const _tapLatency = 'tapLatency';

  Settings load() {
    const defaults = Settings();
    T? named<T extends Enum>(List<T> values, String key) =>
        values.asNameMap()[_prefs.getString(key)];
    return Settings(
      onboarded: _prefs.getBool(_onboarded) ?? defaults.onboarded,
      naming: named(NoteNaming.values, _naming) ?? defaults.naming,
      start: named(StartLevel.values, _start) ?? defaults.start,
      placement: _prefs.getStringList(_placement)?.toSet(),
      keyLabels: _prefs.getBool(_keyLabels) ?? defaults.keyLabels,
      goal: named(DailyGoal.values, _goal) ?? defaults.goal,
      haptics: _prefs.getBool(_haptics) ?? defaults.haptics,
      sound: _prefs.getBool(_sound) ?? defaults.sound,
      theme: named(ThemeMode.values, _theme) ?? defaults.theme,
      updateCheck: _prefs.getBool(_updateCheck) ?? defaults.updateCheck,
      tapLatency: _prefs.getInt(_tapLatency),
    );
  }

  Future<void> save(Settings settings) => Future.wait([
    _prefs.setBool(_onboarded, settings.onboarded),
    _prefs.setString(_naming, settings.naming.name),
    _prefs.setString(_start, settings.start.name),
    switch (settings.placement) {
      final placement? => _prefs.setStringList(_placement, placement.toList()),
      null => _prefs.remove(_placement),
    },
    _prefs.setBool(_keyLabels, settings.keyLabels),
    _prefs.setString(_goal, settings.goal.name),
    _prefs.setBool(_haptics, settings.haptics),
    _prefs.setBool(_sound, settings.sound),
    _prefs.setString(_theme, settings.theme.name),
    _prefs.setBool(_updateCheck, settings.updateCheck),
    if (settings.tapLatency case final latency?)
      _prefs.setInt(_tapLatency, latency),
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
