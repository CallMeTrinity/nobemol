import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/review/card.dart';

void main() {
  late Content content;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await loadContent(rootBundle);
  });

  /// Toutes les questions d'un exercice, dans l'ordre.
  List<Question> questionsOf(ReadingExercise exercise, {int seed = 1}) {
    final source = exercise.questions(Random(seed));
    Question? previous;
    return [
      for (var i = 0; i < exercise.length; i++)
        previous = source.next(previous: previous),
    ];
  }

  test('format des cartes stocké', () {
    final noteLesson = content.lessons.firstWhere(
      (lesson) => lesson.id == 'key-signature',
    );
    // Un fa de l'armure de ré majeur : la carte garde le fa dièse lu.
    final cards = questionsOf(noteLesson.exercise).map(cardOf).toSet();
    expect(cards, contains(matches(RegExp(r'^note:treble:fSharp\d$'))));

    const bassF = Pitch(DiatonicStep.f, 3);
    expect(
      cardOf(
        NoteQuestion(
          system: System.single(
            const Staff(
              clef: Clef.bass,
              measures: [
                Measure([Note(bassF)]),
              ],
            ),
          ),
          pitch: bassF,
          target: const EventRef(staff: 0, measure: 0, event: 0),
          answer: NoteName.f,
        ),
      ),
      'note:bass:f3',
    );
  });

  test('chaque cible des leçons fait l’aller-retour carte, question', () {
    var count = 0;
    for (final lesson in content.lessons) {
      for (final question in questionsOf(lesson.exercise)) {
        final card = cardOf(question);
        final back = questionOf(card);
        expect(back, isNotNull, reason: '${lesson.id} : $card');
        expect(back!.answer, question.answer, reason: card);
        expect(back.runtimeType, question.runtimeType, reason: card);
        expect(cardOf(back), card, reason: '${lesson.id} : $card');
        count++;
      }
    }
    expect(count, greaterThan(100));
  });

  test('notes tirées au hasard, toutes les portées, altérées', () {
    for (final staff in StaffSetup.values) {
      final exercise = NoteReadingParams(
        staff: staff,
        ledgerLines: 2,
        accidentals: true,
      );
      for (final question in questionsOf(exercise, seed: staff.index)) {
        final card = cardOf(question);
        final back = questionOf(card)! as NoteQuestion;
        expect(back.answer, question.answer, reason: card);
        expect(cardOf(back), card);
        // Seule sur sa portée, dans sa clé : la grande portée se défait.
        expect(back.system.staves, hasLength(1));
      }
    }
  });

  test('durées : figures, silences, liaisons', () {
    expect(
      (questionOf('duration:quarter.dotted')! as DurationQuestion).answer,
      Beats.oneAndHalf,
    );
    expect(
      (questionOf('duration:rest.eighth')! as DurationQuestion).answer,
      Beats.half,
    );
    final tied = questionOf('duration:half+quarter')! as DurationQuestion;
    expect(tied.answer, Beats.three);
    expect(tied.targets, hasLength(2));
  });

  test('signes : nuance, soufflet, terme', () {
    expect(questionOf('marking:dynamic:mp')!.answer, Marking.mezzoPiano);
    final hairpin = questionOf('marking:hairpin:diminuendo')!;
    expect(hairpin.answer, Marking.diminuendo);
    expect(hairpin.decorationTargets, hasLength(1));
    // Un terme garde son écriture : « rall. » n'est pas « rit. ».
    expect(questionOf('marking:above:rall.')!.answer, Marking.ritardando);
    expect(
      cardOf(questionOf('marking:above:a tempo')!),
      'marking:above:a tempo',
    );
  });

  test('carte illisible : null, jamais d’erreur', () {
    for (final card in [
      '',
      'note',
      'note:violin:c4',
      'note:treble:eSharp4',
      'note:treble:c',
      'duration:quarter.triplet',
      'duration:rest',
      'duration:rest.half+quarter',
      'duration:whole+whole',
      'marking:dynamic:sfz',
      'marking:above:allegro',
      'chord:c-e-g',
    ]) {
      expect(questionOf(card), isNull, reason: card);
    }
  });

  test('réponses d’un signe : celles de sa première leçon', () {
    expect(markingChoices(content, Marking.crescendo), [
      Marking.piano,
      Marking.forte,
      Marking.crescendo,
      Marking.diminuendo,
    ]);
    expect(markingChoices(content, Marking.pianississimo), isEmpty);
  });
}
