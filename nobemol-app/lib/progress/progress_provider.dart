import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/progress/course.dart';
import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/progress.dart';

/// Base du téléphone. Sur le web (cible de dev), dans le navigateur :
/// `web/sqlite3.wasm` et `web/drift_worker.js` viennent de la release de
/// Drift de la version du `pubspec.lock`.
QueryExecutor openDatabase() => driftDatabase(
  name: 'nobemol',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
);

/// Lecture et écriture de la progression dans la base.
class ProgressStore {
  ProgressStore(this._db);

  final NobemolDatabase _db;

  Future<Progress> load() async {
    final sessions = await (_db.select(
      _db.sessions,
    )..orderBy([(session) => OrderingTerm(expression: session.id)])).get();
    final theory = await _db.select(_db.theory).get();
    final mastered = await _db.select(_db.masteredSkills).get();
    return Progress(
      sessions: [
        for (final row in sessions)
          SessionSummary(
            lessonId: row.lessonId,
            finishedAt: row.finishedAt,
            questions: row.questions,
            correct: row.correct,
            xp: row.xp,
          ),
      ],
      theory: {
        for (final row in theory)
          row.lessonId: TheoryProgress(
            page: row.page,
            read: row.read,
            updatedAt: row.updatedAt,
          ),
      },
      mastered: {for (final row in mastered) row.skillId},
    );
  }

  /// Enregistre une session terminée et ses réponses, d'un seul bloc.
  Future<void> recordSession({
    required String? lessonId,
    required DateTime startedAt,
    required DateTime finishedAt,
    required List<AnswerRecord> answers,
    required int bestCombo,
  }) => _db.transaction(() async {
    final id = await _db
        .into(_db.sessions)
        .insert(
          SessionsCompanion.insert(
            lessonId: Value(lessonId),
            startedAt: startedAt,
            finishedAt: finishedAt,
            questions: answers.length,
            correct: answers.where((answer) => answer.correct).length,
            xp: answers.fold(0, (sum, answer) => sum + answer.xp),
            bestCombo: bestCombo,
          ),
        );
    await _db.batch(
      (batch) => batch.insertAll(_db.answers, [
        for (final answer in answers)
          AnswersCompanion.insert(
            sessionId: id,
            expected: answer.expected.name,
            given: answer.given.name,
            elapsedMs: answer.elapsed.inMilliseconds,
            xp: answer.xp,
          ),
      ]),
    );
  });

  /// Enregistre des compétences maîtrisées. Une compétence déjà
  /// enregistrée garde sa date.
  Future<void> saveMastered(Iterable<String> skillIds, DateTime at) =>
      _db.batch(
        (batch) => batch.insertAll(_db.masteredSkills, [
          for (final id in skillIds)
            MasteredSkillsCompanion.insert(skillId: id, masteredAt: at),
        ], mode: InsertMode.insertOrIgnore),
      );

  Future<void> saveTheory(String lessonId, TheoryProgress theory) => _db
      .into(_db.theory)
      .insertOnConflictUpdate(
        TheoryCompanion.insert(
          lessonId: lessonId,
          page: theory.page,
          read: theory.read,
          updatedAt: theory.updatedAt,
        ),
      );
}

/// Progression, lue au démarrage (voir main.dart) puis relue après chaque
/// écriture.
final progressProvider = NotifierProvider<ProgressNotifier, Progress>(
  () => throw UnimplementedError('progressProvider : à surcharger'),
);

class ProgressNotifier extends Notifier<Progress> {
  ProgressNotifier(this._store, this._initial);

  final ProgressStore _store;
  final Progress _initial;

  @override
  Progress build() => _initial;

  Future<void> recordSession({
    required String? lessonId,
    required DateTime startedAt,
    required DateTime finishedAt,
    required List<AnswerRecord> answers,
    required int bestCombo,
  }) async {
    await _store.recordSession(
      lessonId: lessonId,
      startedAt: startedAt,
      finishedAt: finishedAt,
      answers: answers,
      bestCombo: bestCombo,
    );
    final progress = await _store.load();
    final mastered = Course(ref.read(contentProvider), progress).newlyMastered;
    if (mastered.isEmpty) {
      state = progress;
      return;
    }
    await _store.saveMastered(mastered, finishedAt);
    state = await _store.load();
  }

  /// Note la page de théorie ouverte. [finished] : la dernière page est
  /// passée. Une théorie lue le reste, même relue depuis le début.
  Future<void> openPage(
    String lessonId,
    int page, {
    bool finished = false,
  }) async {
    await _store.saveTheory(
      lessonId,
      TheoryProgress(
        page: page,
        read: finished || (state.theory[lessonId]?.read ?? false),
        updatedAt: ref.read(clockProvider)(),
      ),
    );
    state = await _store.load();
  }
}

/// Le parcours, recalculé à chaque changement de progression.
final courseProvider = Provider<Course>(
  (ref) => Course(ref.watch(contentProvider), ref.watch(progressProvider)),
);
