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
      error(11, 8, 'theory[2].abc : durée non supportée (étape 3)'),
    );
  });

  test('erreur ABC sur une seule ligne', () {
    expect(
      () => parse(
        valid.replaceFirst(
          '    abc: |\n      X:1\n      K:C\n      G\n',
          '    abc: "X:1"\n',
        ),
      ),
      error(8, 10, 'ligne 1 de l’ABC'),
    );
  });

  test('champ inconnu : faute de frappe', () {
    expect(
      () => parse(valid.replaceFirst('ledger-lines', 'ledger_lines')),
      error(15, 3, '« ledger_lines » inconnu'),
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
      error(14, 10, 'piano'),
    );
    expect(
      () => parse(valid.replaceFirst('note-reading\n', 'identify-note\n')),
      error(13, 9, 'identify-note'),
    );
    expect(
      () => parse(valid.replaceFirst('accidentals: true', 'accidentals: oui')),
      error(16, 16, 'true ou false'),
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
}
