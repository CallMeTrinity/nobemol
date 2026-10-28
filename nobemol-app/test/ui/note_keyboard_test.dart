import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/theme/theme.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/note_keyboard.dart';

void main() {
  Future<List<DiatonicStep>> pumpKeyboard(
    WidgetTester tester, {
    Map<DiatonicStep, AnswerTone> tones = const {},
  }) async {
    final pressed = <DiatonicStep>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 336,
              child: NoteKeyboard(
                label: (step) => step.name,
                onKey: pressed.add,
                tones: tones,
              ),
            ),
          ),
        ),
      ),
    );
    return pressed;
  }

  Color background(WidgetTester tester, DiatonicStep step) {
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byKey(ValueKey('answer-${step.name}')),
        matching: find.byType(Container),
      ),
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  testWidgets('7 touches blanches, de do à si, de gauche à droite', (
    tester,
  ) async {
    final pressed = await pumpKeyboard(tester);
    final xs = [
      for (final step in DiatonicStep.values)
        tester.getCenter(find.byKey(ValueKey('answer-${step.name}'))).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));

    await tester.tap(find.text('g'));
    expect(pressed, [DiatonicStep.g]);
  });

  testWidgets('une noire inactive laisse passer l’appui à la blanche', (
    tester,
  ) async {
    final pressed = await pumpKeyboard(tester);
    // Haut du bord droit du do : sous la noire do dièse.
    final c = tester.getRect(find.byKey(const ValueKey('answer-c')));
    await tester.tapAt(Offset(c.right - 2, c.top + 10));
    expect(pressed, [DiatonicStep.c]);
  });

  testWidgets('correction : juste en vert, faux en rouge', (tester) async {
    await pumpKeyboard(
      tester,
      tones: {
        DiatonicStep.g: AnswerTone.right,
        DiatonicStep.a: AnswerTone.wrong,
      },
    );
    const colors = NobemolColors.light;
    expect(background(tester, DiatonicStep.g), colors.success);
    expect(background(tester, DiatonicStep.a), colors.danger);
    expect(background(tester, DiatonicStep.c), colors.keyWhite);
  });

  testWidgets('appui : la touche s’enfonce, puis remonte', (tester) async {
    await pumpKeyboard(tester);
    final key = find.byKey(const ValueKey('answer-e'));
    double offset() => tester
        .widget<Transform>(
          find.descendant(of: key, matching: find.byType(Transform)),
        )
        .transform
        .getTranslation()
        .y;

    expect(offset(), 0);
    final gesture = await tester.startGesture(tester.getCenter(key));
    await tester.pump();
    expect(offset(), Depths.key - Depths.pressed);
    expect(background(tester, DiatonicStep.e), NobemolColors.light.keyPressed);

    await gesture.up();
    await tester.pump();
    expect(offset(), 0);
  });
}
