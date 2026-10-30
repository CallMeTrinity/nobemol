import 'package:nobemol/reading/note_reading.dart';

/// Point de départ choisi à la main, en attendant le test de positionnement.
enum StartLevel {
  beginner(NoteReadingParams(staff: StaffSetup.treble)),
  knowsTreble(
    NoteReadingParams(staff: StaffSetup.bass),
    acquired: {'note-reading.treble'},
  ),
  readsBoth(
    NoteReadingParams(staff: StaffSetup.grand, ledgerLines: 1),
    acquired: {
      'note-reading.treble',
      'note-reading.bass',
      'note-reading.ledger-lines',
      'note-reading.grand',
    },
  ),
  fluent(
    NoteReadingParams(
      staff: StaffSetup.grand,
      ledgerLines: 2,
      accidentals: true,
    ),
    acquired: {
      'note-reading.treble',
      'note-reading.bass',
      'note-reading.ledger-lines',
      'note-reading.grand',
      'note-reading.accidentals',
    },
  );

  const StartLevel(this.params, {this.acquired = const {}});

  /// Lecture libre de ce niveau.
  final NoteReadingParams params;

  /// Compétences que l'élève dit déjà savoir : elles comptent comme
  /// prérequis acquis, sans être maîtrisées. Leurs propres prérequis en
  /// font partie (vérifié en test).
  final Set<String> acquired;
}
