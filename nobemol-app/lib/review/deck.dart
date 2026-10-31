import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/review/card.dart';
import 'package:nobemol/review/leitner.dart';

/// Cartes d'une session de révision : environ 3 minutes, à une dizaine de
/// secondes par réponse, correction comprise.
const reviewLength = 15;

/// Seuil des « plus difficiles » : une carte ratée une fois n'en est pas
/// une.
const _hardMisses = 2;

/// Les cartes de révision, vues le jour [today].
class Deck {
  Deck(this.content, Iterable<ReviewCard> cards, DateTime today)
    : cards = List.unmodifiable(cards),
      today = dayOf(today);

  final Content content;
  final List<ReviewCard> cards;
  final DateTime today;

  /// Cartes à réviser aujourd'hui, les plus en retard d'abord, puis les
  /// plus fragiles (boîte la plus basse).
  late final List<ReviewCard> due = [
    for (final card in cards)
      if (card.isDue(today)) card,
  ]..sort(_byDue);

  int get fresh => cards.where((card) => card.fresh).length;
  int get acquired => cards.where((card) => card.acquired).length;

  /// Jours avant la prochaine carte due, `null` sans carte à venir. Utile
  /// quand rien n'est dû aujourd'hui.
  int? get daysToNext {
    final upcoming = [
      for (final card in cards)
        if (!card.isDue(today)) card.due,
    ]..sort();
    final next = upcoming.firstOrNull;
    if (next == null) return null;
    // En UTC : un changement d'heure ne fait pas un jour de 23 heures.
    return DateTime.utc(
      next.year,
      next.month,
      next.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  }

  /// Les cartes les plus ratées, ratées au moins deux fois : les plus
  /// d'erreurs d'abord, puis la dernière ratée.
  late final List<ReviewCard> hardest =
      [
        for (final card in cards)
          if (card.misses >= _hardMisses) card,
      ]..sort(
        (a, b) => b.misses != a.misses
            ? b.misses.compareTo(a.misses)
            : b.lastMiss.compareTo(a.lastMiss),
      );

  /// Session de révision : les [reviewLength] premières cartes dues, puis
  /// rangées par sorte (notes, durées, signes) pour que les réponses ne
  /// changent pas à chaque question. `null` si rien n'est dû.
  ///
  /// Une carte qui ne se lit plus (signe absent des leçons) est sautée.
  ReviewExercise? session() {
    final questions = <Question>[];
    final choices = <Marking, List<Marking>>{};
    for (final card in due) {
      if (questions.length == reviewLength) break;
      final question = questionOf(card.card);
      if (question == null) continue;
      if (question case MarkingQuestion(:final answer)) {
        if ((choices[answer] ??= markingChoices(content, answer)).isEmpty) {
          continue;
        }
      }
      questions.add(question);
    }
    if (questions.isEmpty) return null;
    // Tri stable : l'ordre des cartes dues reste dans chaque sorte.
    final ordered = questions.indexed.toList()
      ..sort(
        (a, b) => _kind(a.$2) != _kind(b.$2)
            ? _kind(a.$2).compareTo(_kind(b.$2))
            : a.$1.compareTo(b.$1),
      );
    return ReviewExercise(
      cards: [for (final (_, question) in ordered) question],
      markingChoices: {
        for (final MapEntry(:key, :value) in choices.entries)
          if (value.isNotEmpty) key: value,
      },
    );
  }
}

int _byDue(ReviewCard a, ReviewCard b) => a.due != b.due
    ? a.due.compareTo(b.due)
    : a.box != b.box
    ? a.box.compareTo(b.box)
    : a.card.compareTo(b.card);

int _kind(Question question) => switch (question) {
  NoteQuestion() => 0,
  DurationQuestion() => 1,
  MarkingQuestion() => 2,
};
