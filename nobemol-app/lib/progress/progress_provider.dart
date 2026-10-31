import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nobemol/clock.dart';
import 'package:nobemol/lessons/content_provider.dart';
import 'package:nobemol/progress/course.dart';
import 'package:nobemol/progress/database.dart';
import 'package:nobemol/progress/progress.dart';
import 'package:nobemol/progress/xp.dart';
import 'package:nobemol/review/leitner.dart';
import 'package:nobemol/lessons/skill_tree.dart';
import 'package:nobemol/settings/settings.dart';

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
    final answers = _db.answers;
    final cardAnswers =
        await (_db.select(answers).join([
                innerJoin(
                  _db.sessions,
                  _db.sessions.id.equalsExp(answers.sessionId),
                ),
              ])
              ..where(answers.card.isNotNull())
              ..orderBy([
                OrderingTerm(expression: _db.sessions.id),
                OrderingTerm(expression: answers.id),
              ]))
            .get();
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
      cardAnswers: cardAnswers.map((row) {
        final answer = row.readTable(answers);
        return CardAnswer(
          card: answer.card!,
          correct: answer.expected == answer.given,
          answeredAt: row.readTable(_db.sessions).finishedAt,
        );
      }).toList(),
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
            card: Value(answer.card),
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

/// Ce qu'une session a changé : de l'XP, peut-être un niveau, des
/// compétences maîtrisées et d'autres débloquées.
class SessionOutcome {
  const SessionOutcome({
    required this.xpBefore,
    required this.xpAfter,
    this.mastered = const [],
    this.unlocked = const [],
  });

  final int xpBefore;
  final int xpAfter;

  /// Compétences maîtrisées par cette session.
  final List<Skill> mastered;

  /// Compétences débloquées par cette session, qui ont des leçons.
  final List<Skill> unlocked;

  Level get level => Level.of(xpAfter);
  bool get levelUp => level.number > Level.of(xpBefore).number;

  /// Un palier à fêter : un niveau, ou une compétence.
  bool get milestone => levelUp || mastered.isNotEmpty;
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

  /// Enregistre une session terminée, et dit ce qu'elle a changé.
  Future<SessionOutcome> recordSession({
    required String? lessonId,
    required DateTime startedAt,
    required DateTime finishedAt,
    required List<AnswerRecord> answers,
    required int bestCombo,
  }) async {
    final content = ref.read(contentProvider);
    final acquired = ref.read(settingsProvider).start.acquired;
    final before = Course(content, state, acquired: acquired);
    final xpBefore = state.xp;
    await _store.recordSession(
      lessonId: lessonId,
      startedAt: startedAt,
      finishedAt: finishedAt,
      answers: answers,
      bestCombo: bestCombo,
    );
    var progress = await _store.load();
    final mastered = Course(
      content,
      progress,
      acquired: acquired,
    ).newlyMastered.toList();
    if (mastered.isNotEmpty) {
      await _store.saveMastered(mastered, finishedAt);
      progress = await _store.load();
    }
    state = progress;

    final after = Course(content, progress, acquired: acquired);
    return SessionOutcome(
      xpBefore: xpBefore,
      xpAfter: progress.xp,
      mastered: [for (final id in mastered) after.skill(id)!.skill],
      unlocked: [
        for (final skills in after.branches.values)
          for (final skill in skills)
            if (skill.state != SkillState.locked &&
                before.skill(skill.skill.id)!.state == SkillState.locked)
              skill.skill,
      ],
    );
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
  (ref) => Course(
    ref.watch(contentProvider),
    ref.watch(progressProvider),
    acquired: ref.watch(settingsProvider.select((s) => s.start.acquired)),
  ),
);
