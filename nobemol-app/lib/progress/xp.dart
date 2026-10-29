/// XP d'une bonne réponse.
const xpPerAnswer = 10;

/// Bonus de combo : à partir de la 5e bonne réponse d'affilée, chacune
/// rapporte 5 XP de plus.
const comboBonusFrom = 5;
const comboBonus = 5;

/// Objectif du jour, fixe jusqu'aux réglages (étape 9).
const dailyGoal = 100;

/// XP d'une réponse. [combo] compte les bonnes réponses d'affilée, celle-ci
/// comprise : 0 pour une réponse fausse.
int answerXp(int combo) => switch (combo) {
  0 => 0,
  < comboBonusFrom => xpPerAnswer,
  _ => xpPerAnswer + comboBonus,
};

/// Niveau atteint avec un total d'XP. Le palier du niveau n est à
/// 100 × n × (n − 1) XP : 200 pour le niveau 2, 600 pour le 3, 1 200 pour
/// le 4. Chaque niveau demande 200 XP de plus que le précédent.
class Level {
  const Level._(this.number, this.xp);

  factory Level.of(int xp) {
    var number = 1;
    while (threshold(number + 1) <= xp) {
      number++;
    }
    return Level._(number, xp);
  }

  /// À partir de 1.
  final int number;

  /// Total d'XP.
  final int xp;

  /// XP nécessaires pour atteindre le niveau [number].
  static int threshold(int number) => 100 * number * (number - 1);

  /// XP gagnés depuis le début du niveau.
  int get progress => xp - threshold(number);

  /// XP du niveau entier, de son palier au suivant.
  int get span => threshold(number + 1) - threshold(number);
}
