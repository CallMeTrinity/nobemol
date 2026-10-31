import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/review/card.dart';
import 'package:nobemol/review/deck.dart';
import 'package:nobemol/review/leitner.dart';

void main() {
  late Content content;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await loadContent(rootBundle);
  });

  final today = DateTime(2026, 10, 31, 9);

  ReviewCard card(
    String key, {
    int due = 31,
    int box = 1,
    int misses = 1,
    int reviews = 0,
    int lastMiss = 1,
  }) => ReviewCard(
    card: key,
    box: box,
    due: DateTime(2026, 10, due),
    misses: misses,
    reviews: reviews,
    lastMiss: DateTime(2026, 10, lastMiss),
  );

  Deck deck(List<ReviewCard> cards) => Deck(content, cards, today);

  test('dues : les plus en retard, puis les plus fragiles', () {
    final cards = deck([
      card('note:treble:c5', due: 30, box: 3),
      card('note:treble:d5', due: 31),
      card('note:treble:e5', due: 30),
      card('note:treble:f5', due: 32),
    ]);
    expect(cards.due.map((c) => c.card), [
      'note:treble:e5',
      'note:treble:c5',
      'note:treble:d5',
    ]);
    expect(cards.daysToNext, 1);
  });

  test('session : 15 cartes au plus, rangées par sorte', () {
    final cards = deck([
      card('marking:dynamic:p', due: 1),
      card('duration:half', due: 2),
      for (var i = 0; i < 20; i++) card('note:treble:c$i', due: 3 + i),
    ]);
    final session = cards.session()!;
    expect(session.length, reviewLength);
    expect(session.cards.first, isA<NoteQuestion>());
    expect(session.cards[session.length - 2], isA<DurationQuestion>());
    expect(session.cards.last, isA<MarkingQuestion>());
    // Les notes gardent l'ordre des retours.
    expect(cardOf(session.cards.first), 'note:treble:c0');
  });

  test('session : réponses de chaque question', () {
    final session = deck([
      card('note:treble:c5'),
      card('note:bass:fSharp3'),
      card('marking:hairpin:crescendo'),
    ]).session()!;
    // Une note altérée ouvre les touches noires pour toutes.
    expect(session.choicesFor(session.cards.first), NoteName.values);
    expect(session.choicesFor(session.cards.last), [
      Marking.piano,
      Marking.forte,
      Marking.crescendo,
      Marking.diminuendo,
    ]);
  });

  test('session : cartes illisibles et signes sans leçon sautés', () {
    expect(
      deck([card('note:violin:c5'), card('marking:dynamic:ppp')]).session(),
      isNull,
    );
    expect(deck([card('note:treble:c5', due: 32)]).session(), isNull);
  });

  test('nouvelles, acquises', () {
    final cards = deck([
      card('note:treble:c5'),
      card('note:treble:d5', box: 2, reviews: 1, due: 33),
      card('note:treble:e5', box: 5, reviews: 4, due: 60),
    ]);
    expect(cards.fresh, 1);
    expect(cards.acquired, 1);
    expect(cards.daysToNext, 2);
  });

  test('les plus difficiles : ratées au moins deux fois', () {
    final cards = deck([
      card('note:treble:c5', misses: 1),
      card('note:treble:d5', misses: 3, lastMiss: 2),
      card('note:treble:e5', misses: 3, lastMiss: 9),
      card('note:treble:f5', misses: 4),
    ]);
    expect(cards.hardest.map((c) => c.card), [
      'note:treble:f5',
      'note:treble:e5',
      'note:treble:d5',
    ]);
  });
}
