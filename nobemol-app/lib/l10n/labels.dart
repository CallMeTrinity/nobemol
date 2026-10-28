import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/reading/beats.dart';
import 'package:nobemol/reading/markings.dart';
import 'package:nobemol/reading/start_level.dart';

/// Libellés des types du modèle et de l'appli.
extension Labels on AppLocalizations {
  /// Nom de note affiché : le modèle est en lettres, l'affichage en do-ré-mi.
  String noteName(DiatonicStep step) => switch (step) {
    DiatonicStep.c => noteC,
    DiatonicStep.d => noteD,
    DiatonicStep.e => noteE,
    DiatonicStep.f => noteF,
    DiatonicStep.g => noteG,
    DiatonicStep.a => noteA,
    DiatonicStep.b => noteB,
  };

  /// Libellé d'un bouton de réponse : un nom de note, une durée ou le sens
  /// d'un signe.
  String answerLabel(Enum answer) => switch (answer) {
    DiatonicStep() => noteName(answer),
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
}
