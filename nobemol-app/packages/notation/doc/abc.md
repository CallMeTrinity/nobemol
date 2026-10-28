# Sous-ensemble ABC

Le moteur lit un **sous-ensemble strict** de l'[ABC 2.1](https://abcnotation.com/wiki/abc:standard:v2.1). Tout ce qui sort de ce sous-ensemble est **refusé avec une erreur**, jamais ignoré : une leçon qui passe le validateur s'affiche comme prévu.

Le sous-ensemble grandit avec le moteur (voir [ROADMAP.md](../../../../ROADMAP.md)). Les messages d'erreur indiquent l'étape qui ajoutera une syntaxe refusée aujourd'hui.

Les fichiers d'exemple sont dans [`test/abc/`](../test/abc) : `valid/` (avec le résultat attendu) et `invalid/` (avec l'erreur attendue). Ils servent de tests au parser.

## Exemples

Une portée en clé de sol :

```abc
X:1
K:C
C D E F G
```

Une grande portée :

```abc
X:1
%%score {RH LH}
K:C
V:RH clef=treble
c e g
V:LH clef=bass
C, E, G,
```

## Grammaire (étape 2)

```ebnf
morceau      = { ligne-vide | commentaire } , en-tête , corps ;

en-tête      = champ-X , { champ-V | directive-score | commentaire } , champ-K ;
champ-X      = "X:" , entier ;
champ-K      = "K:" , "C" , [ espace , clé ] ;
champ-V      = "V:" , id-voix , [ espace , clé ] ;
directive-score = "%%score" , élément-score , { élément-score } ;
élément-score   = id-voix | "{" , id-voix , id-voix , { id-voix } , "}" ;

corps        = { champ-V | ligne-musique | commentaire } ;
ligne-musique = { espace } , { note , { espace } } ;

note         = [ altération ] , ( grave , { "," } | aiguë , { "'" } ) ;
altération   = "^^" | "^" | "=" | "_" | "__" ;
grave        = "C" | "D" | "E" | "F" | "G" | "A" | "B" ;
aiguë        = "c" | "d" | "e" | "f" | "g" | "a" | "b" ;

clé          = "clef=" , ( "treble" | "bass" | "alto" | "tenor" ) ;
id-voix      = ( lettre | chiffre | "_" ) , { lettre | chiffre | "_" } ;
commentaire  = "%" , { caractère } ;
```

Les espaces sont libres autour des notes et des éléments de `%%score`.

## Règles

### En-tête

- `X:` ouvre le morceau. Avant, seuls les lignes vides et les commentaires sont admis.
- `K:` ferme l'en-tête. À l'étape 2, la tonalité est toujours `C` : pas d'armure.
- `V:` et `%%score` se placent entre `X:` et `K:`. `%%score` ne figure qu'une fois.
- Tout autre champ (`T:`, `M:`, `L:`...) est refusé. Le titre d'une leçon va dans son fichier YAML, pas dans l'ABC.

### Hauteurs

| ABC | Note | ABC | Note |
|---|---|---|---|
| `C,` | do3 | `c` | do5 (3e interligne en clé de sol) |
| `C` | **do4, do central** | `c'` | do6 |

- Majuscule : octave 4. Minuscule : octave 5. Chaque `,` descend d'une octave, chaque `'` monte d'une octave.
- `,` ne suit qu'une majuscule et `'` qu'une minuscule. L'ABC standard accepte `C'` (= `c`) et `c,` (= `C`) : ici, une hauteur s'écrit d'une seule façon.
- L'altération est l'**altération écrite** : `^` dièse, `_` bémol, `=` bécarre, `^^` et `__` doubles. Le modèle garde ce qui est écrit, pas ce qui sonne : `^F G F` donne fa#, sol, fa sans altération.

### Clés

- `treble` (sol 2e ligne), `bass` (fa 4e ligne), `alto` (ut 3e ligne), `tenor` (ut 4e ligne).
- La clé de `K:` s'applique à toutes les voix. La clé d'un `V:` la remplace pour cette voix. Sans clé : `treble`.
- Une voix garde la même clé tout le morceau : redonner une autre clé à une voix est une erreur.

### Voix et portées

Une voix ABC = une portée du modèle (`Staff.id` = identifiant de la voix).

- **Sans `V:`** : une seule portée, sans identifiant.
- **Avec `V:`** : la musique suit toujours une ligne `V:` du corps. Un `V:` dans le corps sélectionne la voix (et la crée si besoin).
- **Avec `%%score`** : il fixe l'ordre des portées, de haut en bas. `{RH LH}` les lie par une accolade (grande portée). Une voix du corps absente de `%%score` est une erreur (l'ABC ne l'afficherait pas). Une voix de `%%score` sans musique donne une portée vide.
- **Sans `%%score`** : les portées suivent l'ordre d'apparition des voix, sans accolade.

### Lignes

- Une **ligne vide** dans le morceau est une erreur : en ABC, elle termine le morceau, et la suite serait perdue. Les lignes vides à la fin sont admises.
- `%` commence un commentaire jusqu'à la fin de la ligne. Les directives `%%` autres que `%%score` sont refusées.
- Le morceau peut ne contenir aucune note : la portée s'affiche vide, avec sa clé.

## Refusé, et quand ça arrive

| Syntaxe | Exemple | Étape |
|---|---|---|
| Durées | `C2`, `C/2` | 3 |
| Barres de mesure | `\|`, `\|]`, `:\|` | 3 |
| Mesure, unité de temps | `M:3/4`, `L:1/8` | 3 |
| Armure | `K:G` | 3 |
| Silences | `z` | 4 |
| Liaisons de prolongation | `C-C` | 4 |
| Rythmes pointés | `C>D` | 4 |
| Décorations | `!p!`, `.C` | 5 |
| Accords, n-olets, liaisons | `[CEG]`, `(3`, `(CD)` | plus tard |
| Annotations, accords chiffrés | `"Am"` | non prévu |
| Champs dans la ligne | `[V:RH]`, `[K:G]` | non prévu |
| Crochets et barres dans `%%score` | `[S A]`, `(S A)`, `S \| A` | non prévu |

## Erreurs

Le parser lève une `AbcException` avec la ligne et la colonne (base 1) dans le texte ABC, et un message en français. Exemple : `ligne 3, colonne 2 : durée non supportée (étape 3)`.
