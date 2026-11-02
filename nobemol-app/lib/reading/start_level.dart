/// Point de départ choisi à la main, à la place du test de positionnement
/// (`lib/placement/`).
enum StartLevel {
  beginner(),
  knowsTreble(acquired: {'note-reading.treble'}),
  readsBoth(
    acquired: {
      'note-reading.treble',
      'note-reading.bass',
      'note-reading.ledger-lines',
      'note-reading.grand',
    },
  ),
  fluent(
    acquired: {
      'note-reading.treble',
      'note-reading.bass',
      'note-reading.ledger-lines',
      'note-reading.grand',
      'note-reading.accidentals',
    },
  );

  const StartLevel({this.acquired = const {}});

  /// Compétences que l'élève dit déjà savoir : elles comptent comme
  /// prérequis acquis, sans être maîtrisées. Leurs propres prérequis en
  /// font partie (vérifié en test).
  final Set<String> acquired;
}
