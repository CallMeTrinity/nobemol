import 'package:meta/meta.dart';

/// Nombre rationnel exact, pour le temps musical (fraction de ronde).
///
/// Pas de `double` : `1/3 + 1/3 + 1/3` doit valoir exactement 1 pour que les
/// événements de deux portées tombent dans la même colonne.
@immutable
class Fraction implements Comparable<Fraction> {
  /// Crée [numerator]/[denominator]. La fraction n'a pas besoin d'être
  /// réduite : l'égalité compare les valeurs.
  const new(this.numerator, [this.denominator = 1])
    : assert(denominator > 0, 'dénominateur strictement positif');

  /// Zéro.
  static const zero = Fraction(0);

  /// Numérateur.
  final int numerator;

  /// Dénominateur, strictement positif.
  final int denominator;

  /// Fraction réduite.
  Fraction get reduced {
    final divisor = numerator.gcd(denominator);
    return divisor <= 1
        ? this
        : Fraction(numerator ~/ divisor, denominator ~/ divisor);
  }

  /// Vrai si la fraction est un entier.
  bool get isInteger => numerator % denominator == 0;

  /// Somme.
  Fraction operator +(Fraction other) => Fraction(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  ).reduced;

  /// Différence.
  Fraction operator -(Fraction other) =>
      this + Fraction(-other.numerator, other.denominator);

  /// Produit.
  Fraction operator *(Fraction other) => Fraction(
    numerator * other.numerator,
    denominator * other.denominator,
  ).reduced;

  /// Strictement inférieur.
  bool operator <(Fraction other) => compareTo(other) < 0;

  /// Strictement supérieur.
  bool operator >(Fraction other) => compareTo(other) > 0;

  /// Valeur approchée.
  double toDouble() => numerator / denominator;

  @override
  int compareTo(Fraction other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Fraction &&
      numerator * other.denominator == other.numerator * denominator;

  @override
  int get hashCode {
    final value = reduced;
    return Object.hash(value.numerator, value.denominator);
  }

  @override
  String toString() {
    final value = reduced;
    return value.denominator == 1
        ? '${value.numerator}'
        : '${value.numerator}/${value.denominator}';
  }
}
