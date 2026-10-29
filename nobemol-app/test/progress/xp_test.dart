import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/progress/xp.dart';

void main() {
  test('10 XP par bonne réponse, 5 de plus à partir de la 5e d’affilée', () {
    expect(
      [for (var combo = 0; combo <= 6; combo++) answerXp(combo)],
      [0, 10, 10, 10, 10, 15, 15],
    );
  });

  test('paliers de niveau : 200, 600, 1 200 XP', () {
    expect(Level.of(0).number, 1);
    expect(Level.of(199).number, 1);
    expect(Level.of(200).number, 2);
    expect(Level.of(599).number, 2);
    expect(Level.of(600).number, 3);
    expect(Level.of(1200).number, 4);
  });

  test('XP dans le niveau', () {
    final level = Level.of(250);
    expect(level.progress, 50);
    expect(level.span, 400);
    expect(Level.of(0).span, 200);
  });
}
