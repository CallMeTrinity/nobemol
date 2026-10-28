import 'package:notation/core.dart';

/// Durée en temps, la noire valant un temps : les réponses des exercices de
/// rythme, du plus court au plus long.
enum Beats {
  quarter(Fraction(1, 4)),
  half(Fraction(1, 2)),
  threeQuarters(Fraction(3, 4)),
  one(Fraction(1)),
  oneAndHalf(Fraction(3, 2)),
  two(Fraction(2)),
  three(Fraction(3)),
  four(Fraction(4));

  const Beats(this.value);

  final Fraction value;

  /// Réponse qui vaut [value] temps, `null` s'il n'y en a pas.
  static Beats? of(Fraction value) =>
      Beats.values.where((beats) => beats.value == value).firstOrNull;
}

/// Durée en temps (noire = 1) des événements [refs] de [system], additionnés :
/// une note et celles qui lui sont liées.
Fraction beatsOf(System system, List<EventRef> refs) => refs
    .map((ref) => system.event(ref)!.duration * const Fraction(4))
    .fold(Fraction.zero, (total, beats) => total + beats);
