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
    expect(parse('X:1\r\nL:1/1\r\nK:C\r\nC D\r\n'), 'treble(C4 D4)');
  });

  test('do central : C, en clé de sol sur la 1re ligne supplémentaire', () {
    final staff = parseAbc('X:1\nL:1/1\nK:C\nC\n').staves.single;
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

  group('armures', () {
    KeySignature key(String name) =>
        parseAbc('X:1\nK:$name\n').staves.single.key;

    test('majeures et mineures', () {
      expect(key('C'), KeySignature.none);
      expect(key('Am'), KeySignature.none);
      expect(key('G'), const KeySignature(1));
      expect(key('Em'), const KeySignature(1));
      expect(key('F'), const KeySignature(-1));
      expect(key('Dm'), const KeySignature(-1));
      expect(key('F#'), const KeySignature(6));
      expect(key('C#'), const KeySignature(7));
      expect(key('Cb'), const KeySignature(-7));
      expect(key('Bbm'), const KeySignature(-5));
      expect(key('A#m'), const KeySignature(7));
    });

    test('la clé suit la tonalité', () {
      final staff = parseAbc('X:1\nK:D clef=bass\n').staves.single;
      expect(staff.key, const KeySignature(2));
      expect(staff.clef, Clef.bass);
    });

    test('formes refusées', () {
      expect(() => parseAbc('X:1\nK:Gmin\n'), error(2, 3, 'Gmin'));
      expect(() => parseAbc('X:1\nK:none\n'), error(2, 3, 'none'));
      expect(() => parseAbc('X:1\nK:Fb\n'), error(2, 3, '7 altérations'));
      expect(() => parseAbc('X:1\nK:D#m\n'), isNot(throwsA(anything)));
    });
  });

  group('durées', () {
    test('relatives à L:', () {
      expect(parse('X:1\nL:1/4\nK:C\nC4 D2 E\n'), 'treble(C4 D4:2 E4:4)');
      expect(parse('X:1\nL:1/8\nK:C\nC8 D4 E2\n'), 'treble(C4 D4:2 E4:4)');
      expect(
        parse('X:1\nL:1/1\nK:C\nC D/ E// F/4\n'),
        'treble(C4 D4:2 E4:4 F4:4)',
      );
      expect(parse('X:1\nL:1/2\nK:C\nC2/4\n'), 'treble(C4:4)');
    });

    test('sans L:, même sans chiffre de durée', () {
      expect(() => parseAbc('X:1\nK:C\nC\n'), error(3, 1, 'L:'));
      expect(() => parseAbc('X:1\nM:4/4\nK:C\n^C\n'), error(4, 1, 'L:'));
    });

    test('figures pointées et courtes', () {
      expect(
        parse('X:1\nL:1/16\nK:C\nC12 D6 E3 F\n'),
        'treble(C4:2. D4:4. E4:8. F4:16)',
      );
      expect(parse('X:1\nL:1/4\nK:C\nz/ z3\n'), 'treble(z:8 z:2.)');
    });

    test('valeurs refusées', () {
      expect(() => parseAbc('X:1\nL:1/4\nK:C\nC6\n'), error(4, 1, 'ronde'));
      expect(() => parseAbc('X:1\nL:1/4\nK:C\nC5\n'), error(4, 1, 'ronde'));
      expect(() => parseAbc('X:1\nL:1/4\nK:C\nC0\n'), error(4, 2, 'nulle'));
      expect(() => parseAbc('X:1\nL:1/8\nK:C\nz5\n'), error(4, 1, 'silences'));
      expect(() => parseAbc('X:1\nK:C\nz\n'), error(3, 1, 'L:'));
    });
  });

  group('ligatures', () {
    test('une fin de ligne coupe le groupe', () {
      expect(
        parse('X:1\nL:1/8\nK:C\nCD\nEF\n'),
        'treble([C4:8 D4:8] [E4:8 F4:8])',
      );
    });

    test('une note plus longue coupe le groupe', () {
      expect(parse('X:1\nL:1/8\nK:C\nCD2E\n'), 'treble(C4:8 D4:4 E4:8)');
    });

    test('une liaison collée ne coupe pas le groupe', () {
      expect(parse('X:1\nL:1/8\nK:C\nC-CD\n'), 'treble([C4:8- C4:8 D4:8])');
    });

    test('un silence non ligaturable peut être collé', () {
      expect(parse('X:1\nL:1/8\nK:C\nCz2D\n'), 'treble(C4:8 z:4 D4:8)');
    });
  });

  group('liaisons de prolongation', () {
    test('entre voix entrelacées, chaque voix garde la sienne', () {
      expect(
        parse(
          'X:1\n%%score {A B}\nM:2/4\nL:1/2\nK:C\n'
          'V:A\nc- |\nV:B\nC |\nV:A\nc |]\nV:B\nC |]\n',
        ),
        '{A:treble 2/4(C5:2- | C5:2 |]) B:treble 2/4(C4:2 | C4:2 |])}',
      );
    });

    test('tieChain : toute la liaison, quelle que soit la note visée', () {
      final system = parseAbc('X:1\nM:2/4\nL:1/4\nK:C\nC D- | D- D |]\n');
      EventRef ref(int measure, int event) =>
          EventRef(staff: 0, measure: measure, event: event);
      final chain = [ref(0, 1), ref(1, 0), ref(1, 1)];
      expect(system.tieChain(ref(0, 1)), chain);
      expect(system.tieChain(ref(1, 1)), chain);
      expect(system.tieChain(ref(0, 0)), [ref(0, 0)]);
      expect(system.tieChain(ref(2, 0)), isEmpty);
    });
  });

  group('mesures', () {
    test('sans chiffrage : une seule mesure, sans barre', () {
      final staff = parseAbc('X:1\nL:1/4\nK:C\nC D E\n').staves.single;
      expect(staff.time, isNull);
      expect(staff.measures, hasLength(1));
      expect(staff.measures.single.barline, isNull);
    });

    test('mesures en 6/8 sans croche', () {
      expect(
        parse('X:1\nM:6/8\nL:1/4\nK:C\nC D E |]\n'),
        'treble 6/8(C4:4 D4:4 E4:4 |])',
      );
    });

    test('voix vide à côté de mesures : portée vide', () {
      expect(
        parse('X:1\n%%score {A B}\nM:2/4\nL:1/2\nK:C\nV:A\nc | c |]\n'),
        '{A:treble 2/4(C5:2 | C5:2 |]) B:treble 2/4()}',
      );
    });

    test('fin alternative refusée', () {
      expect(
        () => parseAbc('X:1\nM:2/4\nL:1/2\nK:C\nC |1 D |\n'),
        error(5, 3, 'fin alternative'),
      );
    });

    test('chiffrage invalide', () {
      expect(() => parseAbc('X:1\nM:13/4\nK:C\n'), error(2, 3, '1 à 12'));
      expect(
        () => parseAbc('X:1\nM:3/3\nK:C\n'),
        error(2, 3, 'chiffre du bas'),
      );
      expect(() => parseAbc('X:1\nM:C|\nK:C\n'), error(2, 3, 'M:2/2'));
      expect(() => parseAbc('X:1\nM:3/4\nM:3/4\nK:C\n'), error(3, 1, 'double'));
    });
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
      expect(
        () => parseAbc('X:1\nL:1/1\nK:C\nC\nK:C\n'),
        error(5, 1, 'changement'),
      );
    });

    test('altération sans note', () {
      expect(
        () => parseAbc('X:1\nL:1/1\nK:C\nC ^ D\n'),
        error(4, 4, 'note attendue'),
      );
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
        () => parseAbc('X:1\nL:1/1\nK:C\nC\nV:A\nD\n'),
        error(5, 1, 'musique avant le premier V:'),
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
