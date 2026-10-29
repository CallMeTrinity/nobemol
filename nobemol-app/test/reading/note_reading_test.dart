import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:notation/notation.dart';

import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';

void main() {
  List<NoteQuestion> draw(NoteReadingParams params, {int count = 500}) {
    final generator = NoteGenerator(params, Random(42));
    final questions = <NoteQuestion>[];
    for (var i = 0; i < count; i++) {
      questions.add(
        generator.next(previous: questions.isEmpty ? null : questions.last),
      );
    }
    return questions;
  }

  /// La portée qui porte la note, et sa position.
  (Staff, int) placed(NoteQuestion question) {
    final staff = question.system.staves.singleWhere((s) => s.notes.isNotEmpty);
    return (staff, staff.clef.staffPosition(question.pitch));
  }

  test('la tessiture suit le nombre de lignes supplémentaires', () {
    for (final ledgerLines in [0, 1, 2]) {
      final params = NoteReadingParams(
        staff: StaffSetup.treble,
        ledgerLines: ledgerLines,
      );
      final positions = draw(params).map((q) => placed(q).$2).toSet();
      expect(positions.reduce(min), params.lowestPosition);
      expect(positions.reduce(max), params.highestPosition);
    }
  });

  test('sans ligne supplémentaire : de ré4 à sol5 en clé de sol', () {
    final pitches = draw(const NoteReadingParams(staff: StaffSetup.treble))
        .map((q) => q.pitch)
        .toSet();
    expect(pitches, contains(const Pitch(DiatonicStep.d, 4)));
    expect(pitches, contains(const Pitch(DiatonicStep.g, 5)));
    expect(pitches, hasLength(11));
  });

  test('clé de fa', () {
    final clefs = draw(const NoteReadingParams(staff: StaffSetup.bass))
        .map((q) => placed(q).$1.clef)
        .toSet();
    expect(clefs, {Clef.bass});
  });

  test('grande portée : les deux portées sont tirées', () {
    final questions = draw(const NoteReadingParams(staff: StaffSetup.grand));
    for (final question in questions) {
      expect(question.system.groups.single.symbol, GroupSymbol.brace);
    }
    final clefs = questions.map((q) => placed(q).$1.clef).toSet();
    expect(clefs, {Clef.treble, Clef.bass});
  });

  test('la note tirée est la cible, sur sa portée', () {
    for (final params in const [
      NoteReadingParams(staff: StaffSetup.treble),
      NoteReadingParams(staff: StaffSetup.grand),
    ]) {
      for (final question in draw(params, count: 50)) {
        final target = question.targets.single;
        expect(
          question.system.event(target),
          isA<Note>().having((n) => n.pitch, 'pitch', question.pitch),
        );
      }
    }
  });

  test('altérations seulement si demandées', () {
    final without = draw(const NoteReadingParams(staff: StaffSetup.treble));
    expect(without.where((q) => q.pitch.accidental != null), isEmpty);

    final withAccidentals = draw(
      const NoteReadingParams(staff: StaffSetup.treble, accidentals: true),
    ).map((q) => q.pitch.accidental).toSet();
    expect(withAccidentals, {null, Accidental.sharp, Accidental.flat});
  });

  test('jamais deux fois la même note de suite', () {
    final questions = draw(const NoteReadingParams(staff: StaffSetup.treble));
    for (var i = 1; i < questions.length; i++) {
      expect(questions[i].pitch, isNot(questions[i - 1].pitch));
    }
  });

  test('la réponse porte l’altération, toujours sur une touche noire', () {
    final questions = draw(
      const NoteReadingParams(staff: StaffSetup.treble, accidentals: true),
    );
    for (final question in questions) {
      expect(question.answer.step, question.pitch.step);
      expect(question.answer.accidental, question.pitch.accidental);
    }
    // Pas de mi dièse, de si dièse, de fa bémol ni de do bémol.
    expect(
      questions.where(
        (q) => switch ((q.pitch.step, q.pitch.accidental)) {
          (DiatonicStep.e || DiatonicStep.b, Accidental.sharp) => true,
          (DiatonicStep.f || DiatonicStep.c, Accidental.flat) => true,
          _ => false,
        },
      ),
      isEmpty,
    );
  });

  test('identify-note : les cibles dans l’ordre, avec leur hauteur', () {
    final system = parseAbc('X:1\nM:2/4\nL:1/4\nK:G\nB d | f2 |]\n');
    const targets = [
      EventRef(staff: 0, measure: 1, event: 0),
      EventRef(staff: 0, measure: 0, event: 0),
    ];
    final questions = IdentifyNoteExercise(
      system: system,
      targets: targets,
    ).questions(Random(1));

    final first = questions.next() as NoteQuestion;
    final second = questions.next(previous: first) as NoteQuestion;
    expect(first.targets, [targets[0]]);
    // f en sol majeur : écrit sans altération, l'armure en fait un fa
    // dièse.
    expect(first.pitch, const Pitch(DiatonicStep.f, 5));
    expect(first.answer, NoteName.fSharp);
    expect(second.targets, [targets[1]]);
    expect(second.answer, NoteName.b);
    expect(second.system, same(system));
  });
}
