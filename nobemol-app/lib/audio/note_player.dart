import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:nobemol/audio/piano.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/settings/settings.dart';

/// Joue une note. Remplaçable en test.
abstract interface class NotePlayer {
  /// Charge le son, une fois : la première note part alors sans attente.
  Future<void> load();

  Future<void> play(int midi);

  Future<void> dispose();
}

/// Le piano enregistré (`piano.dart`), joué par SoLoud.
///
/// Les 30 notes sont chargées en mémoire une fois pour toutes. Chaque [play]
/// lance une voix neuve : rien à préparer, aucun lecteur réutilisé, donc
/// pas de note perdue ni jouée deux fois, quel que soit le rythme des
/// réponses. Une nouvelle note éteint la précédente en [_release].
///
/// SoLoud ne demande pas le focus audio : la musique de l'élève continue.
class PianoNotePlayer implements NotePlayer {
  PianoNotePlayer();

  static const _release = Duration(milliseconds: 80);

  final _soloud = SoLoud.instance;
  Future<Map<int, AudioSource>>? _sources;
  SoundHandle? _sounding;

  @override
  Future<void> load() => _loaded();

  Future<Map<int, AudioSource>> _loaded() async {
    final pending = _sources ??= _load();
    try {
      return await pending;
    } catch (_) {
      // Pas de sortie audio, par exemple : on réessaiera à la note suivante.
      if (identical(_sources, pending)) _sources = null;
      rethrow;
    }
  }

  Future<Map<int, AudioSource>> _load() async {
    if (!_soloud.isInitialized) await _soloud.init();
    final sources = await Future.wait([
      for (final sample in pianoSamples) _soloud.loadAsset(pianoAsset(sample)),
    ]);
    return {for (final (i, sample) in pianoSamples.indexed) sample: sources[i]};
  }

  @override
  Future<void> play(int midi) async {
    final sources = await _loaded();
    final (:sample, :speed) = pianoSample(midi);

    if (_sounding case final previous?) {
      _soloud
        ..fadeVolume(previous, 0, _release)
        ..scheduleStop(previous, _release);
    }
    // En pause le temps de régler la hauteur : pas un instant de faux.
    final handle = _soloud.play(sources[sample]!, paused: true);
    _soloud
      ..setRelativePlaySpeed(handle, speed)
      ..setPause(handle, false);
    _sounding = handle;
  }

  @override
  Future<void> dispose() async {
    if (_soloud.isInitialized) await _soloud.deinitAsync();
  }
}

final notePlayerProvider = Provider<NotePlayer>((ref) {
  final player = PianoNotePlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Le son des questions, côté écran. Une note à lire seulement : une durée
/// ou un signe n'a pas de hauteur. Rien si le son est coupé.
extension NoteSound on WidgetRef {
  /// À l'ouverture d'un exercice : le piano est prêt avant la première
  /// réponse.
  void loadNotes() => _sound((player) => player.load());

  /// À la correction, juste ou faux : la note juste.
  void playNote(Question question) {
    if (question is! NoteQuestion) return;
    _sound((player) => player.play(midiOfQuestion(question)));
  }

  /// Sans attendre, et sans jamais faire échouer l'exercice : un son raté
  /// ne se voit pas.
  void _sound(Future<void> Function(NotePlayer player) action) {
    if (!read(settingsProvider).sound) return;
    unawaited(
      Future.sync(() => action(read(notePlayerProvider))).catchError((_) {}),
    );
  }
}
