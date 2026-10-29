import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/theme/theme.dart';
import 'package:nobemol/theme/tokens.dart';
import 'package:nobemol/ui/depth.dart';
import 'package:nobemol/ui/note_keyboard.dart';

void main() {
  Future<List<NoteName>> pumpKeyboard(
    WidgetTester tester, {
    Map<NoteName, AnswerTone> tones = const {},
    bool accidentals = false,
  }) async {
    final pressed = <NoteName>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 336,
              child: NoteKeyboard(
                label: (name) => name.name,
                onKey: pressed.add,
                accidentals: accidentals,
                tones: tones,
              ),
            ),
          ),
        ),
      ),
    );
    return pressed;
  }

  Color background(WidgetTester tester, NoteName name) {
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byKey(ValueKey('answer-${name.name}')),
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
      for (final name in NoteName.naturals)
        tester.getCenter(find.byKey(ValueKey('answer-${name.name}'))).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));

    await tester.tap(find.text('g'));
    expect(pressed, [NoteName.g]);
  });

  testWidgets('une noire inactive laisse passer l’appui à la blanche', (
    tester,
  ) async {
    final pressed = await pumpKeyboard(tester);
    // Haut du bord droit du do : sous la noire do dièse.
    final c = tester.getRect(find.byKey(const ValueKey('answer-c')));
    await tester.tapAt(Offset(c.right - 2, c.top + 10));
    expect(pressed, [NoteName.c]);
  });

  testWidgets('correction : juste en vert, faux en rouge', (tester) async {
    await pumpKeyboard(
      tester,
      tones: {NoteName.g: AnswerTone.right, NoteName.a: AnswerTone.wrong},
    );
    const colors = NobemolColors.light;
    expect(background(tester, NoteName.g), colors.success);
    expect(background(tester, NoteName.a), colors.danger);
    expect(background(tester, NoteName.c), colors.keyWhite);
  });

  Color black(WidgetTester tester, String after) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(ValueKey('black-$after')),
        matching: find.byType(DecoratedBox),
      ),
    );
    return (box.decoration as BoxDecoration).color!;
  }

  testWidgets('touche noire : deux orthographes, un fa dièse n’est pas un '
      'sol bémol', (tester) async {
    final pressed = await pumpKeyboard(tester, accidentals: true);
    expect(find.byKey(const ValueKey('answer-fSharp')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('black-f')));
    await tester.pump();
    expect(find.text('fSharp'), findsOneWidget);
    expect(find.text('gFlat'), findsOneWidget);
    expect(black(tester, 'f'), NobemolColors.light.accent);

    await tester.tap(find.byKey(const ValueKey('answer-gFlat')));
    await tester.pump();
    expect(pressed, [NoteName.gFlat]);
    expect(find.text('fSharp'), findsNothing);
  });

  testWidgets('bulle ouverte : une blanche répond, une autre noire change '
      'la bulle', (tester) async {
    final pressed = await pumpKeyboard(tester, accidentals: true);
    await tester.tap(find.byKey(const ValueKey('black-c')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('black-a')));
    await tester.pump();
    expect(find.text('cSharp'), findsNothing);
    expect(find.text('aSharp'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('answer-e')));
    await tester.pump();
    expect(pressed, [NoteName.e]);
    expect(find.text('aSharp'), findsNothing);
  });

  testWidgets('correction sur une noire : ses deux noms la colorent', (
    tester,
  ) async {
    await pumpKeyboard(
      tester,
      accidentals: true,
      tones: {NoteName.bFlat: AnswerTone.right, NoteName.b: AnswerTone.wrong},
    );
    expect(black(tester, 'a'), NobemolColors.light.success);
    expect(background(tester, NoteName.b), NobemolColors.light.danger);
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
    expect(background(tester, NoteName.e), NobemolColors.light.keyPressed);

    await gesture.up();
    await tester.pump();
    expect(offset(), 0);
  });
}
