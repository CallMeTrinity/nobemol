import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:nobemol/audio/metronome.dart';
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
    await initSoloud();
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

Future<void>? _initializing;

/// Démarre SoLoud, une fois pour le piano et le métronome.
Future<void> initSoloud() {
  final soloud = SoLoud.instance;
  if (soloud.isInitialized) return Future.value();
  return _initializing ??= soloud.init().whenComplete(
    () => _initializing = null,
  );
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

  /// Change à chaque arrêt : une suite qui attendait son départ (le
  /// métronome) sait qu'elle a été arrêtée entre-temps.
  int get generation => _generation;
  var _generation = 0;

  /// Joue [steps] (chacun : des notes ensemble) espacés de [soundGap].
  void start(NotePlayer player, List<List<int>> steps) => startTimed(player, [
    for (final (index, midis) in steps.indexed) (soundGap * index, midis),
  ]);

  /// Joue chaque étape de [steps] à son instant. Une étape sans note éteint
  /// la précédente : un silence.
  void startTimed(NotePlayer player, List<(Duration, List<int>)> steps) {
    cancel();
    for (final (at, midis) in steps) {
      void play() =>
          unawaited(Future.sync(() => player.play(midis)).catchError((_) {}));
      if (at == Duration.zero) {
        play();
      } else {
        _timers.add(Timer(at, play));
      }
    }
  }

  /// Arrête les notes pas encore jouées.
  void cancel() {
    _generation++;
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
    if (question is TapQuestion) {
      unawaited(_playRhythm(question));
      return;
    }
    final steps = soundOf(question);
    if (steps.isEmpty) return;
    read(soundSequenceProvider).start(read(notePlayerProvider), steps);
  }

  /// Rejoue la phrase d'un rythme tapé, même son des notes coupé : le
  /// décompte, puis ses notes sur le métronome.
  void playRhythm(TapQuestion question) => unawaited(_playRhythm(question));

  Future<void> _playRhythm(TapQuestion question) async {
    final sequence = read(soundSequenceProvider);
    final player = read(notePlayerProvider);
    final metronome = read(metronomeProvider);
    sequence.cancel();
    final generation = sequence.generation;
    // Le métronome a déjà joué ce temps-là : les notes le rattrapent.
    var started = Duration.zero;
    try {
      started = await metronome.play(question.track);
    } catch (_) {
      // Sans clics, les notes restent.
    }
    // Arrêtée pendant que le métronome partait.
    if (sequence.generation != generation) return;
    sequence.startTimed(player, [
      for (final (at, midis) in rhythmSound(question))
        (at > started ? at - started : Duration.zero, midis),
    ]);
  }

  /// Arrête le son en cours : notes à venir et métronome.
  void stopSounds() {
    read(soundSequenceProvider).cancel();
    unawaited(
      Future.sync(() => read(metronomeProvider).stop()).catchError((_) {}),
    );
  }
}
