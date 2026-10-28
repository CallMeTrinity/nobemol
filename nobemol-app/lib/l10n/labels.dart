import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
import 'package:nobemol/reading/beats.dart';
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

  /// Libellé d'un bouton de réponse : un nom de note ou une durée.
  String answerLabel(Enum answer) => switch (answer) {
    DiatonicStep() => noteName(answer),
    Beats() => beatsLabel(answer),
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
