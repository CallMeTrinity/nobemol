import 'package:notation/core.dart';

/// Intervalle par son numéro, de l'unisson à l'octave : les réponses des
/// exercices d'intervalles. La qualité (majeure, mineure, juste) viendra
/// plus tard.
enum IntervalNumber {
  unison(1),
  second(2),
  third(3),
  fourth(4),
  fifth(5),
  sixth(6),
  seventh(7),
  octave(8);

  const IntervalNumber(this.size);

  /// Nombre de notes de la gamme comptées d'un bout à l'autre, les deux
  /// bouts compris : 3 pour une tierce.
  final int size;

  /// Intervalle de [size] notes, `null` au-delà de l'octave.
  static IntervalNumber? of(int size) =>
      values.where((number) => number.size == size).firstOrNull;
}

/// Intervalle entre [a] et [b], dans un sens ou dans l'autre. Les
/// altérations ne changent pas le numéro. `null` au-delà de l'octave.
IntervalNumber? intervalBetween(Pitch a, Pitch b) =>
    IntervalNumber.of((a.diatonic - b.diatonic).abs() + 1);

/// Écart en demi-tons de [a] à [b], en valeur absolue.
int semitonesBetween(Pitch a, Pitch b) => (_semitone(a) - _semitone(b)).abs();

int _semitone(Pitch pitch) =>
    12 * pitch.octave +
    const [0, 2, 4, 5, 7, 9, 11][pitch.step.index] +
    (pitch.accidental?.alteration ?? 0);
