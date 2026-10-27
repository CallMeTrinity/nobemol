import 'package:nobemol/reading/note_reading.dart';

/// Point de départ choisi à la main, en attendant le test de positionnement.
enum StartLevel {
  beginner(NoteReadingParams(staff: StaffSetup.treble)),
  knowsTreble(NoteReadingParams(staff: StaffSetup.bass)),
  readsBoth(NoteReadingParams(staff: StaffSetup.grand, ledgerLines: 1)),
  fluent(
    NoteReadingParams(
      staff: StaffSetup.grand,
      ledgerLines: 2,
      accidentals: true,
    ),
  );

  const StartLevel(this.params);

  final NoteReadingParams params;
}
