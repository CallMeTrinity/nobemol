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

- `sessions` : une session d'exercice **terminée** (une session quittée avant la fin n'est pas gardée). Leçon (`null` en lecture libre), début, fin, questions, bonnes réponses, XP, meilleur combo.
- `answers` : les réponses d'une session, dans l'ordre. Bonne réponse et réponse donnée (nom de l'enum : `c`, `half`, `piano`), temps de réponse, XP.
- `theory` : la dernière page ouverte de chaque leçon, et si la théorie est lue.
- `mastered_skills` : les compétences maîtrisées, avec la date de la première fois.

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

## Dates

Stockées en texte ISO 8601 avec le décalage horaire (`2026-10-29T18:00:00.000+01:00`). Une date sans décalage est lue comme de l'UTC : en écrire une à la main (dans un test) demande le décalage.
