import 'package:meta/meta.dart';
import 'package:notation/src/model/fraction.dart';

/// Chiffrage : [beats] temps de [beatUnit] (3/4 : trois noires).
@immutable
class TimeSignature {
  /// Crée un chiffrage.
  const new(this.beats, this.beatUnit);

  /// Chiffre du haut.
  final int beats;

  /// Chiffre du bas : 4 pour la noire, 2 pour la blanche...
  final int beatUnit;

  /// Durée d'une mesure complète, en rondes.
  Fraction get measureDuration => Fraction(beats, beatUnit);

  @override
  bool operator ==(Object other) =>
      other is TimeSignature &&
      other.beats == beats &&
      other.beatUnit == beatUnit;

  @override
  int get hashCode => Object.hash(beats, beatUnit);

  @override
  String toString() => '$beats/$beatUnit';
}
