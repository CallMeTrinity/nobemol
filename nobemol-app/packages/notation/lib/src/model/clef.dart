import 'package:meta/meta.dart';
import 'package:notation/src/model/pitch.dart';

/// Signe de clé, avec la hauteur qu'il désigne.
enum ClefSign {
  /// Clé de sol : sol4.
  g(Pitch(DiatonicStep.g, 4)),

  /// Clé de fa : fa3.
  f(Pitch(DiatonicStep.f, 3)),

  /// Clé d'ut : do4.
  c(Pitch(DiatonicStep.c, 4));

  new(this.pitch);

  /// Hauteur désignée par le signe, sur la ligne où il est posé.
  final Pitch pitch;
}

/// Clé : un signe posé sur une ligne de la portée.
///
/// Les clés d'ut ne demandent aucun cas particulier : seule la ligne change.
@immutable
class Clef {
  /// Crée une clé. [line] va de 1 (ligne du bas) à 5 (ligne du haut).
  const new(this.sign, this.line);

  /// Clé de sol 2e ligne.
  static const treble = Clef(ClefSign.g, 2);

  /// Clé de fa 4e ligne.
  static const bass = Clef(ClefSign.f, 4);

  /// Clé d'ut 3e ligne.
  static const alto = Clef(ClefSign.c, 3);

  /// Clé d'ut 4e ligne.
  static const tenor = Clef(ClefSign.c, 4);

  /// Signe.
  final ClefSign sign;

  /// Ligne de référence, de 1 (bas) à 5 (haut).
  final int line;

  /// Hauteur de référence, posée sur [line].
  Pitch get reference => sign.pitch;

  /// Position de [pitch] sur la portée, en demi-interlignes au-dessus de la
  /// ligne du bas : 0 pour la ligne du bas, 1 pour le premier interligne,
  /// 8 pour la ligne du haut. Négative sous la portée.
  int staffPosition(Pitch pitch) =>
      (line - 1) * 2 + pitch.diatonic - reference.diatonic;

  /// Hauteur (sans altération) à la [position] donnée sur la portée.
  Pitch pitchAt(int position) =>
      Pitch.fromDiatonic(reference.diatonic + position - (line - 1) * 2);

  @override
  bool operator ==(Object other) =>
      other is Clef && other.sign == sign && other.line == line;

  @override
  int get hashCode => Object.hash(sign, line);
}
