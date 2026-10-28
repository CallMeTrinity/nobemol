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
| `identify-duration` | `abc`, `targets` | Même principe, mais il faut donner la durée de la cible en temps : ¼, ½, ¾, 1, 1½, 2, 3 ou 4. |
| `identify-marking` | `abc`, `targets`, `choices` | Même principe, mais la cible est un signe (nuance, soufflet, articulation, terme) : il faut donner son sens parmi les réponses choisies par l'auteur. |

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
- `measure`, `event` : comptés **à partir de 1**. `event` compte les notes **et les silences** de la mesure, de gauche à droite.
- Le chargement vérifie que chaque cible existe (portée, mesure, note) et qu'elle n'est pas en double. La CI échoue sinon.
- La réponse est le nom de la note, sans l'altération : un fa dièse par l'armure se nomme fa.
- Les cibles peuvent sauter des notes et suivre n'importe quel ordre : la note demandée est colorée.
- Une cible est une note, pas un silence (un silence n'a pas de nom).

### `identify-duration`

```yaml
exercise:
  type: identify-duration
  abc: |
    X:1
    M:4/4
    L:1/8
    K:C
    C2 z2 EF G2- | G2 c6 |]
  targets:
    - { measure: 1, event: 2 }   # le soupir : 1 temps
    - { measure: 1, event: 5 }   # sol lié : 1 + 1 = 2 temps
```

Mêmes cibles que `identify-note`, avec ces différences :

- **Chiffrage en x/4 obligatoire** (`M:2/4`, `M:3/4`, `M:4/4`...) : les réponses comptent en noires. En 6/8, « un temps » vaut une noire pointée, et les boutons ne voudraient plus rien dire.
- Une cible peut être un **silence**.
- Une note liée compte **toute sa liaison**, et toute la liaison est colorée. La cible vise la **première** note de la liaison : viser une note d'arrivée est une erreur.
- La durée de chaque cible doit avoir un bouton : ¼, ½, ¾, 1, 1½, 2, 3 ou 4 temps. Une liaison de 2 temps et demi est refusée.

### `identify-marking`

```yaml
exercise:
  type: identify-marking
  abc: |
    X:1
    M:4/4
    L:1/4
    K:C
    !p! C D !crescendo(! E F | G A B !crescendo)! !f! c | "_cresc." c B A G |]
  targets:
    - { measure: 1, event: 1 }   # p : doux
    - { measure: 1, event: 3 }   # le soufflet : de plus en plus fort
    - { measure: 2, event: 4 }   # f : fort (la fin du soufflet ne compte pas)
    - { measure: 3, event: 1 }   # cresc. : de plus en plus fort
  choices: [piano, forte, crescendo, diminuendo]
```

Mêmes cibles que `identify-note`, avec ces différences :

- La cible vise l'événement qui **porte le signe** (voir les décorations dans [doc/abc.md](../packages/notation/doc/abc.md)). Seul le signe est coloré, pas la note. Un soufflet se vise sur sa **première** note.
- L'événement porte **un seul signe**, sinon la question serait ambiguë : `!p! .C` ne peut pas être une cible. Une fin de soufflet ne compte pas : `!crescendo)! !f! c` vise le f.
- Une annotation doit être un **terme connu** (tableau ci-dessous). Les autres textes s'affichent, mais ne peuvent pas être visés.
- `choices` : de **2 à 8 réponses**, sans doublon, affichées dans l'ordre du tableau quel que soit l'ordre d'écriture. La réponse de chaque cible doit y être. Peu de réponses pour une première leçon, plus ensuite.

La réponse est un **sens**, pas une écriture : le soufflet et « cresc. » donnent la même réponse, « rit. » et « rall. » aussi. Le bouton affiche le sens en français.

| `choices` | S'écrit | Bouton |
|---|---|---|
| `pianississimo` | `!ppp!` | extrêmement doux |
| `pianissimo` | `!pp!` | très doux |
| `piano` | `!p!` | doux |
| `mezzo-piano` | `!mp!` | moyennement doux |
| `mezzo-forte` | `!mf!` | moyennement fort |
| `forte` | `!f!` | fort |
| `fortissimo` | `!ff!` | très fort |
| `fortississimo` | `!fff!` | extrêmement fort |
| `crescendo` | `!crescendo(!`, `"_cresc."`, `"_crescendo"` | de plus en plus fort |
| `diminuendo` | `!diminuendo(!`, `"_dim."`, `"_diminuendo"`, `"_decresc."`, `"_decrescendo"` | de moins en moins fort |
| `staccato` | `.` | piqué |
| `tenuto` | `!tenuto!` | tenu |
| `accent` | `!accent!` | accentué |
| `fermata` | `!fermata!` | prolongé à volonté |
| `ritardando` | `"^rit."`, `"^ritard."`, `"^ritardando"`, `"^rall."`, `"^rallentando"` | en ralentissant |
| `accelerando` | `"^accel."`, `"^accelerando"` | en accélérant |
| `a-tempo` | `"^a tempo"` | au mouvement initial |
| `dolce` | `"_dolce"` | avec douceur |
| `legato` | `"_legato"` | lié |
| `espressivo` | `"_espress."`, `"_espressivo"` | expressif |
| `cantabile` | `"_cantabile"` | chantant |

Un terme se reconnaît à son texte, au-dessus (`^`) comme au-dessous (`_`) de la portée. L'usage : les termes de mouvement au-dessus, les autres au-dessous.

## Conventions

- **Pièges YAML** : `>-` replie les lignes en un seul paragraphe, `|` garde les retours à la ligne (obligatoire pour l'ABC). Un texte qui contient `: ` se met entre guillemets.
- **ABC** : pas de ligne vide dans un bloc `abc` (en ABC, elle termine le morceau). `L:` est obligatoire dès qu'il y a une note : `L:1/1` pour des rondes sans rythme.
- **Phrases** : 3 ou 4 mesures au plus. Elles s'affichent sur une seule ligne, à la largeur de l'écran : au-delà, les notes deviennent trop petites. Avec des croches et des doubles croches, viser 2 ou 3 mesures.
- **Ligatures** : en ABC, des croches collées sont ligaturées (`CDEF`), une espace coupe le groupe (`CD EF`). Un groupe par temps, en général.
- **Signes et termes** : le moteur ne décale rien pour éviter un chevauchement horizontal. Deux nuances sur deux noires voisines (`!pp! C !mp! D`) ou deux termes à une noire d'écart se touchent : espacer les signes (blanches, ou un signe par mesure), surtout pour les termes, plus larges.
- **Noms de notes** : en do-ré-mi dans les textes. L'ABC reste en lettres.
- **Cibles** (`identify-note`) : `measure` et `event` comptent **à partir de 1**, comme on compte les mesures en musique (« mesure 1, 2e note »). La conversion en index du code se fait au chargement.

## Ordre des leçons

L'appli range les leçons d'après `assets/skills.yaml` : d'abord par la compétence la plus avancée de la leçon (position dans le fichier), puis par niveau, puis par `id`.

Dans `assets/skills.yaml`, un prérequis (`requires`) est toujours déclaré plus haut que la compétence qui en dépend. L'ordre du fichier est donc un ordre d'apprentissage, et il ne peut pas y avoir de cycle.
