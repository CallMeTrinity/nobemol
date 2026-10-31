import 'package:drift/drift.dart';

import 'package:nobemol/progress/database.steps.dart';

part 'database.g.dart';

/// Session d'exercice terminée. Une session abandonnée n'est pas gardée.
@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Leçon jouée, `null` hors leçon : lecture libre (jusqu'à la v2),
  /// révision, arcade.
  TextColumn get lessonId => text().nullable()();

  /// Partie d'arcade : mode et clé (`chrono:treble`, `survival`), `null`
  /// hors arcade. Voir `lib/arcade/arcade.dart`.
  TextColumn get arcade => text().nullable()();

  /// Score d'une partie d'arcade, `null` hors arcade.
  IntColumn get score => integer().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime()();
  IntColumn get questions => integer()();
  IntColumn get correct => integer()();
  IntColumn get xp => integer()();
  IntColumn get bestCombo => integer()();
}

/// Réponse donnée pendant une session, dans l'ordre des questions.
@DataClassName('AnswerRow')
class Answers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Bonne réponse et réponse donnée : nom d'un `DiatonicStep`, d'un
  /// `Beats` ou d'un `Marking`. Juste si les deux sont égales.
  TextColumn get expected => text()();
  TextColumn get given => text()();

  /// Temps de réponse, de l'affichage de la question au choix.
  IntColumn get elapsedMs => integer()();
  IntColumn get xp => integer()();

  /// Carte de révision de la question (voir `lib/review/card.dart`).
  /// `null` avant la v2 : ces réponses ne créent pas de carte.
  TextColumn get card => text().nullable()();
}

/// Lecture de la théorie d'une leçon.
@DataClassName('TheoryRow')
class Theory extends Table {
  TextColumn get lessonId => text()();

  /// Dernière page ouverte, à partir de 0.
  IntColumn get page => integer()();

  /// Vrai une fois la dernière page passée (« S'entraîner »).
  BoolColumn get read => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {lessonId};
}

/// Compétence maîtrisée, une fois pour toutes : ajouter une leçon à une
/// compétence baisse sa maîtrise calculée, mais ne reverrouille pas ce qui
/// en dépend.
@DataClassName('MasteredSkillRow')
class MasteredSkills extends Table {
  TextColumn get skillId => text()();

  /// Première fois que la maîtrise a atteint le seuil.
  DateTimeColumn get masteredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {skillId};
}

/// Succès débloqué, une fois pour toutes, comme une compétence maîtrisée :
/// les succès sont définis dans `assets/achievements.yaml`.
@DataClassName('AchievementRow')
class Achievements extends Table {
  TextColumn get achievementId => text()();

  /// Fin de la session qui l'a débloqué.
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {achievementId};
}

/// Progression de l'élève, sur le téléphone.
///
/// La bêta est installée : chaque changement de schéma passe par une
/// version et une migration testée (voir `doc/database.md`).
@DriftDatabase(
  tables: [Sessions, Answers, Theory, MasteredSkills, Achievements],
)
class NobemolDatabase extends _$NobemolDatabase {
  NobemolDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.addColumn(schema.answers, schema.answers.card);
      },
      from2To3: (m, schema) async {
        await m.addColumn(schema.sessions, schema.sessions.arcade);
        await m.addColumn(schema.sessions, schema.sessions.score);
      },
      from3To4: (m, schema) async {
        await m.createTable(schema.achievements);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
