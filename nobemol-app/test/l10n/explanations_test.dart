import 'package:flutter_test/flutter_test.dart';
import 'package:notation/core.dart';

import 'package:nobemol/l10n/app_localizations_fr.dart';
import 'package:nobemol/l10n/explanations.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';
import 'package:nobemol/settings/settings.dart';

void main() {
  final l10n = AppLocalizationsFr();
  const solfege = NoteNaming.solfege;

  /// Question sur la note [event] de la première mesure de [abc].
  NoteQuestion note(String abc, int event, {String? explanation}) {
    final system = parseAbc(abc);
    final target = EventRef(staff: 0, measure: 0, event: event);
    return NoteQuestion(
      system: system,
      pitch: (system.event(target)! as Note).pitch,
      target: target,
      answer: noteNameAt(system, target)!,
      explanation: explanation,
    );
  }

  DurationQuestion duration(String abc, int measure, int event) {
    final system = parseAbc(abc);
    final targets = system.tieChain(
      EventRef(staff: 0, measure: measure, event: event),
    );
    return DurationQuestion(
      system: system,
      targets: targets,
      answer: Beats.of(beatsOf(system, targets))!,
    );
  }

  const treble = 'X:1\nL:1/4\nK:C\n';

  group('notes : la place sur la portée', () {
    test('ligne et interligne', () {
      expect(
        l10n.explain(note('${treble}G F', 0), naming: solfege),
        'En clé de sol, la 2e ligne est un sol.',
      );
      expect(
        l10n.explain(note('${treble}G F', 1), naming: solfege),
        'En clé de sol, le 1er interligne est un fa.',
      );
    });

    test('autour de la portée et lignes supplémentaires', () {
      expect(
        l10n.explain(note('${treble}D', 0), naming: solfege),
        "En clé de sol, juste sous la portée, c'est un ré.",
      );
      expect(
        l10n.explain(note('${treble}C', 0), naming: solfege),
        'En clé de sol, la 1re ligne supplémentaire en dessous est un do.',
      );
      expect(
        l10n.explain(note('${treble}b', 0), naming: solfege),
        "En clé de sol, au-dessus de la 1re ligne supplémentaire, c'est un si.",
      );
    });

    test('clé de fa', () {
      expect(
        l10n.explain(note('X:1\nL:1/4\nK:C clef=bass\nF,', 0), naming: solfege),
        'En clé de fa, la 4e ligne est un fa.',
      );
    });

    test('l’altération et sa cause', () {
      expect(
        l10n.explain(note('X:1\nL:1/4\nK:G\nF', 0), naming: solfege),
        'En clé de sol, le 1er interligne est un fa. '
        "L'armure en fait un fa dièse.",
      );
      expect(
        l10n.explain(note('${treble}_B B', 1), naming: solfege),
        'En clé de sol, la 3e ligne est un si. '
        'Le bémol écrit plus tôt dans la mesure vaut encore : si bémol.',
      );
    });

    test('l’explication de l’auteur passe avant', () {
      expect(
        l10n.explain(
          note('${treble}G', 0, explanation: 'Le sol de la clé.'),
          naming: solfege,
        ),
        'Le sol de la clé.',
      );
    });
  });

  group('durées', () {
    const phrase = 'X:1\nM:4/4\nL:1/4\nK:C\n';

    test('une figure', () {
      expect(
        l10n.explain(duration('${phrase}C2 z2 |]', 0, 0), naming: solfege),
        'Blanche : 2 temps.',
      );
      expect(
        l10n.explain(duration('${phrase}C2 z2 |]', 0, 1), naming: solfege),
        'Demi-pause : 2 temps.',
      );
    });

    test('pointée : le point ajoute la moitié', () {
      expect(
        l10n.explain(duration('${phrase}C3/2 D/ E2 |]', 0, 0), naming: solfege),
        'Noire pointée : 1½ temps. Le point ajoute la moitié de la valeur.',
      );
    });

    test('liée : les temps s’additionnent', () {
      expect(
        l10n.explain(
          duration('${phrase}C D E2- | E C3 |]', 0, 2),
          naming: solfege,
        ),
        'Blanche liée à une noire : 2 + 1 = 3 temps.',
      );
    });
  });

  test('signes : le sens et comment le reconnaître', () {
    final question = MarkingQuestion(
      system: parseAbc(treble),
      target: const EventRef(staff: 0, measure: 0, event: 0),
      answer: Marking.piano,
    );
    expect(l10n.explain(question, naming: solfege), 'p : piano, doux.');
    expect(
      l10n.feedbackTitle(question, right: true, naming: solfege),
      'Juste, ça veut dire « doux »',
    );
  });

  test('titres de la correction', () {
    final question = note('X:1\nL:1/4\nK:G\nF', 0);
    expect(
      l10n.feedbackTitle(question, right: true, naming: solfege),
      "Juste, c'est un fa dièse",
    );
    expect(
      l10n.feedbackTitle(question, right: false, naming: solfege),
      "C'est un fa dièse",
    );
  });

  test('temps en chiffres', () {
    expect(formatBeats(const Fraction(3)), '3');
    expect(formatBeats(const Fraction(1, 2)), '½');
    expect(formatBeats(const Fraction(6, 4)), '1½');
    expect(formatBeats(const Fraction(3, 8)), '⅜');
  });
}
