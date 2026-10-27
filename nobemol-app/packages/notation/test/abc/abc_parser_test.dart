import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

import '../helpers/describe_system.dart';

void main() {
  String parse(String source) => describeSystem(parseAbc(source));

  Matcher error(int line, int column, String message) => throwsA(
    isA<AbcException>()
        .having((e) => e.line, 'line', line)
        .having((e) => e.column, 'column', column)
        .having((e) => e.message, 'message', contains(message)),
  );

  test('fins de ligne Windows', () {
    expect(parse('X:1\r\nK:C\r\nC D\r\n'), 'treble(C4 D4)');
  });

  test('do central : C, en clé de sol sur la 1re ligne supplémentaire', () {
    final staff = parseAbc('X:1\nK:C\nC\n').staves.single;
    expect(staff.clef.staffPosition(staff.notes.single.pitch), -2);
  });

  test('voix de %%score jamais déclarée : portée vide, clé de K:', () {
    expect(parse('X:1\n%%score {A B}\nK:C clef=bass\n'), '{A:bass() B:bass()}');
  });

  test('voix hors accolade dans %%score', () {
    expect(
      parse('X:1\n%%score S {RH LH}\nK:C\n'),
      'S:treble() {RH:treble() LH:treble()}',
    );
  });

  group('erreurs', () {
    test('morceau vide', () {
      expect(() => parseAbc(''), error(1, 1, 'X:'));
      expect(() => parseAbc('% rien\n'), error(1, 1, 'X:'));
    });

    test('X: sans numéro', () {
      expect(() => parseAbc('X:\nK:C\n'), error(1, 3, 'numéro'));
    });

    test('K: sans tonalité', () {
      expect(() => parseAbc('X:1\nK:\n'), error(2, 3, 'tonalité'));
      expect(() => parseAbc('X:1\nK:clef=bass\n'), error(2, 3, 'avant la clé'));
    });

    test('changement de tonalité dans le corps', () {
      expect(() => parseAbc('X:1\nK:C\nC\nK:C\n'), error(4, 1, 'changement'));
    });

    test('altération sans note', () {
      expect(() => parseAbc('X:1\nK:C\nC ^ D\n'), error(3, 4, 'note attendue'));
    });

    test('mauvaise marque d’octave sur une minuscule', () {
      expect(() => parseAbc('X:1\nK:C\nc,\n'), error(3, 2, "s'écrit « C »"));
    });

    test('champ dans la ligne', () {
      expect(
        () => parseAbc('X:1\nV:A\nK:C\nV:A\n[V:A] C\n'),
        error(5, 1, 'champ'),
      );
    });

    test('propriété de voix inconnue', () {
      expect(
        () => parseAbc('X:1\nV:A name="Piano"\nK:C\n'),
        error(2, 5, 'propriété'),
      );
    });

    test('%%score après K: ou en double', () {
      expect(() => parseAbc('X:1\nK:C\n%%score A\n'), error(3, 1, 'en-tête'));
      expect(
        () => parseAbc('X:1\n%%score A\n%%score A\nK:C\n'),
        error(3, 1, 'double'),
      );
    });

    test('voix en double dans %%score', () {
      expect(
        () => parseAbc('X:1\n%%score {A B} A\nK:C\n'),
        error(2, 15, 'double'),
      );
    });

    test('voix déclarée dans l’en-tête mais absente de %%score', () {
      expect(
        () => parseAbc('X:1\n%%score A\nV:B\nK:C\n'),
        error(3, 3, 'absente'),
      );
    });

    test('V: après de la musique hors voix', () {
      expect(
        () => parseAbc('X:1\nK:C\nC\nV:A\nD\n'),
        error(4, 1, 'musique avant le premier V:'),
      );
    });

    test('autres directives', () {
      expect(() => parseAbc('X:1\n%%staves A\nK:C\n'), error(2, 1, '%%staves'));
    });

    test('toString donne la position', () {
      expect(
        const AbcException(
          'durée non supportée',
          line: 3,
          column: 2,
        ).toString(),
        'ligne 3, colonne 2 : durée non supportée',
      );
    });
  });
}
