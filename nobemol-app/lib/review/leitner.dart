import 'dart:math';

/// Délai de retour d'une carte, en jours, par boîte : la boîte 1 revient
/// le lendemain, la dernière au bout d'un mois.
const leitnerIntervals = [1, 3, 7, 14, 30];

/// Réponse sur une carte, telle que le journal la garde.
class CardAnswer {
  const CardAnswer({
    required this.card,
    required this.correct,
    required this.answeredAt,
    this.elapsed = Duration.zero,
    this.timedOut = false,
  });

  /// Clé de la carte (voir `card.dart`).
  final String card;
  final bool correct;

  /// Fin de la session de la réponse : elle compte ce jour-là.
  final DateTime answeredAt;

  /// Temps de réponse, pour les statistiques.
  final Duration elapsed;

  /// Pas de réponse : le temps de la note est écoulé (arcade). Une erreur,
  /// qui ne compte pas dans le temps de réponse moyen.
  final bool timedOut;
}

/// Carte de révision, recalculée depuis les réponses (méthode de Leitner).
class ReviewCard {
  const ReviewCard({
    required this.card,
    required this.box,
    required this.due,
    required this.misses,
    required this.reviews,
    required this.lastMiss,
  });

  final String card;

  /// De 1 à [leitnerIntervals].length.
  final int box;

  /// Jour (minuit local) à partir duquel la carte revient.
  final DateTime due;

  /// Erreurs, où qu'elles soient : la première crée la carte.
  final int misses;

  /// Réponses données le jour du retour ou après, justes ou fausses.
  final int reviews;

  /// Jour de la dernière erreur.
  final DateTime lastMiss;

  /// Jamais revue depuis sa création.
  bool get fresh => reviews == 0;

  /// Dans la dernière boîte.
  bool get acquired => box == leitnerIntervals.length;

  /// À réviser le jour [today].
  bool isDue(DateTime today) => !due.isAfter(dayOf(today));
}

/// Jour local de [time], à minuit.
DateTime dayOf(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Cartes nées des [answers], dans l'ordre chronologique. La première
/// erreur sur une carte la crée, en boîte 1.
///
/// - Une erreur, où qu'elle soit (leçon, lecture libre, révision), renvoie
///   la carte en boîte 1 : elle revient le lendemain.
/// - La première bonne réponse du jour du retour (ou d'après) monte la
///   carte d'une boîte, où qu'elle soit donnée. Les suivantes ne comptent
///   pas : la carte n'est plus due.
/// - Une bonne réponse sur une carte qui n'existe pas, ou pas encore due,
///   ne change rien.
///
/// Calculées et pas stockées, comme la maîtrise : changer d'algorithme ne
/// demande pas de migration, il suffit de rejouer le journal.
Map<String, ReviewCard> replay(Iterable<CardAnswer> answers) {
  final cards = <String, ReviewCard>{};
  for (final answer in answers) {
    final day = dayOf(answer.answeredAt);
    final card = cards[answer.card];
    final due = card != null && !day.isBefore(card.due);
    if (!answer.correct) {
      cards[answer.card] = ReviewCard(
        card: answer.card,
        box: 1,
        due: _addDays(day, leitnerIntervals.first),
        misses: (card?.misses ?? 0) + 1,
        reviews: (card?.reviews ?? 0) + (due ? 1 : 0),
        lastMiss: day,
      );
    } else if (card != null && due) {
      final box = min(card.box + 1, leitnerIntervals.length);
      cards[answer.card] = ReviewCard(
        card: answer.card,
        box: box,
        due: _addDays(day, leitnerIntervals[box - 1]),
        misses: card.misses,
        reviews: card.reviews + 1,
        lastMiss: card.lastMiss,
      );
    }
  }
  return cards;
}

/// Ajoute des jours de calendrier : un changement d'heure ne décale rien.
DateTime _addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);
