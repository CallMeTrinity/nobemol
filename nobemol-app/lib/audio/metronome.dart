import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:nobemol/audio/note_player.dart';
import 'package:nobemol/reading/tapping.dart';

/// Joue les clics d'un métronome. Remplaçable en test.
abstract interface class Metronome {
  /// Prépare [track] : il partira sans attente.
  Future<void> prepare(ClickTrack track);

  /// Joue [track] depuis le début, et rend la main quand il part. Arrête
  /// celui qui joue encore. Rend la position du son à cet instant : le
  /// premier clic a sonné (à la latence de sortie près) d'autant plus tôt.
  /// Zéro si elle n'est pas connue.
  Future<Duration> play(ClickTrack track);

  Future<void> stop();
}

/// Le métronome par SoLoud : chaque [ClickTrack] devient **un seul son**,
/// fabriqué ici. Les clics sont à l'échantillon près les uns des autres :
/// seul le départ peut varier, et le calage du rythme tapé l'absorbe.
/// Des clics lancés un par un, au minuteur, flotteraient de quelques
/// millisecondes à chaque temps.
class SoloudMetronome implements Metronome {
  /// Pistes gardées en mémoire : la phrase en cours, la suivante, le
  /// calage. Les plus anciennes sont libérées.
  static const _kept = 4;

  final _soloud = SoLoud.instance;
  final _sources = <ClickTrack, Future<AudioSource>>{};
  SoundHandle? _playing;
  ClickTrack? _playingTrack;

  @override
  Future<void> prepare(ClickTrack track) => _source(track);

  Future<AudioSource> _source(ClickTrack track) {
    // La plus récente en dernier.
    final cached = _sources.remove(track);
    final pending = _sources[track] =
        cached ??
        () async {
          await initSoloud();
          return _soloud.loadMem(
            'clicks-${track.hashCode}.wav',
            clickWav(track),
          );
        }();
    _forgetOld();
    // Pas de sortie audio, par exemple : on réessaiera au prochain départ.
    unawaited(
      pending.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_sources[track], pending)) _sources.remove(track);
        },
      ),
    );
    return pending;
  }

  /// Libère les pistes au-delà de [_kept], sauf celle qui joue.
  void _forgetOld() {
    if (_sources.length <= _kept) return;
    final old = _sources.keys
        .where((track) => track != _playingTrack)
        .take(_sources.length - _kept)
        .toList();
    for (final track in old) {
      final source = _sources.remove(track)!;
      unawaited(
        source
            .then((source) => _soloud.disposeSource(source))
            .catchError((Object _) {}),
      );
    }
  }

  /// Le son part au prochain bloc de mixage : un délai qui varie à chaque
  /// départ, jusqu'à la taille d'un bloc (46 ms par défaut). On attend que
  /// sa position avance : à ce moment, le départ est connu à une ou deux
  /// millisecondes près, à un décalage constant près que le calage
  /// absorbe.
  @override
  Future<Duration> play(ClickTrack track) async {
    final source = await _source(track);
    await stop();
    final handle = _soloud.play(source);
    _playing = handle;
    _playingTrack = track;
    final waiting = Stopwatch()..start();
    while (waiting.elapsed < const Duration(milliseconds: 300)) {
      final position = _soloud.getPosition(handle);
      if (position > Duration.zero) return position;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    return Duration.zero;
  }

  @override
  Future<void> stop() async {
    final playing = _playing;
    _playing = null;
    _playingTrack = null;
    if (playing != null && _soloud.isInitialized) await _soloud.stop(playing);
  }
}

final metronomeProvider = Provider<Metronome>((ref) => SoloudMetronome());

/// Fréquence d'échantillonnage du métronome.
const clickSampleRate = 22050;

/// [track] en fichier WAV : mono, 16 bits. Un clic bref par temps, plus
/// aigu au premier temps de la mesure.
Uint8List clickWav(ClickTrack track) {
  final frames =
      (track.length + const Duration(milliseconds: 200)).inMicroseconds *
      clickSampleRate ~/
      Duration.microsecondsPerSecond;
  final samples = Int16List(frames);
  const clickLength = clickSampleRate * 30 ~/ 1000;
  for (var i = 0; i < track.beats; i++) {
    final start =
        track.click(i).inMicroseconds *
        clickSampleRate ~/
        Duration.microsecondsPerSecond;
    final frequency = track.accented(i) ? 1760.0 : 1320.0;
    final volume = track.accented(i) ? 0.7 : 0.5;
    for (var n = 0; n < clickLength && start + n < frames; n++) {
      final t = n / clickSampleRate;
      // Une sinusoïde qui s'éteint vite : un « toc » net, sans souffle.
      final value = volume * exp(-t * 180) * sin(2 * pi * frequency * t);
      samples[start + n] = (value * 32767).round();
    }
  }
  return _wav(samples, clickSampleRate);
}

Uint8List _wav(Int16List samples, int sampleRate) {
  final data = samples.lengthInBytes;
  final header = ByteData(44)
    ..setUint32(0, 0x52494646) // RIFF
    ..setUint32(4, 36 + data, Endian.little)
    ..setUint32(8, 0x57415645) // WAVE
    ..setUint32(12, 0x666d7420) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461) // data
    ..setUint32(40, data, Endian.little);
  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(samples.buffer.asUint8List(0, data)))
      .toBytes();
}
