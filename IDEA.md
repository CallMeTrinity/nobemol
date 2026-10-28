# Nobémol

Nom retenu (à valider : disponibilité Play Store et nom de domaine). Jeu de mots sur « pas de bémol » (pas de souci). Affichage : **Nobémol**. Identifiants techniques : `nobemol`.

Application mobile pour apprendre et réviser le solfège. Le but n'est pas d'afficher des partitions complètes mais de **créer des automatismes de lecture** et d'**apprendre les symboles et les termes** de la notation musicale.

## Objectifs

- **Produit** : lecture de notes rapide, rythme, symboles, termes, sur de courts extraits.
- **Apprentissage** : découvrir Flutter et Dart, et le comparer à React Native.
- **Portfolio** : l'appli, plus un moteur de rendu de partition publiable comme package indépendant.

## Périmètre

- **4 mesures maximum** à l'écran. Pas de saut de ligne, pas de pagination.
- **Grande portée** (clé de sol + clé de fa liées par une accolade) prévue **dès le départ** dans le modèle.
- Contenu pédagogique écrit en texte (syntaxe ABC), comme LaTeX pour les maths.

## Public visé

**Tous les niveaux**, du débutant complet au musicien qui retravaille sa lecture.

- **Test de positionnement** au premier lancement, façon Duolingo. **Pas au MVP**, mais à prévoir dans le modèle de données.
- **Substitut au MVP** : un choix manuel du point de départ (« je débute », « je connais la clé de sol », « je lis les deux clés »...).

### Conséquences sur le design

- **Chaque leçon et chaque exercice est tagué** dès le départ par compétence (`note-reading.treble`, `rhythm.eighths`, `terms.dynamics`...) et par niveau. Sans ces tags, un test de positionnement est impossible à brancher plus tard.
- **Les exercices de lecture sont paramétriques** : clé, tessiture, lignes supplémentaires, altérations, vitesse. Un même exercice couvre donc tous les niveaux, et le niveau devient un jeu de paramètres. Le test de positionnement peut alors être **adaptatif** : on durcit les paramètres tant que l'utilisateur réussit.
- **Les débutants ont besoin d'explications**, pas seulement d'entraînement. Il faut des écrans de théorie courts avant les exercices (« voici la clé de sol »). C'est du contenu à écrire.
- **Les musiciens avancés** voudront les clés d'ut (alto, ténor). L'ABC les supporte (`clef=alto`, `clef=tenor`). Le moteur doit les traiter comme un simple paramètre de clé, sans cas particulier.

## Décisions prises

| Sujet | Décision | Raison |
|---|---|---|
| Framework mobile | Flutter | Rendu custom via `CustomPainter`, identique iOS/Android. Objectif d'apprentissage. |
| Plateforme | **Android uniquement** | Pas de Xcode ni de compte Apple. Flutter garde la porte iOS ouverte sans réécriture. |
| Distribution | **Pas de Play Store** prévu, APK installé à la main (GitHub Releases) | Évite le compte payant et le test fermé obligatoire. |
| Identifiant d'appli | `fr.antoninpamart.nobemol` | Domaine `nobemol.antoninpamart.fr` à l'envers (convention). |
| Cible de dev du moteur | **Web** en plus d'Android | Hot reload sans émulateur. La cible macOS desktop exige Xcode. |
| Syntaxe des leçons | **Sous-ensemble strict de l'ABC notation** | Lisible, facile à parser, compatible avec les outils existants. Pas de syntaxe maison. Le sous-ensemble est écrit (grammaire + fichiers d'exemple) avant le parser. |
| Formats écartés | LilyPond, MusicXML | LilyPond trop dur à parser (Scheme embarqué), MusicXML pas écrivable à la main. |
| Rendu dans l'appli | Moteur maison en Dart | Interactif (notes cliquables, colorées), hors ligne. |
| Back-office Symfony + aperçu abcjs | **Reporté** | Au MVP, rien à servir. abcjs accepte plus d'ABC que notre parser : un aperçu correct ne garantit rien. Revient quand le contenu sera servi à distance. |
| Rendu serveur (Verovio) | Écarté | Statique, peu interactif, n'apprend rien. |
| Police musicale | Bravura (SMuFL) | Boîtes englobantes et points d'ancrage des glyphes. Les métadonnées utiles sont **générées en Dart** (pas de JSON brut embarqué). SMuFL permet de changer de police (Leland, Petaluma) sans toucher au layout. |
| Format des leçons | **Un fichier YAML par leçon**, ABC compris (`abc: \|`) | La musique (ABC) et la pédagogie (exercice) restent séparées, mais en champs et pas en fichiers. Pas d'ABC multi-ligne échappé dans du JSON. |
| Validation du contenu | Validateur Dart qui utilise **notre** parser, lancé en CI | Vérifie l'ABC, le schéma, l'existence des cibles et des compétences. |
| Sous-ensemble ABC | **Strict** : tout ce qui sort du sous-ensemble est une erreur, jamais ignoré. Une hauteur s'écrit d'une seule façon (`c`, pas `C'`) | Une leçon qui passe le validateur s'affiche comme prévu. Spécification : [doc/abc.md](nobemol-app/packages/notation/doc/abc.md). |
| Durée par défaut (`L:`) | **Obligatoire** dès qu'il y a une note, `L:1/1` pour des notes sans rythme | L'ABC standard prend la croche ou la double croche selon `M:`. Un auteur qui oublie `L:` aurait des croches sans le savoir. Le sous-ensemble ne devine pas. |
| Temps musical | Fractions exactes (`Fraction`), pas de `double` | Deux événements de deux portées tombent dans la même colonne seulement si leurs instants sont égaux. Prépare les n-olets. |
| Exercice de rythme (sans audio) | **Durée en temps** d'une note ou d'un silence ciblé, 8 boutons de ¼ à 4. Chiffrages x/4 seulement | Même mécanique que `identify-note`. Une note liée compte toute la liaison. En 6/8, « un temps » change de sens : écarté pour l'instant. Le rythme tapé viendra avec l'audio. |
| Ligatures | **Choisies par l'auteur**, règle ABC : croches collées = un groupe | Pas de regroupement automatique par temps. Une leçon montre exactement ce qui est écrit. |
| Signes et termes en ABC | Décorations `!…!` et `.` devant la note, termes en annotations `"^…"` / `"_…"` | ABC standard (abcjs et abcm2ps les lisent). Une écriture par signe : `.` pour le staccato, pas `!staccato!`. |
| Police des termes | **Edwin Italic** (MuseScore, OFL), chasses générées en Dart | Bravura recommande Academico (introuvable en ligne) puis Edwin. Le layout reste en Dart pur : il mesure le texte avec les chasses générées, pas avec Flutter. |
| Exercice de signes | **Sens** du signe ciblé, réponses **choisies par l'auteur** (2 à 8) | Le soufflet et « cresc. » ont la même réponse. Une première leçon propose peu de réponses, les suivantes davantage : le niveau devient un paramètre, comme pour la lecture de notes. |
| Indexation des cibles | **Base 1** (`measure`, `event`) | Les leçons sont écrites à la main par des musiciens : « mesure 1, 2e note ». Conversion une seule fois, au chargement. |
| Moteur sans Flutter | `package:notation/core.dart` (abc, modèle, layout) à côté de `notation.dart` (rendu) | Le validateur tourne avec `dart run`, sans `dart:ui`. Préfigure le découpage `notation_core` / `notation_flutter`. |
| Stockage des leçons (MVP) | Embarquées dans l'appli | Du texte : ~1000 leçons pèsent environ 100 à 200 Ko compressées. |
| Noms des notes | Modèle en **lettres** (comme l'ABC), affichage **do-ré-mi** | Réglage C-D-E ajoutable plus tard sans refonte. |
| Gestion d'état | **Riverpod 3, sans codegen** | Réglages, score, chrono et progression dès le MVP. Pas de `build_runner` pour l'état. |
| Persistance | **Drift** (progression, révision), `shared_preferences` (réglages) | Requêtes « cartes dues », migrations, maîtrise par compétence pour le futur test. Hive et Isar écartés (projets d'origine abandonnés). |
| Navigation | `go_router` | Standard, maintenu par l'équipe Flutter. |
| i18n | `gen-l10n` (ARB) dès le départ, FR seul | Peu coûteux maintenant, pénible à rattraper. |
| Repo | Monorepo. La racine ne contient que le générique (doc, identité, CI). Tout Flutter vit dans `nobemol-app/` | Place libre pour un futur back-office Symfony à côté. |
| Workspace Flutter | **pub workspaces**, racine = `nobemol-app/pubspec.yaml`, membre `packages/notation` | Un seul `pubspec.lock`. Pas besoin de Melos pour deux packages. |
| Version Flutter | Figée (FVM ou mise) | Même version en local et en CI. |
| Lint | `very_good_analysis` (package), `flutter_lints` (appli) | Strict là où c'est publiable. |
| Tests | Unitaires (parser, layout) + **golden tests** (rendu) | Goldens générés sur une seule plateforme (CI Linux) : le rendu des polices varie selon l'OS. |
| CI | GitHub Actions : analyze, test, build APK. Un tag `vX.Y.Z` sur `main` publie une release avec l'APK | Clé de signature fixe dans les secrets GitHub : une mise à jour s'installe par-dessus sans perdre la progression. |

## Architecture

```
nobemol/                        repo : doc, identité, CI
├── .github/workflows/          un workflow par projet
└── nobemol-app/                appli Flutter + racine du workspace pub
    ├── assets/lessons/         leçons en YAML (théorie avec ABC + exercice)
    ├── assets/skills.yaml      arbre de compétences
    ├── packages/notation/      moteur de rendu (publiable)
    │   └── tool/               génération des métadonnées Bravura (suit le package)
    └── tool/                   validateur de contenu

leçon YAML -> parser ABC -> modèle -> layout -> liste de dessin -> CustomPainter
générateur d'exercice ──────────^
```

Le moteur vit dans un **package Dart séparé** (`packages/notation`), développé **en parallèle** de l'appli et piloté par ses besoins. On ne le développe pas « d'abord ».

**C'est le modèle qui fait référence, pas l'ABC.** L'ABC n'est qu'une source parmi d'autres : les exercices paramétriques (MVP compris) construisent le modèle directement en code.

### Les 4 couches du moteur

1. **Parser** : ABC vers modèle. Dart pur, testé unitairement.
2. **Modèle** : System > StaffGroup > Staff > Measure > Event (Note, Rest, Chord) + Decorations. Dart pur.
3. **Layout** : positionnement. C'est **toute la difficulté** (espacement, hampes, ligatures, collisions). **Dart pur, en interlignes** (l'unité de SMuFL), conversion en pixels seulement au dessin. Produit une **liste de dessin** (glyphe en x,y, ligne, chemin), testable sans Flutter.
4. **Rendu** : `CustomPainter` qui dessine la liste. Seule couche qui importe Flutter. Glyphes Bravura via `TextPainter`, derrière une unique fonction `drawGlyph` (piège : décalage de la ligne de base). Remplaçable plus tard par des `Path` extraits, ou par un export SVG.

Un seul package au départ. On le découpe (`notation_core` en Dart pur / `notation_flutter`) seulement au moment de publier.

### Modèle de hauteur

- Une hauteur = **degré diatonique + octave + altération**, pas de numéro MIDI. Un fa# n'est pas un solb pour la lecture.
- Une clé = (ligne de référence, hauteur de référence). La position sur la portée se calcule à partir de la clé et du degré. Les clés d'ut (alto, ténor) ne demandent aucun cas particulier.

### Grande portée : conséquences sur le design

- En ABC, on l'écrit avec deux voix regroupées :
  ```
  %%score {RH LH}
  V:RH clef=treble
  V:LH clef=bass
  ```
- **Le layout horizontal doit être calculé sur toutes les portées en même temps.** Deux événements qui tombent au même temps musical doivent être alignés verticalement. On raisonne donc en **colonnes temporelles** (time slices) communes au système, et pas portée par portée.
- Les barres de mesure traversent tout le groupe. L'accolade et la barre initiale font partie du système.
- Chaque note doit rester rattachée à sa portée pour les exercices (« quelle est la note en clé de fa ? »).

### Exemple de leçon

```
X:1
M:3/4
L:1/8
K:G
!p! G2 AB c2 | !crescendo(! d4 !crescendo)! e2 | !f! d6 |]
```

```yaml
id: treble-dynamics-01
skills: [note-reading.treble, terms.dynamics]
level: 2
abc: |
  X:1
  M:3/4
  L:1/8
  K:G
  !p! G2 AB c2 | !crescendo(! d4 !crescendo)! e2 | !f! d6 |]
exercise:
  type: identify-note
  targets:
    - { staff: RH, measure: 1, event: 2 }
```

Les index `measure` et `event` sont fragiles si l'ABC change : le validateur vérifie que chaque cible existe. Ils comptent à partir de 1.

Cet exemple date de la conception. Depuis l'étape 5, son ABC passe le parser, mais le format réel des leçons est décrit dans [doc/lessons.md](nobemol-app/doc/lessons.md) : l'ABC de l'exercice va dans `exercise.abc`, avec des cibles `{ staff, measure, event }`. L'étape 4 ajoute `identify-duration`, l'étape 5 `identify-marking` (sens d'une nuance, d'un soufflet, d'une articulation ou d'un terme).

## Feuille de route

Voir [ROADMAP.md](ROADMAP.md) : étapes, tâches et état d'avancement.

## Risques identifiés

- **Viser tous les niveaux coûte cher en contenu.** Les exercices paramétriques passent bien à l'échelle, mais les écrans de théorie et les leçons structurées sont à écrire un par un. Au MVP, on couvre le début du parcours et on étend ensuite.
- **Le moteur dévore l'appli.** Garde-fou : on n'implémente une fonctionnalité de gravure que si un exercice en a besoin.
- **Le poids de l'APK vient de l'audio, pas des leçons.** Une soundfont complète pèse des dizaines de Mo. Prendre une soundfont piano seule, ou synthétiser le son.
- **L'audio.** Jouer une note : OK. Détecter la hauteur au micro : projet à part (latence, bruit, appareils). Repoussé à la fin.
- **Pas d'équivalent à Expo Go.** Android Studio (SDK + émulateur) nécessaire, `flutter doctor`. Tester tôt sur un vrai appareil.
- **Latence audio Android** plus élevée et plus variable que sur iOS selon les appareils. À surveiller pour les exercices d'oreille et de rythme.
- **Publication Play Store** : pas prévue. Si ça change : compte développeur payant, et pour un compte personnel récent, un test fermé avec des testeurs pendant plusieurs semaines avant la production.

## Ressources

- Spécification SMuFL et métadonnées Bravura
- *Behind Bars*, Elaine Gould (règles de gravure)
- Standard ABC notation (abcnotation.com)
- abcjs (référence de comportement ABC), code source de VexFlow (algorithmes de layout)
- `simple_sheet_music` (pub.dev) : à lire pour s'inspirer, pas comme dépendance

## Journal de comparaison Flutter / React Native

À tenir pendant le développement : ce qui est plus simple, plus dur ou juste différent. Matière pour le portfolio.

## Questions ouvertes

- Algorithme de révision espacée : reprendre celui de Recto, Leitner simple, ou FSRS ?
- Arbre de compétences : quelles compétences, dans quel ordre, avec quels prérequis ?
- Algorithme du test de positionnement (post-MVP).
