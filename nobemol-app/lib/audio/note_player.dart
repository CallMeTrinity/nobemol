import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/audio/synth.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/settings/settings.dart';

/// Joue une note. Remplaçable en test.
abstract interface class NotePlayer {
  /// Prépare le son de [midi] : il part sans attente au [play] suivant.
  Future<void> prepare(int midi);

  Future<void> play(int midi);

  Future<void> dispose();
}

/// Notes synthétisées (`synth.dart`), jouées par le lecteur du système.
///
/// Sur Android, un son en mémoire passe par MediaPlayer, qui demande un
/// temps de préparation (le mode faible latence n'accepte que des
/// fichiers). D'où [prepare] : l'écran prépare la note juste dès que la
/// question s'affiche, et la correction la lance aussitôt. Deux lecteurs
/// en alternance : préparer la note suivante ne coupe pas celle qui sonne.
class SynthNotePlayer implements NotePlayer {
  SynthNotePlayer();

  final _players = [AudioPlayer(), AudioPlayer()];
  final _sounds = <int, Uint8List>{};
  var _next = 0;
  (int, AudioPlayer)? _prepared;
  Future<void>? _setup;

  /// Joue par-dessus la musique de l'élève, sans la couper.
  Future<void> _context() => _setup ??= Future.wait([
    for (final player in _players)
      player.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      ),
  ]);

  @override
  Future<void> prepare(int midi) async {
    await _context();
    final player = _players[_next];
    _next = 1 - _next;
    await player.setSource(
      BytesSource(
        _sounds.putIfAbsent(midi, () => pianoWav(midi)),
        mimeType: 'audio/wav',
      ),
    );
    _prepared = (midi, player);
  }

  @override
  Future<void> play(int midi) async {
    if (_prepared?.$1 != midi) await prepare(midi);
    final (_, player) = _prepared!;
    _prepared = null;
    await player.resume();
  }

  @override
  Future<void> dispose() async {
    for (final player in _players) {
      await player.dispose();
    }
  }
}

final notePlayerProvider = Provider<NotePlayer>((ref) {
  final player = SynthNotePlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Le son d'une question, côté écran. Une note à lire seulement : une
/// durée ou un signe n'a pas de hauteur. Rien si le son est coupé.
extension NoteSound on WidgetRef {
  /// Dès que la question s'affiche.
  void prepareNote(Question question) =>
      _note(question, (player, midi) => player.prepare(midi));

  /// À la correction, juste ou faux : la note juste.
  void playNote(Question question) =>
      _note(question, (player, midi) => player.play(midi));

  /// Sans attendre, et sans jamais faire échouer l'exercice : un son raté
  /// ne se voit pas.
  void _note(
    Question question,
    Future<void> Function(NotePlayer player, int midi) action,
  ) {
    if (question is! NoteQuestion || !read(settingsProvider).sound) return;
    unawaited(
      Future.sync(
        () => action(read(notePlayerProvider), midiOfQuestion(question)),
      ).catchError((Object _) {}),
    );
  }
}
