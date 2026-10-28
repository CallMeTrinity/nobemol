# Écrire une leçon

Une leçon = **un fichier YAML** dans `assets/lessons/`. Elle enchaîne des pages de théorie, puis un exercice de lecture. La musique s'écrit en ABC, dans le [sous-ensemble du moteur](../packages/notation/doc/abc.md).

Après chaque modification :

```sh
dart run tool/validate_content.dart   # depuis nobemol-app/
```

La CI lance la même commande : une leçon invalide fait échouer le build. Les erreurs sont au format `fichier:ligne:colonne: message`, ABC compris (la position pointe dans le fichier YAML).

## Exemple

```yaml
id: treble-clef                  # = nom du fichier, sans .yaml
title: La clé de sol
skills: [note-reading.treble]    # au moins une, définies dans assets/skills.yaml
level: 1                         # de 1 à 10
theory:                          # au moins une page
  - text: >-
      La clé de sol s'enroule autour de la 2e ligne.
      La note posée sur cette ligne est un sol.
    abc: |                       # facultatif
      X:1
      L:1/1                      # obligatoire dès qu'il y a une note
      K:C
      G
exercise:
  type: note-reading
  staff: treble                  # treble, bass, alto, tenor ou grand
  ledger-lines: 0                # facultatif, de 0 à 4 (défaut 0)
  accidentals: false             # facultatif (défaut false)
```

## Champs

| Champ | Contenu |
|---|---|
| `id` | Minuscules, chiffres et tirets. **Identique au nom du fichier** : l'unicité est garantie par le système de fichiers. |
| `title` | Titre affiché dans l'appli. |
| `skills` | Compétences travaillées, sans doublon. Chacune doit exister dans `assets/skills.yaml`. |
| `level` | Niveau de 1 à 10. |
| `theory` | Pages de théorie, dans l'ordre. `text` obligatoire, `abc` facultatif. |
| `exercise` | Exercice qui suit la théorie. |

Tout champ inconnu est une erreur : une faute de frappe (`ledger_lines`) ne passe pas en silence.

### Exercices

| `type` | Champs | Exercice |
|---|---|---|
| `note-reading` | `staff`, `ledger-lines`, `accidentals` | Lecture de notes paramétrique, la même que les points de départ de l'accueil. 20 notes tirées au hasard. |
| `identify-note` | `abc`, `targets` | Une phrase écrite en ABC. Chaque cible est colorée à son tour, et il faut la nommer. Une question par cible, dans l'ordre. |

### `identify-note`

```yaml
exercise:
  type: identify-note
  abc: |
    X:1
    %%score {RH LH}
    M:3/4
    L:1/4
    K:G
    V:RH
    B2 c | d2 c |]
    V:LH clef=bass
    G, D, B, | G,2 D, |]
  targets:
    - { staff: RH, measure: 1, event: 2 }   # do, 2e note de la mesure 1
    - { staff: LH, measure: 2, event: 1 }
```

- `staff` : identifiant de la voix (`V:`). Facultatif s'il n'y a qu'une portée, obligatoire sinon.
- `measure`, `event` : comptés **à partir de 1**. `event` compte les notes de la mesure, de gauche à droite.
- Le chargement vérifie que chaque cible existe (portée, mesure, note) et qu'elle n'est pas en double. La CI échoue sinon.
- La réponse est le nom de la note, sans l'altération : un fa dièse par l'armure se nomme fa.
- Les cibles peuvent sauter des notes et suivre n'importe quel ordre : la note demandée est colorée.

## Conventions

- **Pièges YAML** : `>-` replie les lignes en un seul paragraphe, `|` garde les retours à la ligne (obligatoire pour l'ABC). Un texte qui contient `: ` se met entre guillemets.
- **ABC** : pas de ligne vide dans un bloc `abc` (en ABC, elle termine le morceau). `L:` est obligatoire dès qu'il y a une note : `L:1/1` pour des rondes sans rythme.
- **Phrases** : 3 ou 4 mesures au plus. Elles s'affichent sur une seule ligne, à la largeur de l'écran : au-delà, les notes deviennent trop petites.
- **Noms de notes** : en do-ré-mi dans les textes. L'ABC reste en lettres.
- **Cibles** (`identify-note`) : `measure` et `event` comptent **à partir de 1**, comme on compte les mesures en musique (« mesure 1, 2e note »). La conversion en index du code se fait au chargement.

## Ordre des leçons

L'appli range les leçons d'après `assets/skills.yaml` : d'abord par la compétence la plus avancée de la leçon (position dans le fichier), puis par niveau, puis par `id`.

Dans `assets/skills.yaml`, un prérequis (`requires`) est toujours déclaré plus haut que la compétence qui en dépend. L'ordre du fichier est donc un ordre d'apprentissage, et il ne peut pas y avoir de cycle.
