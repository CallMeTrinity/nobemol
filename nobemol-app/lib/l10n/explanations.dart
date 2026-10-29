import 'package:notation/core.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/l10n/labels.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/note_reading.dart';

/// Textes de la correction : le titre (« Juste, c'est un ré »), et
/// l'explication, écrite par l'auteur ou générée.
extension Explanations on AppLocalizations {
  /// Titre de la correction de [question], juste ou faux.
  String feedbackTitle(Question question, {required bool right}) =>
      switch (question) {
        NoteQuestion(:final answer) =>
          right
              ? feedbackRightNote(noteFullName(answer))
              : feedbackWrongNote(noteFullName(answer)),
        DurationQuestion(:final answer) =>
          right
              ? feedbackRightDuration(beatsLabel(answer))
              : feedbackWrongDuration(beatsLabel(answer)),
        MarkingQuestion(:final answer) =>
          right
              ? feedbackRightMarking(markingLabel(answer))
              : feedbackWrongMarking(markingLabel(answer)),
      };

  /// Explication de [question] : celle de l'auteur, sinon générée.
  String explain(Question question) =>
      question.explanation ??
      switch (question) {
        NoteQuestion() => _explainNote(question),
        DurationQuestion(:final system, :final targets) => _explainDuration(
          system,
          targets,
        ),
        MarkingQuestion(:final answer) => _explainMarking(answer),
      };

  String clefName(Clef clef) => switch (clef) {
    Clef.bass => clefBass,
    Clef.alto => clefAlto,
    Clef.tenor => clefTenor,
    _ => clefTreble,
  };

  /// Place de la note sur la portée, puis d'où vient son altération.
  String _explainNote(NoteQuestion question) {
    final system = question.system;
    final target = question.target;
    final clef = system.staves.elementAt(target.staff).clef;
    final pitch = (system.event(target)! as Note).pitch;
    final position = clef.staffPosition(pitch);
    final c = clefName(clef);
    final step = noteName(pitch.step);

    final place = switch (position) {
      >= 0 && <= 8 when position.isEven => explainLine(
        c,
        position ~/ 2 + 1,
        step,
      ),
      >= 1 && <= 7 => explainSpace(c, (position + 1) ~/ 2, step),
      9 => explainJustAbove(c, step),
      -1 => explainJustBelow(c, step),
      > 9 when position.isEven => explainLedgerAbove(
        c,
        (position - 8) ~/ 2,
        step,
      ),
      > 9 => explainOverLedger(c, (position - 9) ~/ 2, step),
      _ when position.isEven => explainLedgerBelow(c, -position ~/ 2, step),
      _ => explainUnderLedger(c, (-position - 1) ~/ 2, step),
    };

    final sounding = soundingAccidental(system, target);
    if (sounding == null) return place;
    final name = noteFullName(question.answer);
    final sign = switch (sounding.accidental) {
      Accidental.sharp => 'sharp',
      Accidental.flat => 'flat',
      _ => 'natural',
    };
    final cause = switch (sounding.source) {
      AccidentalSource.written => explainWritten(sign, name),
      AccidentalSource.measure => explainMeasure(sign, name),
      AccidentalSource.tie => explainTie(name),
      AccidentalSource.key => explainKey(name),
    };
    return '$place $cause';
  }

  /// Figures de la liaison, et leurs temps additionnés.
  String _explainDuration(System system, List<EventRef> targets) {
    final events = [for (final ref in targets) system.event(ref)!];
    final figures = events.map(_figure).reduce(explainTied);
    final parts = [
      for (final event in events)
        formatBeats(event.duration * const Fraction(4)),
    ];
    final total = formatBeats(beatsOf(system, targets));
    final sum = parts.length == 1 ? total : '${parts.join(' + ')} = $total';
    final text = explainDuration(_capitalized(figures), sum);
    return events.any((event) => event.dotted) ? '$text $explainDot' : text;
  }

  /// Nom d'une figure de note ou de silence, point compris.
  String _figure(Event event) {
    final (name, feminine) = switch ((event, event.value)) {
      (Note(), NoteValue.whole) => (figureWhole, true),
      (Note(), NoteValue.half) => (figureHalf, true),
      (Note(), NoteValue.quarter) => (figureQuarter, true),
      (Note(), NoteValue.eighth) => (figureEighth, true),
      (Note(), NoteValue.sixteenth) => (figureSixteenth, true),
      (Rest(), NoteValue.whole) => (restWhole, true),
      (Rest(), NoteValue.half) => (restHalf, true),
      (Rest(), NoteValue.quarter) => (restQuarter, false),
      (Rest(), NoteValue.eighth) => (restEighth, false),
      (Rest(), NoteValue.sixteenth) => (restSixteenth, false),
    };
    if (!event.dotted) return name;
    return feminine ? dottedFeminine(name) : dottedMasculine(name);
  }

  String _explainMarking(Marking marking) => switch (marking) {
    Marking.pianississimo => explainPianississimo,
    Marking.pianissimo => explainPianissimo,
    Marking.piano => explainPiano,
    Marking.mezzoPiano => explainMezzoPiano,
    Marking.mezzoForte => explainMezzoForte,
    Marking.forte => explainForte,
    Marking.fortissimo => explainFortissimo,
    Marking.fortississimo => explainFortississimo,
    Marking.crescendo => explainCrescendo,
    Marking.diminuendo => explainDiminuendo,
    Marking.staccato => explainStaccato,
    Marking.tenuto => explainTenuto,
    Marking.accent => explainAccent,
    Marking.fermata => explainFermata,
    Marking.ritardando => explainRitardando,
    Marking.accelerando => explainAccelerando,
    Marking.aTempo => explainATempo,
    Marking.dolce => explainDolce,
    Marking.legato => explainLegato,
    Marking.espressivo => explainEspressivo,
    Marking.cantabile => explainCantabile,
  };
}

/// Temps en chiffres : 3, ½, 1½, 2¾. Les huitièmes viennent des doubles
/// croches pointées.
String formatBeats(Fraction beats) {
  final value = beats.reduced;
  final whole = value.numerator ~/ value.denominator;
  final rest = Fraction(value.numerator % value.denominator, value.denominator);
  if (rest.numerator == 0) return '$whole';
  final glyph = switch ((rest.reduced.numerator, rest.reduced.denominator)) {
    (1, 4) => '¼',
    (1, 2) => '½',
    (3, 4) => '¾',
    (1, 8) => '⅛',
    (3, 8) => '⅜',
    (5, 8) => '⅝',
    (7, 8) => '⅞',
    (final n, final d) => '$n/$d',
  };
  return whole == 0 ? glyph : '$whole$glyph';
}

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
