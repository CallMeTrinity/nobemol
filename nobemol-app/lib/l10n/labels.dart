import 'package:flutter/material.dart' show ThemeMode;
import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/note_name.dart';
import 'package:nobemol/reading/start_level.dart';
import 'package:nobemol/settings/settings.dart';

/// Libellés des types du modèle et de l'appli.
extension Labels on AppLocalizations {
  /// Nom de note affiché : le modèle est en lettres, l'affichage en do-ré-mi
  /// ou en lettres capitales selon le réglage.
  String noteName(DiatonicStep step, {required NoteNaming naming}) =>
      switch (naming) {
        NoteNaming.letters => step.name.toUpperCase(),
        NoteNaming.solfege => _solfege(step),
      };

  String _solfege(DiatonicStep step) => switch (step) {
    DiatonicStep.c => noteC,
    DiatonicStep.d => noteD,
    DiatonicStep.e => noteE,
    DiatonicStep.f => noteF,
    DiatonicStep.g => noteG,
    DiatonicStep.a => noteA,
    DiatonicStep.b => noteB,
  };

  /// Nom de note avec son altération, en toutes lettres : « fa dièse ».
  /// Les polices de l'interface n'ont pas les signes ♯ et ♭.
  String noteFullName(NoteName name, {required NoteNaming naming}) {
    final step = noteName(name.step, naming: naming);
    return switch (name.accidental) {
      Accidental.sharp => noteSharp(step),
      Accidental.flat => noteFlat(step),
      _ => step,
    };
  }

  /// Libellé d'une réponse : un nom de note, une durée ou le sens d'un
  /// signe.
  String answerLabel(Enum answer, {required NoteNaming naming}) =>
      switch (answer) {
        DiatonicStep() => noteName(answer, naming: naming),
        NoteName() => noteFullName(answer, naming: naming),
        Beats() => beatsLabel(answer),
        Marking() => markingLabel(answer),
        _ => throw ArgumentError.value(answer, 'answer', 'réponse inconnue'),
      };

  /// Durée en temps. Des nombres : rien à traduire.
  String beatsLabel(Beats beats) => switch (beats) {
    Beats.quarter => '¼',
    Beats.half => '½',
    Beats.threeQuarters => '¾',
    Beats.one => '1',
    Beats.oneAndHalf => '1½',
    Beats.two => '2',
    Beats.three => '3',
    Beats.four => '4',
  };

  /// Sens d'un signe ou d'un terme, en français.
  String markingLabel(Marking marking) => switch (marking) {
    Marking.pianississimo => markingPianississimo,
    Marking.pianissimo => markingPianissimo,
    Marking.piano => markingPiano,
    Marking.mezzoPiano => markingMezzoPiano,
    Marking.mezzoForte => markingMezzoForte,
    Marking.forte => markingForte,
    Marking.fortissimo => markingFortissimo,
    Marking.fortississimo => markingFortississimo,
    Marking.crescendo => markingCrescendo,
    Marking.diminuendo => markingDiminuendo,
    Marking.staccato => markingStaccato,
    Marking.tenuto => markingTenuto,
    Marking.accent => markingAccent,
    Marking.fermata => markingFermata,
    Marking.ritardando => markingRitardando,
    Marking.accelerando => markingAccelerando,
    Marking.aTempo => markingATempo,
    Marking.dolce => markingDolce,
    Marking.legato => markingLegato,
    Marking.espressivo => markingEspressivo,
    Marking.cantabile => markingCantabile,
  };

  /// Titre d'une branche de l'arbre de compétences (début de l'identifiant
  /// des compétences). Une branche sans libellé garde son identifiant.
  String branchTitle(String branch) => switch (branch) {
    'note-reading' => branchNoteReading,
    'rhythm' => branchRhythm,
    'terms' => branchTerms,
    'symbols' => branchSymbols,
    _ => branch,
  };

  String levelTitle(StartLevel level) => switch (level) {
    StartLevel.beginner => levelBeginnerTitle,
    StartLevel.knowsTreble => levelKnowsTrebleTitle,
    StartLevel.readsBoth => levelReadsBothTitle,
    StartLevel.fluent => levelFluentTitle,
  };

  String levelDescription(StartLevel level) => switch (level) {
    StartLevel.beginner => levelBeginnerDescription,
    StartLevel.knowsTreble => levelKnowsTrebleDescription,
    StartLevel.readsBoth => levelReadsBothDescription,
    StartLevel.fluent => levelFluentDescription,
  };

  String goalTitle(DailyGoal goal) => switch (goal) {
    DailyGoal.five => goalFive,
    DailyGoal.ten => goalTen,
    DailyGoal.fifteen => goalFifteen,
    DailyGoal.twenty => goalTwenty,
  };

  String namingLabel(NoteNaming naming) => switch (naming) {
    NoteNaming.solfege => namingSolfege,
    NoteNaming.letters => namingLetters,
  };

  String themeLabel(ThemeMode theme) => switch (theme) {
    ThemeMode.system => themeSystem,
    ThemeMode.light => themeLight,
    ThemeMode.dark => themeDark,
  };
}
