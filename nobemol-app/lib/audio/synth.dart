import 'dart:math';
import 'dart:typed_data';

import 'package:notation/core.dart';

import 'package:nobemol/reading/note_reading.dart';

/// Fréquence d'échantillonnage : les harmoniques utiles d'une note de
/// piano tiennent sous 11 kHz, la moitié.
const sampleRate = 22050;

/// Durée d'une note jouée, extinction comprise.
const noteLength = Duration(milliseconds: 1500);

/// Numéro MIDI d'une hauteur : do4 (do du milieu) = 60, la4 = 69.
int midiOf(DiatonicStep step, int octave, Accidental? accidental) {
  const semitones = {
    DiatonicStep.c: 0,
    DiatonicStep.d: 2,
    DiatonicStep.e: 4,
    DiatonicStep.f: 5,
    DiatonicStep.g: 7,
    DiatonicStep.a: 9,
    DiatonicStep.b: 11,
  };
  return 12 * (octave + 1) + semitones[step]! + (accidental?.alteration ?? 0);
}

/// Ce qu'on entend pour [question] : la note lue, armure et altérations de
/// la mesure comprises (la réponse), à l'octave écrite.
int midiOfQuestion(NoteQuestion question) => midiOf(
  question.answer.step,
  question.pitch.octave,
  question.answer.accidental,
);

/// Fréquence en Hz, tempérament égal, la4 = 440 Hz.
double frequencyOf(int midi) => 440 * pow(2, (midi - 69) / 12).toDouble();

/// Son de piano simplifié, synthétisé : pas de fichier embarqué, toutes les
/// hauteurs. Fichier WAV (PCM 16 bits, mono) prêt à jouer.
///
/// Une corde frappée : des harmoniques un peu plus aiguës que les multiples
/// exacts (inharmonicité), d'autant plus faibles et plus brèves qu'elles
/// sont hautes. Attaque de 5 ms, puis tout s'éteint ; fondu sur les 60
/// dernières ms pour ne pas finir sur un clic.
Uint8List pianoWav(int midi) {
  final frequency = frequencyOf(midi);
  final count = sampleRate * noteLength.inMilliseconds ~/ 1000;
  final attack = sampleRate * 5 ~/ 1000;
  final fade = sampleRate * 60 ~/ 1000;
  // Les notes graves durent plus longtemps.
  final decay = 1.2 + frequency / 400;

  final partials = [
    for (var n = 1; n <= 10; n++)
      if (n * frequency < sampleRate / 2)
        (
          frequency: n * frequency * sqrt(1 + 0.0004 * n * n),
          amplitude: 1 / pow(n, 1.6),
          decay: decay * (1 + 0.6 * (n - 1)),
        ),
  ];

  final samples = Float64List(count);
  var peak = 0.0;
  for (var i = 0; i < count; i++) {
    final t = i / sampleRate;
    var value = 0.0;
    for (final partial in partials) {
      value +=
          partial.amplitude *
          exp(-partial.decay * t) *
          sin(2 * pi * partial.frequency * t);
    }
    if (i < attack) value *= i / attack;
    if (i > count - fade) value *= (count - i) / fade;
    samples[i] = value;
    peak = max(peak, value.abs());
  }

  final gain = peak == 0 ? 0 : 0.8 / peak;
  final pcm = Int16List(count);
  for (var i = 0; i < count; i++) {
    pcm[i] = (samples[i] * gain * 32767).round().clamp(-32768, 32767);
  }
  return _wav(pcm);
}

/// En-tête RIFF de 44 octets, puis les échantillons (petit-boutiste).
Uint8List _wav(Int16List pcm) {
  final dataBytes = pcm.length * 2;
  final bytes = ByteData(44 + dataBytes);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little) // taille du bloc fmt
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little) // octets par seconde
    ..setUint16(32, 2, Endian.little) // octets par échantillon
    ..setUint16(34, 16, Endian.little); // bits
  ascii(36, 'data');
  bytes.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < pcm.length; i++) {
    bytes.setInt16(44 + i * 2, pcm[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}
