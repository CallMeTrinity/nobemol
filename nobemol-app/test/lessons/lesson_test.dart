import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/lessons/lesson.dart';
import 'package:nobemol/lessons/yaml_fields.dart';
import 'package:nobemol/reading/note_reading.dart';

void main() {
  const skills = {'note-reading.treble', 'note-reading.grand'};

  const valid = '''
id: test-lesson
title: Test
skills: [note-reading.treble]
level: 1
theory:
  - text: Sans musique.
  - text: Avec musique.
    abc: |
      X:1
      L:1/1
      K:C
      G
exercise:
  type: note-reading
  staff: grand
  ledger-lines: 2
  accidentals: true
''';

  Lesson parse(String source) =>
      parseLesson(source, fileId: 'test-lesson', skills: skills);

  Matcher error(int line, int? column, String message) => throwsA(
    isA<ContentException>()
        .having((e) => e.line, 'line', line)
        .having((e) => e.column, 'column', column)
        .having((e) => e.message, 'message', contains(message)),
  );

  test('leçon valide', () {
    final lesson = parse(valid);
    expect(lesson.id, 'test-lesson');
    expect(lesson.skills, ['note-reading.treble']);
    expect(lesson.theory, hasLength(2));
    expect(lesson.theory.first.system, isNull);
    expect(
      lesson.theory.last.system!.staves.single.notes.single.pitch,
      const Pitch(DiatonicStep.g, 4),
    );
    expect(
      lesson.exercise,
      const NoteReadingParams(
        staff: StaffSetup.grand,
        ledgerLines: 2,
        accidentals: true,
      ),
    );
  });

  test('valeurs par défaut de l’exercice', () {
    final lesson = parse(
      valid
          .replaceFirst('  ledger-lines: 2\n', '')
          .replaceFirst('  accidentals: true\n', ''),
    );
    expect(lesson.exercise, const NoteReadingParams(staff: StaffSetup.grand));
  });

  test('erreur ABC située dans le fichier YAML', () {
    expect(
      () => parse(valid.replaceFirst('      G\n', '      G2\n')),
      error(12, 7, "theory[2].abc : durée plus longue qu'une ronde"),
    );
  });

  test('erreur ABC sur une seule ligne', () {
    expect(
      () => parse(
        valid.replaceFirst(
          '    abc: |\n      X:1\n      L:1/1\n      K:C\n      G\n',
          '    abc: "X:1"\n',
        ),
      ),
      error(8, 10, 'ligne 1 de l’ABC'),
    );
  });

  test('champ inconnu : faute de frappe', () {
    expect(
      () => parse(valid.replaceFirst('ledger-lines', 'ledger_lines')),
      error(16, 3, '« ledger_lines » inconnu'),
    );
  });

  test('champ manquant', () {
    expect(
      () => parse(valid.replaceFirst('level: 1\n', '')),
      error(1, 1, '« level » manquant'),
    );
  });

  test('id différent du nom du fichier', () {
    expect(
      () => parseLesson(valid, fileId: 'other', skills: skills),
      error(1, 5, 'nom du fichier'),
    );
  });

  test('compétence inconnue', () {
    expect(
      () => parse(valid.replaceFirst('[note-reading.treble]', '[rhythm.x]')),
      error(3, 10, 'rhythm.x'),
    );
  });

  test('types vérifiés', () {
    expect(
      () => parse(valid.replaceFirst('level: 1', 'level: un')),
      error(4, 8, 'entier'),
    );
    expect(
      () => parse(valid.replaceFirst('staff: grand', 'staff: piano')),
      error(15, 10, 'piano'),
    );
    expect(
      () => parse(valid.replaceFirst('note-reading\n', 'quiz\n')),
      error(14, 9, '« quiz » inconnu (note-reading, identify-note)'),
    );
    expect(
      () => parse(valid.replaceFirst('note-reading\n', 'identify-note\n')),
      error(15, 3, '« staff » inconnu'),
    );
    expect(
      () => parse(valid.replaceFirst('accidentals: true', 'accidentals: oui')),
      error(17, 16, 'true ou false'),
    );
  });

  test('théorie vide refusée', () {
    expect(
      () => parse(
        valid.replaceFirst(
          RegExp(r'theory:\n(.|\n)*exercise:'),
          'theory: []\nexercise:',
        ),
      ),
      error(5, 9, 'liste non vide'),
    );
  });

  test('YAML mal formé', () {
    expect(
      () => parse('id: [x\n'),
      throwsA(isA<ContentException>().having((e) => e.line, 'line', isNotNull)),
    );
  });

  group('identify-note', () {
    const identify = '''
id: test-lesson
title: Test
skills: [note-reading.treble]
level: 1
theory:
  - text: Texte.
exercise:
  type: identify-note
  abc: |
    X:1
    %%score {RH LH}
    M:2/4
    L:1/4
    K:G
    V:RH
    B d | g2 |]
    V:LH clef=bass
    G, D, | G,,2 |]
  targets:
    - { staff: RH, measure: 1, event: 2 }
    - { staff: LH, measure: 2, event: 1 }
''';

    test('cibles en base 1, converties en index', () {
      final exercise = parse(identify).exercise as IdentifyNoteExercise;
      expect(exercise.system.staves, hasLength(2));
      expect(exercise.targets, const [
        EventRef(staff: 0, measure: 0, event: 1),
        EventRef(staff: 1, measure: 1, event: 0),
      ]);
      expect(exercise.length, 2);
    });

    test('une seule portée : staff facultatif', () {
      final exercise =
          parse(
                identify
                    .replaceFirst(
                      RegExp(r'    %%score(.|\n)*  targets:'),
                      '    L:1/4\n    K:C\n    C D\n  targets:',
                    )
                    .replaceFirst(RegExp(r'    - \{ staff: RH.*\n'), '')
                    .replaceFirst(
                      'staff: LH, measure: 2, event: 1',
                      'measure: 1, event: 2',
                    ),
              ).exercise
              as IdentifyNoteExercise;
      expect(exercise.targets, const [
        EventRef(staff: 0, measure: 0, event: 1),
      ]);
    });

    test('staff obligatoire avec plusieurs portées', () {
      expect(
        () => parse(identify.replaceFirst('staff: RH, ', '')),
        error(20, 7, 'plusieurs portées (RH, LH)'),
      );
    });

    test('portée inconnue', () {
      expect(
        () => parse(identify.replaceFirst('staff: RH', 'staff: XX')),
        error(20, 16, 'portée « XX » absente'),
      );
    });

    test('mesure et événement hors du morceau', () {
      expect(
        () => parse(identify.replaceFirst('measure: 1', 'measure: 3')),
        error(20, 29, 'measure : entier de 1 à 2'),
      );
      expect(
        () => parse(identify.replaceFirst('event: 1 }', 'event: 2 }')),
        error(21, 39, 'event : entier de 1 à 1'),
      );
    });

    test('cible en double', () {
      expect(
        () => parse(
          identify.replaceFirst(
            '{ staff: LH, measure: 2, event: 1 }',
            '{ staff: RH, measure: 1, event: 2 }',
          ),
        ),
        error(21, 7, 'en double'),
      );
    });

    test('erreur de mesure dans l’ABC de l’exercice', () {
      expect(
        () => parse(identify.replaceFirst('B d | g2 |]', 'B d | g |]')),
        error(16, 13, 'exercise.abc : mesure 2 incomplète'),
      );
    });

    test('champs manquants', () {
      expect(
        () => parse(identify.replaceFirst(RegExp(r'  targets:(.|\n)*'), '')),
        error(8, 3, '« targets » manquant'),
      );
    });
  });
}
