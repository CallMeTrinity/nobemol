# Sous-ensemble ABC

Le moteur lit un **sous-ensemble strict** de l'[ABC 2.1](https://abcnotation.com/wiki/abc:standard:v2.1). Tout ce qui sort de ce sous-ensemble est **refusé avec une erreur**, jamais ignoré : une leçon qui passe le validateur s'affiche comme prévu.

Le sous-ensemble grandit avec le moteur (voir [ROADMAP.md](../../../../ROADMAP.md)). Les messages d'erreur indiquent l'étape qui ajoutera une syntaxe refusée aujourd'hui.

Les fichiers d'exemple sont dans [`test/abc/`](../test/abc) : `valid/` (avec le résultat attendu) et `invalid/` (avec l'erreur attendue). Ils servent de tests au parser.

## Exemples

Des notes sans rythme (des rondes), en clé de sol :

```abc
X:1
L:1/1
K:C
C D E F G
```

Une courte phrase en sol majeur, à 3/4 :

```abc
X:1
M:3/4
L:1/4
K:G
G A B | c2 B | A2 G |]
```

Une grande portée en mesures :

```abc
X:1
%%score {RH LH}
M:2/4
L:1/4
K:C
V:RH clef=treble
c e | g2 |]
V:LH clef=bass
C, G, | C,2 |]
```

## Grammaire (étape 3)

```ebnf
morceau      = { ligne-vide | commentaire } , en-tête , corps ;

en-tête      = champ-X , { champ-V | champ-M | champ-L | directive-score
               | commentaire } , champ-K ;
champ-X      = "X:" , entier ;
champ-M      = "M:" , entier , "/" , entier ;
champ-L      = "L:1/" , entier ;
champ-K      = "K:" , tonalité , [ espace , clé ] ;
champ-V      = "V:" , id-voix , [ espace , clé ] ;
directive-score = "%%score" , élément-score , { élément-score } ;
élément-score   = id-voix | "{" , id-voix , id-voix , { id-voix } , "}" ;

tonalité     = lettre-note , [ "#" | "b" ] , [ "m" ] ;
lettre-note  = "C" | "D" | "E" | "F" | "G" | "A" | "B" ;

corps        = { champ-V | ligne-musique | commentaire } ;
ligne-musique = { espace } , { ( note | barre ) , { espace } } ;

note         = [ altération ] , ( grave , { "," } | aiguë , { "'" } ) ,
               [ durée ] ;
altération   = "^^" | "^" | "=" | "_" | "__" ;
grave        = lettre-note ;
aiguë        = "c" | "d" | "e" | "f" | "g" | "a" | "b" ;
durée        = entier , [ "/" , [ entier ] ] | "/" , [ entier ] | "//" ;
barre        = "|" | "||" | "|]" ;

clé          = "clef=" , ( "treble" | "bass" | "alto" | "tenor" ) ;
id-voix      = ( lettre | chiffre | "_" ) , { lettre | chiffre | "_" } ;
commentaire  = "%" , { caractère } ;
```

Les espaces sont libres autour des notes, des barres et des éléments de `%%score`. Pas d'espace entre une note et sa durée.

## Règles

### En-tête

- `X:` ouvre le morceau. Avant, seuls les lignes vides et les commentaires sont admis.
- `K:` ferme l'en-tête. Il donne la tonalité, donc l'armure (voir plus bas).
- `V:`, `M:`, `L:` et `%%score` se placent entre `X:` et `K:`, une seule fois chacun (`V:` une fois par voix). Ils ne changent pas en cours de morceau.
- Tout autre champ (`T:`, `Q:`...) est refusé. Le titre d'une leçon va dans son fichier YAML, pas dans l'ABC.

### Tonalité et armure

- Majeure : `C`, `G`, `F#`, `Bb`... Mineure : `Am`, `Em`, `Bbm`... Une seule écriture : `Gm`, pas `Gmin` ni `G minor`.
- Les modes (`Dmix`, `EDor`), `K:none` et les tonalités de plus de 7 altérations (`G#`, `Fb`) sont refusés.
- Le modèle ne garde que l'**armure** (nombre de dièses ou de bémols) : sol majeur et mi mineur s'affichent pareil.
- Dans `K:G`, `F` est un fa dièse **par l'armure** : la note s'affiche sans signe, comme sur une partition. Le modèle garde l'altération écrite, pas celle qui sonne (voir Hauteurs).

### Durées

- `L:` donne l'unité : `1/1`, `1/2`, `1/4`, `1/8` ou `1/16`. **`L:` est obligatoire dès que le morceau contient une note**. L'ABC standard prend la croche ou la double croche par défaut selon `M:` : un piège pour qui écrit une leçon, donc le sous-ensemble ne devine pas.
- La durée d'une note = `L:` × son multiplicateur : `C2` (double), `C/2` ou `C/` (moitié), `C//` (quart), `C3/2`.
- À l'étape 3, une note dure une **ronde**, une **blanche** ou une **noire**. Le reste est refusé : notes pointées et croches (étape 4), plus long qu'une ronde, durées qui demandent une liaison (`C5` avec `L:1/4`).
- Des notes sans rythme s'écrivent en rondes : `L:1/1`.

### Mesures et barres

- `M:` donne le chiffrage : `3/4`, `6/8`... Chiffre du haut de 1 à 12, chiffre du bas 1, 2, 4, 8 ou 16. `M:C` et `M:C|` sont refusés : écrire `M:4/4` et `M:2/2`.
- **Sans `M:`**, pas de barre : la musique forme une seule mesure, de longueur libre.
- Barres : `|` simple, `||` double, `|]` finale. Les reprises (`|:`, `:|`), fins alternatives (`|1`) et `[|` sont refusées.
- **Chaque mesure est complète**, la dernière aussi, même sans barre. Pas de levée (anacrouse) pour l'instant.
- Pas de barre avant la première note, pas de mesure vide (`| |`).
- Une mesure peut continuer à la ligne suivante.

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
- **Avec `M:`**, toutes les voix qui ont de la musique ont **le même nombre de mesures et les mêmes barres**. Les notes de deux voix qui commencent au même instant sont alignées verticalement.
- Le chiffrage et l'armure valent pour toutes les voix.

### Lignes

- Une **ligne vide** dans le morceau est une erreur : en ABC, elle termine le morceau, et la suite serait perdue. Les lignes vides à la fin sont admises.
- `%` commence un commentaire jusqu'à la fin de la ligne. Les directives `%%` autres que `%%score` sont refusées.
- Le morceau peut ne contenir aucune note : la portée s'affiche vide, avec sa clé.

## Refusé, et quand ça arrive

| Syntaxe | Exemple | Étape |
|---|---|---|
| Croches et valeurs plus courtes | `C` avec `L:1/8` | 4 |
| Notes pointées | `C3` avec `L:1/8` | 4 |
| Silences | `z` | 4 |
| Liaisons de prolongation | `C-C` | 4 |
| Rythmes pointés | `C>D` | 4 |
| Décorations | `!p!`, `.C` | 5 |
| Accords, n-olets, liaisons | `[CEG]`, `(3`, `(CD)` | plus tard |
| Levée (première mesure incomplète) | `C \| D E F G \|` | plus tard |
| Reprises, fins alternatives | `\|:`, `:\|`, `\|1` | non prévu |
| Chiffrages symboliques | `M:C`, `M:C\|` | non prévu |
| Modes | `K:Dmix` | non prévu |
| Annotations, accords chiffrés | `"Am"` | non prévu |
| Champs dans la ligne | `[V:RH]`, `[K:G]` | non prévu |
| Crochets et barres dans `%%score` | `[S A]`, `(S A)`, `S \| A` | non prévu |

## Erreurs

Le parser lève une `AbcException` avec la ligne et la colonne (base 1) dans le texte ABC, et un message en français. Exemple : `ligne 6, colonne 7 : mesure 1 incomplète : 3/4 au lieu de 4/4`.
