import 'package:notation/notation.dart';

import 'package:nobemol/l10n/app_localizations.dart';
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
