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

Du rythme : silences, croches liées par une ligature, notes pointées, liaison de prolongation :

```abc
X:1
M:4/4
L:1/8
K:C
C2 z2 EF G2 | A3 B c2- c2 | z4 G4 |]
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

## Grammaire (étape 4)

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
ligne-musique = { espace } , { ( note | silence | barre ) , { espace } } ;

note         = [ altération ] , ( grave , { "," } | aiguë , { "'" } ) ,
               [ durée ] , [ "-" ] ;
silence      = "z" , [ durée ] ;
altération   = "^^" | "^" | "=" | "_" | "__" ;
grave        = lettre-note ;
aiguë        = "c" | "d" | "e" | "f" | "g" | "a" | "b" ;
durée        = entier , [ "/" , [ entier ] ] | "/" , [ entier ] | "//" ;
barre        = "|" | "||" | "|]" ;

clé          = "clef=" , ( "treble" | "bass" | "alto" | "tenor" ) ;
id-voix      = ( lettre | chiffre | "_" ) , { lettre | chiffre | "_" } ;
commentaire  = "%" , { caractère } ;
```

Les espaces sont libres autour des notes, des silences, des barres et des éléments de `%%score`. Pas d'espace entre une note et sa durée, ni entre la durée et `-`. Une seule exception : les croches et les doubles croches **collées** sont reliées par une ligature (voir Ligatures).

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

- `L:` donne l'unité : `1/1`, `1/2`, `1/4`, `1/8` ou `1/16`. **`L:` est obligatoire dès que le morceau contient une note ou un silence**. L'ABC standard prend la croche ou la double croche par défaut selon `M:` : un piège pour qui écrit une leçon, donc le sous-ensemble ne devine pas.
- La durée d'une note = `L:` × son multiplicateur : `C2` (double), `C/2` ou `C/` (moitié), `C//` (quart), `C3/2`.
- Une note dure une **ronde**, une **blanche**, une **noire**, une **croche** ou une **double croche**, avec **un point** ou sans : `C3` avec `L:1/8` est une noire pointée.
- Refusé : plus long qu'une ronde (ronde pointée comprise), plus court qu'une double croche, double point (`C7` avec `L:1/16`), durées qui demandent une liaison (`C5` avec `L:1/8` : écrire `C4-C`).
- Les rythmes pointés `C>D` et `C<D` sont refusés : écrire les durées, `C3/2 D/`. Une durée s'écrit d'une seule façon.
- Des notes sans rythme s'écrivent en rondes : `L:1/1`.

### Silences

- `z` suivi de sa durée, comme une note : `z` (une unité), `z2`, `z/`, `z3/2`. Mêmes figures que les notes, point compris.
- Refusés : `Z` (silence de plusieurs mesures, écrire `z` avec sa durée) et `x` (silence invisible).
- Un silence se place sur la portée à une hauteur fixe : la pause pend sous la 4e ligne, la demi-pause est posée sur la 3e, les autres sont centrés sur la portée.

### Ligatures

- Des croches et des doubles croches **collées**, sans espace, sont reliées par une ligature : `CDEF` donne quatre croches liées, `CD EF` deux groupes de deux (avec `L:1/8`). C'est la règle de l'ABC standard.
- Une espace, une barre, une fin de ligne ou une note plus longue coupe la ligature. Une croche seule porte un crochet.
- Un silence ne se place pas dans une ligature : un silence collé à une croche ou une double croche (`CzD` avec `L:1/8`) est refusé. Écrire `C z D`.
- Les doubles croches d'un groupe partagent une deuxième ligature. Une double croche isolée dans le groupe (croche pointée et double croche) porte un tronçon de ligature.
- Le moteur ne regroupe rien de lui-même : c'est l'auteur qui choisit les groupes, en général un groupe par temps.

### Liaisons de prolongation

- `-` collé après la note (après sa durée) la lie à la **note suivante de la même voix** : `C2-C`, `c4-|c2`. Les durées s'additionnent.
- La liaison peut traverser une barre et une fin de ligne. Elle ne traverse pas un silence.
- Les deux notes ont la même hauteur. La note d'arrivée s'écrit **sans altération** : `^F2-F`, comme sur la partition, où l'altération ne se répète pas. Deux hauteurs différentes, c'est une liaison d'expression (plus tard).
- Refusé : `-` sans note d'arrivée (fin du morceau), `-` après un silence.

### Mesures et barres

- `M:` donne le chiffrage : `3/4`, `6/8`... Chiffre du haut de 1 à 12, chiffre du bas 1, 2, 4, 8 ou 16. `M:C` et `M:C|` sont refusés : écrire `M:4/4` et `M:2/2`.
- **Sans `M:`**, pas de barre : la musique forme une seule mesure, de longueur libre.
- Barres : `|` simple, `||` double, `|]` finale. Les reprises (`|:`, `:|`), fins alternatives (`|1`) et `[|` sont refusées.
- **Chaque mesure est complète**, la dernière aussi, même sans barre. Pas de levée (anacrouse) pour l'instant.
- Pas de barre avant la première note, pas de mesure vide (`| |`) : une mesure sans note s'écrit avec un silence.
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
- **Avec `M:`**, toutes les voix qui ont de la musique ont **le même nombre de mesures et les mêmes barres**. Les notes et les silences de deux voix qui commencent au même instant sont alignés verticalement.
- Le chiffrage et l'armure valent pour toutes les voix.

### Lignes

- Une **ligne vide** dans le morceau est une erreur : en ABC, elle termine le morceau, et la suite serait perdue. Les lignes vides à la fin sont admises.
- `%` commence un commentaire jusqu'à la fin de la ligne. Les directives `%%` autres que `%%score` sont refusées.
- Le morceau peut ne contenir aucune note : la portée s'affiche vide, avec sa clé.

## Refusé, et quand ça arrive

| Syntaxe | Exemple | Étape |
|---|---|---|
| Rythmes pointés | `C>D` (écrire `C3/2 D/`) | non prévu |
| Silences de plusieurs mesures, silences invisibles | `Z`, `x` | non prévu |
| Triples croches, doubles points | `C/` avec `L:1/16`, `C7` avec `L:1/16` | plus tard |
| Ligature à travers un silence | `CzD` avec `L:1/8` | non prévu |
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
