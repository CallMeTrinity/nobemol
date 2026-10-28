import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/reading/markings.dart';

void main() {
  test('identifiants des leçons en minuscules et tirets', () {
    expect(Marking.mezzoPiano.id, 'mezzo-piano');
    expect(Marking.aTempo.id, 'a-tempo');
    for (final marking in Marking.values) {
      expect(Marking.byId(marking.id), marking);
    }
    expect(Marking.byId('sforzando'), isNull);
  });

  test('chaque sens s’écrit avec un signe ou un terme', () {
    const decorations = <Decoration>[
      ...Dynamic.values,
      ...Articulation.values,
      HairpinStart(Hairpin.crescendo),
      HairpinStart(Hairpin.diminuendo),
    ];
    expect({
      ...decorations.map(markingOf),
      ...terms.values,
    }, Marking.values.toSet());
  });

  test('un soufflet et son terme ont le même sens', () {
    expect(
      markingOf(const HairpinStart(Hairpin.crescendo)),
      markingOf(const Annotation('cresc.', placement: Placement.below)),
    );
    expect(markingOf(const HairpinEnd(Hairpin.crescendo)), isNull);
    expect(
      markingOf(const Annotation('poco', placement: Placement.below)),
      isNull,
    );
  });
}
