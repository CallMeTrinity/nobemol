import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/placement/placement.dart';
import 'package:nobemol/reading/note_reading.dart';

void main() {
  late Content content;
  late List<PlacementSkill> skills;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await loadContent(rootBundle);
    skills = placementSkills(content);
  });

  /// Répond juste aux compétences de [known], faux aux autres, jusqu'à la
  /// fin. Rend le nombre de questions posées.
  int play(PlacementTest test, Set<String> known) {
    var asked = 0;
    while (!test.finished) {
      asked++;
      test.answer(right: known.contains(test.current!.skill.id));
    }
    return asked;
  }

  test('les compétences qui se lisent, dans l’ordre de l’arbre', () {
    final ids = [for (final skill in skills) skill.skill.id];
    expect(ids.first, 'note-reading.treble');
    expect(
      ids,
      containsAll([
        'note-reading.grand',
        'note-reading.key-signatures',
        'rhythm.sixteenths',
        'terms.character',
        'symbols.articulations',
        'intervals.harmonic',
      ]),
    );
    // Ni oreille ni rythme tapé, ni compétence sans leçon.
    expect(ids.where((id) => id.startsWith('ear.')), isEmpty);
    expect(ids, isNot(contains('rhythm.tap')));
    expect(ids, isNot(contains('note-reading.alto')));
    // Un prérequis est toujours testé avant.
    for (final (index, skill) in skills.indexed) {
      for (final id in skill.skill.requires) {
        expect(ids.indexOf(id), inInclusiveRange(0, index - 1));
      }
    }
  });

  test('un débutant sort après deux questions, sans rien d’acquis', () {
    final test = PlacementTest(skills, Random(1));
    expect(play(test, {}), 2);
    expect(test.passed, isEmpty);
    expect(test.progress, 1);
  });

  test('un lecteur confirmé : deux questions par compétence, toutes '
      'acquises', () {
    final test = PlacementTest(skills, Random(1));
    final all = {for (final skill in skills) skill.skill.id};
    expect(play(test, all), 2 * skills.length);
    expect(test.passed, all);
  });

  test('une branche ratée écarte ce qui la suit, pas le reste', () {
    final test = PlacementTest(skills, Random(1));
    // Un violoniste : clé de sol, lignes et altérations, pas la clé de fa.
    final known = {
      for (final skill in skills)
        if (skill.skill.id != 'note-reading.bass') skill.skill.id,
    };
    play(test, known);
    expect(test.passed, contains('note-reading.ledger-lines'));
    expect(test.passed, contains('note-reading.key-signatures'));
    expect(test.passed, contains('rhythm.dotted'));
    expect(test.passed, isNot(contains('note-reading.bass')));
    // La grande portée demande la clé de fa : pas posée.
    expect(test.passed, isNot(contains('note-reading.grand')));
  });

  test('deux sur trois : une erreur ne coûte pas la compétence', () {
    final test = PlacementTest(skills, Random(1))
      ..answer(right: true)
      ..answer(right: false);
    expect(test.current!.skill.id, 'note-reading.treble');
    test.answer(right: true);
    expect(test.passed, {'note-reading.treble'});
    expect(test.current!.skill.id, isNot('note-reading.treble'));

    final failed = PlacementTest(skills, Random(1))
      ..answer(right: false)
      ..answer(right: true)
      ..answer(right: false);
    expect(failed.finished, isTrue);
    expect(failed.passed, isEmpty);
  });

  test('des notes qui distinguent la compétence de ses prérequis', () {
    for (final id in [
      'note-reading.ledger-lines',
      'note-reading.accidentals',
      'note-reading.grand',
    ]) {
      for (var seed = 0; seed < 30; seed++) {
        final test = PlacementTest(skills, Random(seed));
        while (test.current!.skill.id != id) {
          test.answer(right: true);
        }
        final params = test.current!.exercise as NoteReadingParams;
        final question = test.question! as NoteQuestion;
        if (params.accidentals) {
          expect(question.pitch.accidental, isNotNull, reason: id);
        }
        if (params.ledgerLines > 0) {
          final clef = question.system.staves
              .elementAt(question.target.staff)
              .clef;
          final position = clef.staffPosition(question.pitch);
          expect(position < -1 || position > 9, isTrue, reason: id);
        }
      }
    }
  });
}
