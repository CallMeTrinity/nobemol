// Migrations de la base, une par version de schéma. Les schémas figés
// (drift_schemas/) et generated/ viennent de
// `dart run drift_dev make-migrations` : voir doc/database.md.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/progress/database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('chaque version de schéma est figée', () {
    // Sinon : schemaVersion augmentée sans make-migrations.
    expect(
      GeneratedHelper.versions.last,
      NobemolDatabase(NativeDatabase.memory()).schemaVersion,
    );
  });

  test('le schéma du code est celui de la dernière version figée', () async {
    // Échoue si une table change sans nouvelle version de schéma.
    final schema = await verifier.schemaAt(GeneratedHelper.versions.last);
    final db = NobemolDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, GeneratedHelper.versions.last);
    await db.close();
  });

  group('migrations', () {
    const versions = GeneratedHelper.versions;
    for (final (i, from) in versions.indexed) {
      for (final to in versions.skip(i + 1)) {
        test('de $from à $to', () async {
          final schema = await verifier.schemaAt(from);
          final db = NobemolDatabase(schema.newConnection());
          await verifier.migrateAndValidate(db, to);
          await db.close();
        });
      }
    }
  });

  // Les données d'une version doivent survivre jusqu'à la dernière. Un test
  // par version : il insère avec le schéma figé, puis lit avec le code.
  test('données de la v1', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old.customStatement(
      "INSERT INTO sessions (lesson_id, started_at, finished_at, questions, "
      "correct, xp, best_combo) VALUES ('treble-clef', "
      "'2026-10-29T18:00:00.000+01:00', '2026-10-29T18:01:00.000+01:00', 20, 18, 195, 9)",
    );
    await old.customStatement(
      "INSERT INTO answers (session_id, expected, given, elapsed_ms, xp) "
      "VALUES (1, 'c', 'c', 1200, 10)",
    );
    await old.customStatement(
      "INSERT INTO theory (lesson_id, page, read, updated_at) "
      "VALUES ('bass-clef', 2, 0, '2026-10-29T17:00:00.000+01:00')",
    );
    await old.customStatement(
      "INSERT INTO mastered_skills (skill_id, mastered_at) "
      "VALUES ('note-reading.treble', '2026-10-29T18:01:00.000+01:00')",
    );
    await old.close();

    final db = NobemolDatabase(schema.newConnection());
    final session = await db.select(db.sessions).getSingle();
    expect(session.lessonId, 'treble-clef');
    expect(session.xp, 195);
    // Drift écrit les dates locales avec leur décalage.
    expect(session.finishedAt.toUtc(), DateTime.utc(2026, 10, 29, 17, 1));
    expect((await db.select(db.answers).getSingle()).expected, 'c');
    expect((await db.select(db.theory).getSingle()).page, 2);
    expect(
      (await db.select(db.masteredSkills).getSingle()).skillId,
      'note-reading.treble',
    );
    // v2 : les réponses de la v1 n'ont pas de carte.
    expect((await db.select(db.answers).getSingle()).card, isNull);
    await db.close();
  });

  test('données de la v2', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old.customStatement(
      "INSERT INTO sessions (lesson_id, started_at, finished_at, questions, "
      "correct, xp, best_combo) VALUES (NULL, "
      "'2026-10-29T18:00:00.000+01:00', '2026-10-29T18:01:00.000+01:00', 1, 0, 0, 0)",
    );
    await old.customStatement(
      "INSERT INTO answers (session_id, expected, given, elapsed_ms, xp, card) "
      "VALUES (1, 'fSharp', 'g', 1200, 0, 'note:treble:fSharp5')",
    );
    await old.close();

    final db = NobemolDatabase(schema.newConnection());
    expect(
      (await db.select(db.answers).getSingle()).card,
      'note:treble:fSharp5',
    );
    // v3 : une session d'avant n'est pas une partie d'arcade.
    final session = await db.select(db.sessions).getSingle();
    expect(session.arcade, isNull);
    expect(session.score, isNull);
    await db.close();
  });

  test('données de la v3', () async {
    final schema = await verifier.schemaAt(3);
    final old = v3.DatabaseAtV3(schema.newConnection());
    await old.customStatement(
      "INSERT INTO sessions (lesson_id, started_at, finished_at, questions, "
      "correct, xp, best_combo, arcade, score) VALUES (NULL, "
      "'2026-10-29T18:00:00.000+01:00', '2026-10-29T18:01:00.000+01:00', "
      "24, 22, 66, 15, 'chrono:treble', 2150)",
    );
    await old.close();

    final db = NobemolDatabase(schema.newConnection());
    final session = await db.select(db.sessions).getSingle();
    expect(session.arcade, 'chrono:treble');
    expect(session.score, 2150);
    await db.close();
  });
}
