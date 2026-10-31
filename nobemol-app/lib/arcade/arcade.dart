import 'dart:math';

import 'package:nobemol/lessons/content.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/reading/note_reading.dart';

/// Les trois parties d'arcade. Lecture de notes seulement.
enum ArcadeMode {
  /// 60 secondes : le plus de points possible.
  chrono,

  /// Les notes accélèrent, une erreur et c'est fini.
  endless,

  /// Trois erreurs, et de nouvelles clés en route.
  survival,
}

/// Clé d'une partie de chrono ou de sans fin. La survie les mélange.
enum ArcadeClef {
  treble(StaffSetup.treble, 'note-reading.treble'),
  bass(StaffSetup.bass, 'note-reading.bass'),
  grand(StaffSetup.grand, 'note-reading.grand');

  const ArcadeClef(this.staff, this.skill);

  final StaffSetup staff;

  /// Compétence à avoir apprise pour jouer dans cette clé.
  final String skill;
}

/// Durée d'une partie de chrono.
const chronoLength = Duration(seconds: 60);

/// Points d'une note juste en chrono, avant le multiplicateur.
const chronoPoints = 50;

/// Multiplicateur de combo en chrono : ×2 à la 5e note juste d'affilée,
/// ×3 à la 10e, ×4 à partir de la 15e.
int comboMultiplier(int combo) => min(1 + combo ~/ 5, 4);

/// Temps pour lire une note, en sans fin et en survie : 6 s pour la
/// première, 5 % de moins à chaque note juste, jamais moins de 1,5 s.
Duration noteTime(int correct) =>
    Duration(milliseconds: max(6000 * pow(0.95, correct), 1500).round());

/// Vies de la survie.
const survivalLives = 3;

/// Niveau qui débloque la survie.
const survivalLevel = 5;

/// Notes justes avant chaque nouvelle clé, en survie.
const survivalStage = 10;

/// XP d'une note juste. L'arcade enchaîne une note toutes les 2 à 3 s,
/// contre 10 s en leçon avec la correction : 3 XP gardent environ 60 XP
/// par minute, le rythme de l'objectif du jour.
const arcadeXpPerNote = 3;

/// Une partie : son mode, sa clé, et ce que le générateur tire. En survie,
/// une étape par clé apprise, ouvertes une à une.
///
/// Clé de la partie (arcadeProvider) : comparée par valeur.
class ArcadeGame {
  const ArcadeGame({required this.mode, required this.stages, this.clef});

  final ArcadeMode mode;

  /// `null` en survie.
  final ArcadeClef? clef;

  /// Notes à tirer : une seule étape en chrono et en sans fin.
  final List<NoteReadingParams> stages;

  /// Clé de son record.
  String get record => recordKey(mode, clef);

  @override
  bool operator ==(Object other) =>
      other is ArcadeGame &&
      other.mode == mode &&
      other.clef == clef &&
      _sameList(other.stages, stages);

  @override
  int get hashCode => Object.hash(mode, clef, Object.hashAll(stages));
}

/// Ce qui distingue les records : le mode, et la clé hors survie. Gardé
/// en base (`sessions.arcade`) : ne jamais changer ce format sans
/// migration.
String recordKey(ArcadeMode mode, ArcadeClef? clef) =>
    mode == ArcadeMode.survival || clef == null
    ? mode.name
    : '${mode.name}:${clef.name}';

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// L'arcade vue depuis la progression : les clés jouables, les records.
///
/// Une compétence est apprise quand l'exercice d'une de ses leçons a été
/// joué, ou quand le point de départ la donne pour acquise.
class Arcade {
  Arcade(this.content, this.progress, {this.acquired = const {}});

  final Content content;
  final Progress progress;
  final Set<String> acquired;

  bool learned(String skill) =>
      acquired.contains(skill) ||
      content.lessons.any(
        (lesson) =>
            lesson.skills.contains(skill) &&
            progress.bestScores.containsKey(lesson.id),
      );

  /// Clés apprises, dans l'ordre de l'arbre.
  late final List<ArcadeClef> clefs = [
    for (final clef in ArcadeClef.values)
      if (learned(clef.skill)) clef,
  ];

  /// Notes déjà apprises dans [clef] : lignes supplémentaires et
  /// altérations une fois leurs leçons jouées.
  NoteReadingParams params(ArcadeClef clef) => NoteReadingParams(
    staff: clef.staff,
    ledgerLines: learned('note-reading.ledger-lines') ? 1 : 0,
    accidentals: learned('note-reading.accidentals'),
  );

  /// Partie de [mode] dans [clef] (ignorée en survie), `null` si elle ne se
  /// joue pas encore.
  ArcadeGame? game(ArcadeMode mode, ArcadeClef? clef) => switch (mode) {
    ArcadeMode.survival when !survivalUnlocked || clefs.isEmpty => null,
    ArcadeMode.survival => ArcadeGame(
      mode: mode,
      stages: [for (final clef in clefs) params(clef)],
    ),
    _ when clef == null || !clefs.contains(clef) => null,
    _ => ArcadeGame(mode: mode, clef: clef, stages: [params(clef)]),
  };

  /// Record de [mode] dans [clef] (ignorée en survie), `null` sans partie
  /// jouée.
  int? record(ArcadeMode mode, ArcadeClef? clef) =>
      progress.records[recordKey(mode, clef)];

  bool get survivalUnlocked => Level.of(progress.xp).number >= survivalLevel;
}
