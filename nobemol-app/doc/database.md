# Base de données

La progression vit dans une base SQLite sur le téléphone, via [Drift](https://drift.simonbinder.eu). Les réglages iront dans `shared_preferences` (étape 9).

La bêta est installée : **une mise à jour de l'APK ne doit jamais perdre la progression**. Tout changement de schéma passe donc par une nouvelle version et une migration testée.

## Fichiers

| Fichier | Rôle |
|---|---|
| `lib/progress/database.dart` | Tables et version du schéma (`schemaVersion`) |
| `lib/progress/database.g.dart` | Généré par `build_runner`, committé |
| `lib/progress/database.steps.dart` | Généré par `make-migrations` : une étape par version |
| `drift_schemas/nobemol/drift_schema_vN.json` | Schéma figé de chaque version, committé |
| `test/drift/nobemol/generated/` | Schémas figés en Dart, pour les tests |
| `test/drift/nobemol/migration_test.dart` | Tests de migration, écrits à la main |
| `lib/progress/progress_provider.dart` | Lecture et écriture (`ProgressStore`) |
| `build.yaml` | Options de Drift : dates en texte ISO 8601 |
| `web/sqlite3.wasm`, `web/drift_worker.js` | SQLite pour la cible web, depuis la release GitHub de Drift (même version que le `pubspec.lock`) |

## Schéma v1

- `sessions` : une session d'exercice **terminée** (une session quittée avant la fin n'est pas gardée). Leçon (`null` hors leçon : lecture libre jusqu'à la v2, révision, arcade), début, fin, questions, bonnes réponses, XP, meilleur combo.
- `answers` : les réponses d'une session, dans l'ordre. Bonne réponse et réponse donnée (nom de l'enum : `c`, `half`, `piano`), temps de réponse, XP.
- `theory` : la dernière page ouverte de chaque leçon, et si la théorie est lue.
- `mastered_skills` : les compétences maîtrisées, avec la date de la première fois.

## Schéma v2

- `answers.card` : la carte de révision de la question (`note:treble:fSharp5`, `duration:half+quarter`, `marking:above:rit.`). Format dans `lib/review/card.dart` : il est stocké, ne jamais le changer sans migration. `null` pour les réponses de la v1.

## Schéma v3

- `sessions.arcade` : la partie d'arcade, mode et clé (`chrono:treble`, `endless:bass`, `survival`, et l'entraînement `practice:treble`, sans record affiché). Format dans `lib/arcade/arcade.dart` (`recordKey`). `null` hors arcade.
- `sessions.score` : son score, points en chrono, notes justes ailleurs. `null` hors arcade.
- `answers.given` peut valoir `timeout` : le temps de la note est écoulé (arcade). C'est une erreur.

## Schéma v4

- `achievements` : les succès débloqués, avec la date de la première fois (fin de la session qui les a débloqués). Les succès sont définis dans `assets/achievements.yaml` ([doc/achievements.md](achievements.md)) : un id retiré du fichier reste en base, ignoré.

Les records ne sont pas stockés : chacun est le meilleur score de ses parties.

Les cartes ne sont pas stockées : leur boîte et leur date de retour se rejouent depuis les réponses, dans l'ordre (`lib/review/leitner.dart`).

Le **pourcentage** de maîtrise n'est pas stocké : il se calcule depuis les meilleurs scores des sessions (`lib/progress/course.dart`), et suit donc le contenu sans migration. Seul le **fait** d'avoir maîtrisé une compétence est gardé : ajouter une leçon baisse le pourcentage, mais ne reverrouille pas ce qui en dépend.

## Changer le schéma

1. Modifier les tables dans `database.dart`, et augmenter `schemaVersion`.
2. Générer, depuis `nobemol-app/` :
   ```sh
   dart run build_runner build
   dart run drift_dev make-migrations
   ```
   Le schéma de la nouvelle version est figé dans `drift_schemas/`, et `database.steps.dart` gagne une étape `fromNToM`.
3. Écrire la migration dans `database.dart`, avec l'étape générée :
   ```dart
   onUpgrade: stepByStep(
     from1To2: (m, schema) async {
       await m.addColumn(schema.answers, schema.answers.clef);
     },
   ),
   ```
4. Dans `migration_test.dart`, ajouter un test « données de la vN » : il insère des lignes avec le schéma figé de la version précédente, migre, puis les relit avec le code.
5. `flutter test test/drift`.

Les tests échouent si l'une de ces étapes manque :

- `schemaVersion` augmentée sans `make-migrations` : « chaque version de schéma est figée ».
- Une table modifiée sans nouvelle version : « le schéma du code est celui de la dernière version figée ».
- Une migration qui ne produit pas le schéma attendu : « migrations, de N à M ».

**Ne jamais modifier un schéma figé** (`drift_schema_vN.json`) : il décrit ce qui est installé sur les téléphones.

## Sauvegarde

L'onglet Profil exporte toute la base et les réglages dans un fichier JSON (`nobemol-2026-10-31.json`), partagé par la feuille de partage d'Android. L'import, depuis le Profil ou « J'ai déjà une sauvegarde » au démarrage, **remplace** la base et les réglages, d'un seul bloc : un fichier refusé ne change rien. Code dans `lib/backup/`.

```json
{
  "app": "nobemol",
  "format": 1,
  "exportedAt": "2026-10-31T17:00:00.000Z",
  "settings": { "naming": "solfege", "start": "beginner", "keyLabels": true, "goal": "five", "haptics": true, "theme": "system", "updateCheck": true },
  "progress": {
    "sessions": [
      { "lessonId": "treble-clef", "arcade": null, "score": null, "startedAt": "…", "finishedAt": "…",
        "questions": 20, "correct": 18, "xp": 255, "bestCombo": 12,
        "answers": [{ "expected": "c", "given": "c", "elapsedMs": 1200, "xp": 10, "card": "note:treble:c5" }] }
    ],
    "theory": [{ "lessonId": "bass-clef", "page": 2, "read": false, "updatedAt": "…" }],
    "mastered": [{ "skillId": "note-reading.treble", "masteredAt": "…" }],
    "achievements": [{ "id": "first-lesson", "unlockedAt": "…" }]
  }
}
```

- Les **identifiants** de la base ne sont pas gardés : les réponses sont rangées dans leur session, dans l'ordre. La révision rejoue ce journal dans cet ordre.
- Dates en **UTC**, relues en heure locale.
- Un réglage absent ou inconnu garde la valeur du téléphone. Le démarrage est marqué passé.

Le fichier vit hors du téléphone (Drive, mail) et peut être réimporté des mois plus tard. Quand le schéma change :

1. Le fichier suit la nouvelle base : ajouter le champ à `encode()` et à la lecture.
2. Si un fichier d'avant ne se lit plus tel quel (champ obligatoire ajouté, champ renommé), augmenter `backupFormat` et lire l'ancien format **en plus** du nouveau, avec une valeur par défaut. Un champ facultatif (`null` pour les anciennes lignes, comme `answers.card`) ne demande rien.
3. Un fichier d'un format plus récent que l'appli est refusé : « mets l'appli à jour ».

## Dates

Stockées en texte ISO 8601 avec le décalage horaire (`2026-10-29T18:00:00.000+01:00`). Une date sans décalage est lue comme de l'UTC : en écrire une à la main (dans un test) demande le décalage.
