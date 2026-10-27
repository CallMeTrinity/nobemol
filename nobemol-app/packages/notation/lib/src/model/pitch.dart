import 'package:meta/meta.dart';

/// Degré diatonique, en lettres comme l'ABC.
enum DiatonicStep {
  /// Do.
  c,

  /// Ré.
  d,

  /// Mi.
  e,

  /// Fa.
  f,

  /// Sol.
  g,

  /// La.
  a,

  /// Si.
  b,
}

/// Altération écrite devant une note.
enum Accidental {
  /// Double bémol.
  doubleFlat(-2),

  /// Bémol.
  flat(-1),

  /// Bécarre.
  natural(0),

  /// Dièse.
  sharp(1),

  /// Double dièse.
  doubleSharp(2);

  new(this.alteration);

  /// Décalage en demi-tons.
  final int alteration;
}

/// Hauteur écrite : degré diatonique + octave + altération.
///
/// Pas de numéro MIDI : pour la lecture, un fa# n'est pas un solb.
@immutable
class Pitch {
  /// Crée une hauteur. L'octave suit la notation scientifique (do4 = do
  /// central).
  const new(this.step, this.octave, {this.accidental});

  /// Crée une hauteur à partir de son [diatonic] (voir [Pitch.diatonic]).
  factory fromDiatonic(int diatonic, {Accidental? accidental}) {
    final degree = diatonic % 7;
    return Pitch(
      DiatonicStep.values[degree],
      (diatonic - degree) ~/ 7,
      accidental: accidental,
    );
  }

  /// Degré.
  final DiatonicStep step;

  /// Octave, do4 = do central.
  final int octave;

  /// Altération écrite, `null` si aucune.
  final Accidental? accidental;

  /// Index diatonique absolu : do0 vaut 0, chaque octave compte 7 degrés.
  int get diatonic => octave * 7 + step.index;

  @override
  bool operator ==(Object other) =>
      other is Pitch &&
      other.step == step &&
      other.octave == octave &&
      other.accidental == accidental;

  @override
  int get hashCode => Object.hash(step, octave, accidental);

  @override
  String toString() {
    final sign = switch (accidental) {
      null => '',
      Accidental.doubleFlat => 'bb',
      Accidental.flat => 'b',
      Accidental.natural => 'n',
      Accidental.sharp => '#',
      Accidental.doubleSharp => 'x',
    };
    return '${step.name.toUpperCase()}$sign$octave';
  }
}
