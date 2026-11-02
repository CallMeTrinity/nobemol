import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/ui/motion.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool reduced = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ),
  );

  String format(int value) => '$value points';

  testWidgets('un score défile depuis zéro jusqu’à sa valeur', (tester) async {
    await pump(tester, CountUp(value: 150, from: 0, format: format));
    expect(find.text('0 points'), findsOneWidget);

    await tester.pump(Motion.count ~/ 2);
    expect(find.text('0 points'), findsNothing);
    expect(find.text('150 points'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('150 points'), findsOneWidget);
  });

  testWidgets('un score change : il défile depuis la valeur affichée', (
    tester,
  ) async {
    await pump(tester, CountUp(value: 10, from: 10, format: format));
    expect(find.text('10 points'), findsOneWidget);

    await pump(tester, CountUp(value: 20, from: 10, format: format));
    await tester.pump(Motion.count ~/ 2);
    expect(find.text('10 points'), findsNothing);
    expect(find.text('20 points'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('20 points'), findsOneWidget);
  });

  testWidgets('animations supprimées : la valeur finale tout de suite', (
    tester,
  ) async {
    await pump(
      tester,
      CountUp(value: 150, from: 0, format: format),
      reduced: true,
    );
    await tester.pump();
    expect(find.text('150 points'), findsOneWidget);

    await pump(
      tester,
      const Reveal(delay: Duration(seconds: 1), child: Text('palier')),
      reduced: true,
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('un bloc entre après son délai', (tester) async {
    await pump(
      tester,
      const Reveal(delay: Duration(milliseconds: 200), child: Text('score')),
    );
    double opacity() => tester.widget<Opacity>(find.byType(Opacity)).opacity;

    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 150));
    expect(opacity(), 0);
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('une réponse fausse tremble, puis revient à sa place', (
    tester,
  ) async {
    double dx() => tester
        .widget<Transform>(find.byType(Transform))
        .transform
        .getTranslation()
        .x;

    await pump(tester, const Shake(active: false, child: Text('ré')));
    expect(dx(), 0);

    await pump(tester, const Shake(active: true, child: Text('ré')));
    await tester.pump(const Duration(milliseconds: 25));
    expect(dx(), isNot(0));

    await tester.pumpAndSettle();
    expect(dx(), closeTo(0, 0.01));
  });
}
