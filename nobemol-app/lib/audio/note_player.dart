import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:nobemol/audio/piano.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/settings/settings.dart';

/// Joue des notes. Remplaçable en test.
abstract interface class NotePlayer {
  /// Charge le son, une fois : la première note part alors sans attente.
  Future<void> load();

  /// Joue [midis] ensemble : une note, ou un accord.
  Future<void> play(List<int> midis);

  Future<void> dispose();
}

/// Le piano enregistré (`piano.dart`), joué par SoLoud.
///
/// Les 30 notes sont chargées en mémoire une fois pour toutes. Chaque [play]
/// lance une voix neuve : rien à préparer, aucun lecteur réutilisé, donc
/// pas de note perdue ni jouée deux fois, quel que soit le rythme des
/// réponses. De nouvelles notes éteignent les précédentes en [_release].
///
/// SoLoud ne demande pas le focus audio : la musique de l'élève continue.
class PianoNotePlayer implements NotePlayer {
  PianoNotePlayer();

  static const _release = Duration(milliseconds: 80);

  final _soloud = SoLoud.instance;
  Future<Map<int, AudioSource>>? _sources;
  var _sounding = <SoundHandle>[];

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
  Future<void> play(List<int> midis) async {
    final sources = await _loaded();

    for (final previous in _sounding) {
      _soloud
        ..fadeVolume(previous, 0, _release)
        ..scheduleStop(previous, _release);
    }
    // En pause le temps de régler la hauteur : pas un instant de faux. Les
    // notes d'un accord partent ensemble.
    final handles = [
      for (final midi in midis)
        _soloud.play(sources[pianoSample(midi).sample]!, paused: true),
    ];
    for (final (index, handle) in handles.indexed) {
      _soloud.setRelativePlaySpeed(handle, pianoSample(midis[index]).speed);
    }
    for (final handle in handles) {
      _soloud.setPause(handle, false);
    }
    _sounding = handles;
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

/// Écart entre deux notes jouées l'une après l'autre : un intervalle
/// mélodique, le do de référence et la note.
const soundGap = Duration(milliseconds: 800);

/// Notes jouées l'une après l'autre, une seule suite à la fois : une
/// nouvelle suite arrête celle qui n'est pas finie.
class SoundSequence {
  final _timers = <Timer>[];

  /// Joue [steps] (chacun : des notes ensemble) espacés de [soundGap].
  void start(NotePlayer player, List<List<int>> steps) {
    cancel();
    for (final (index, midis) in steps.indexed) {
      void play() =>
          unawaited(Future.sync(() => player.play(midis)).catchError((_) {}));
      if (index == 0) {
        play();
      } else {
        _timers.add(Timer(soundGap * index, play));
      }
    }
  }

  /// Arrête les notes pas encore jouées.
  void cancel() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}

final soundSequenceProvider = Provider<SoundSequence>((ref) {
  final sequence = SoundSequence();
  ref.onDispose(sequence.cancel);
  return sequence;
});

/// Le son des questions, côté écran. Ce qui a une hauteur seulement : une
/// durée ou un signe n'en a pas.
extension NoteSound on WidgetRef {
  /// À l'ouverture d'un exercice : le piano est prêt avant la première
  /// réponse. Toujours pour un exercice d'oreille ([always]).
  void loadNotes({bool always = false}) {
    if (!always && !read(settingsProvider).sound) return;
    unawaited(
      Future.sync(() => read(notePlayerProvider).load()).catchError((_) {}),
    );
  }

  /// À la correction, juste ou faux : la note juste, l'intervalle, ou le do
  /// et la note entendue. Rien si le son est coupé.
  void playNote(Question question) {
    if (!read(settingsProvider).sound) return;
    _play(question);
  }

  /// La question d'un exercice d'oreille, même si le son des notes est
  /// coupé : c'est elle qu'il faut nommer.
  void playHeard(Question question) => _play(question);

  /// Sans attendre, et sans jamais faire échouer l'exercice : un son raté
  /// ne se voit pas.
  void _play(Question question) {
    final steps = soundOf(question);
    if (steps.isEmpty) return;
    read(soundSequenceProvider).start(read(notePlayerProvider), steps);
  }
}
