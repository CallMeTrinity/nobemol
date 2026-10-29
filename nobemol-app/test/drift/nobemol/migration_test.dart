// Migrations de la base, une par version de schéma. Les schémas figés
// (drift_schemas/) et generated/ viennent de
// `dart run drift_dev make-migrations` : voir doc/database.md.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nobemol/progress/database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

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
    await db.close();
  });
}
