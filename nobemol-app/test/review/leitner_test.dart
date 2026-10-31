import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/review/leitner.dart';

void main() {
  const card = 'note:treble:f5';

  /// Une réponse sur [card], le jour [day] d'octobre à 18 h.
  CardAnswer answer(int day, {required bool correct, String on = card}) =>
      CardAnswer(
        card: on,
        correct: correct,
        answeredAt: DateTime(2026, 10, day, 18),
      );

  ReviewCard only(List<CardAnswer> answers) => replay(answers).values.single;

  test('une bonne réponse ne crée pas de carte', () {
    expect(replay([answer(1, correct: true)]), isEmpty);
  });

  test('ratée : boîte 1, revient le lendemain', () {
    final miss = only([answer(1, correct: false)]);
    expect(miss.box, 1);
    expect(miss.due, DateTime(2026, 10, 2));
    expect(miss.misses, 1);
    expect(miss.fresh, isTrue);
    expect(miss.isDue(DateTime(2026, 10, 1, 23, 59)), isFalse);
    expect(miss.isDue(DateTime(2026, 10, 2)), isTrue);
  });

  test('puis s’espace : 3, 7, 14 et 30 jours', () {
    final answers = [answer(1, correct: false)];
    final expected = [
      (day: 2, box: 2, due: DateTime(2026, 10, 5)),
      (day: 5, box: 3, due: DateTime(2026, 10, 12)),
      (day: 12, box: 4, due: DateTime(2026, 10, 26)),
      (day: 26, box: 5, due: DateTime(2026, 11, 25)),
    ];
    for (final step in expected) {
      answers.add(answer(step.day, correct: true));
      final card = only(answers);
      expect((card.box, card.due), (step.box, step.due), reason: '${step.day}');
    }
    final card = only(answers);
    expect(card.acquired, isTrue);
    expect(card.reviews, 4);
    expect(card.fresh, isFalse);
  });

  test('juste avant le retour : rien ne change', () {
    final card = only([
      answer(1, correct: false),
      answer(1, correct: true),
      answer(1, correct: true),
    ]);
    expect(card.box, 1);
    expect(card.due, DateTime(2026, 10, 2));
  });

  test('une seule montée par jour : la carte n’est plus due', () {
    final card = only([
      answer(1, correct: false),
      answer(2, correct: true),
      answer(2, correct: true),
    ]);
    expect(card.box, 2);
  });

  test('en retard : la bonne réponse compte, depuis le jour donné', () {
    final card = only([answer(1, correct: false), answer(9, correct: true)]);
    expect(card.box, 2);
    expect(card.due, DateTime(2026, 10, 12));
  });

  test('une erreur renvoie en boîte 1, où qu’elle soit', () {
    final card = only([
      answer(1, correct: false),
      answer(2, correct: true),
      answer(5, correct: true),
      answer(6, correct: false),
    ]);
    expect(card.box, 1);
    expect(card.due, DateTime(2026, 10, 7));
    expect(card.misses, 2);
    expect(card.lastMiss, DateTime(2026, 10, 6));
    // Le 6, la carte n'était pas due (le 12) : ce n'est pas une révision.
    expect(card.reviews, 2);
  });

  test('chaque carte a sa boîte', () {
    final cards = replay([
      answer(1, correct: false),
      answer(1, correct: false, on: 'duration:half'),
      answer(2, correct: true),
    ]);
    expect(cards[card]!.box, 2);
    expect(cards['duration:half']!.box, 1);
  });

  test('changement d’heure : le retour tombe sur le bon jour', () {
    // Passage à l'heure d'hiver en France le 25 octobre 2026.
    final late = only([
      CardAnswer(
        card: card,
        correct: false,
        answeredAt: DateTime(2026, 10, 24, 23, 30),
      ),
    ]);
    expect(late.due, DateTime(2026, 10, 25));
  });
}
