import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

void main() {
  test('égalité par valeur, fraction non réduite comprise', () {
    expect(const Fraction(2, 4), const Fraction(1, 2));
    expect(const Fraction(2, 4).hashCode, const Fraction(1, 2).hashCode);
    expect(const Fraction(1, 2), isNot(const Fraction(1, 3)));
  });

  test('calcul exact', () {
    const third = Fraction(1, 3);
    expect(third + third + third, const Fraction(1));
    expect(const Fraction(3, 4) - const Fraction(1, 4), const Fraction(1, 2));
    expect(const Fraction(1, 4) * const Fraction(3), const Fraction(3, 4));
  });

  test('ordre', () {
    expect(const Fraction(1, 4) < const Fraction(1, 2), isTrue);
    expect(const Fraction(3, 4) > const Fraction(2, 3), isTrue);
    expect([const Fraction(1), const Fraction(1, 4), Fraction.zero]..sort(), [
      Fraction.zero,
      const Fraction(1, 4),
      const Fraction(1),
    ]);
  });

  test('affichage réduit', () {
    expect('${const Fraction(6, 8)}', '3/4');
    expect('${const Fraction(4, 2)}', '2');
  });
}
