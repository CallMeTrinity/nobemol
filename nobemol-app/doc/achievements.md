# Succès

Les succès de l'onglet Profil sont **des données**, pas du code : `assets/achievements.yaml`, dans l'ordre d'affichage. Le validateur les vérifie avec le reste du contenu :

```sh
dart run tool/validate_content.dart   # depuis nobemol-app/
```

## Exemple

```yaml
- id: ten-lessons                # minuscules, chiffres et tirets
  title: Dix leçons
  description: Termine 10 leçons différentes.   # la condition, dite à l'élève
  when: { lessons: 10 }          # une seule condition
```

## Conditions

| Clé | Compte | Valeur |
|---|---|---|
| `lessons` | leçons différentes terminées | nombre |
| `perfect` | sessions de leçon sans erreur (la même leçon compte plusieurs fois) | nombre |
| `answers` | bonnes réponses, partout (leçons, révision, arcade) | nombre |
| `combo` | meilleur combo d'une session | nombre |
| `streak` | plus longue série de jours de pratique d'affilée | nombre |
| `level` | niveau atteint | nombre |
| `mastered` | compétences maîtrisées | nombre |
| `branch` | toutes les compétences de la branche qui ont des leçons, maîtrisées | branche (`note-reading`) |
| `chrono` | meilleur score en chrono, toutes clés (points) | nombre |
| `endless` | meilleur score en sans fin, toutes clés (notes) | nombre |
| `survival` | meilleur score en survie (notes) | nombre |
| `acquired` | cartes de révision dans la dernière boîte | nombre |

Le validateur refuse une condition inconnue, deux conditions, un nombre inférieur à 1, et une branche sans leçon (elle serait maîtrisée d'office).

## Déblocage

- Les comptes sont **calculés** depuis la progression (`lib/achievements/achievements.dart`), comme la maîtrise.
- À la **fin d'une session** (leçon, révision, partie d'arcade), chaque succès atteint est enregistré avec sa date (table `achievements`, [doc/database.md](database.md)). Il le reste, même si sa condition change ensuite.
- Il s'affiche sur l'écran « palier » après une leçon ou une révision, et sur l'écran de fin d'une partie d'arcade.
- Un succès atteint mais pas encore enregistré (progression d'avant la v4) s'affiche débloqué, sans date, jusqu'à la session suivante qui l'enregistre.

## Changer un succès

- **Ajouter** : il se débloque à la prochaine session de l'élève qui l'a atteint.
- **Retirer** : son id reste en base, ignoré. Ne jamais réutiliser l'id d'un succès retiré.
- **Durcir** une condition ne reverrouille rien chez l'élève qui l'a déjà débloqué.
