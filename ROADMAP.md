# Feuille de route

Le produit et les décisions techniques sont dans [IDEA.md](IDEA.md).

**Règle de base** : le moteur avance au rythme de l'appli. On n'implémente une fonctionnalité de gravure que si un exercice en a besoin.

## Vue d'ensemble

Les étapes 1 à 5 forment le MVP, publié en bêta (`0.0.1`, voir [CHANGELOG.md](CHANGELOG.md)). Les étapes 6 à 9 font la version de lancement (`1.0.0`). Leurs « À vérifier » se font sur l'APK de la release.

Les étapes 6 à 12 viennent du design « Touches » (Claude Design, tour 2) : tous les écrans de l'appli. Elles touchent surtout l'appli. Le moteur ne bouge que pour le halo de cible et les noms sous les notes.

| Étape | Moteur | Appli débloquée | État |
|---|---|---|---|
| 0 | Setup du repo | | Fait |
| 1 | Modèle avec grande portée, rendu portée + clé + **une note** | **MVP** : lecture de notes | Bêta 0.0.1 |
| 2 | Parser ABC (sous-ensemble) + validateur | Leçons écrites en texte | Bêta 0.0.1 |
| 3 | Mesures, chiffrage, armure, barres, hampes, **alignement entre portées** | Lecture de courtes phrases | Bêta 0.0.1 |
| 4 | Silences, points, ligatures, liaisons de prolongation | Exercices de rythme | Bêta 0.0.1 |
| 5 | Décorations : nuances, articulations, termes | Apprentissage des symboles | Bêta 0.0.1 |
| 6 | Halo de cible, noms sous les notes | Design system, clavier, navigation à 4 onglets | 1.0.0 |
| 7 | | Progression persistée : XP, niveaux, parcours | 1.0.0 |
| 8 | | Boucle d'exercice : feedback, combo, résultats | 1.0.0 |
| 9 | | Démarrage et réglages | 1.0.0 |
| 10 | | Révision espacée | Fait |
| 11 | | Arcade | Fait |
| 12 | | Profil, statistiques, succès, sauvegarde | Fait |
| Plus tard | Accords, n-olets, liaisons d'expression | Au besoin | |

## Releases

Une release par version, publiée sur GitHub Releases avec l'APK signé (workflow `release.yml`). Procédure dans [README.md](README.md#releases).

- [x] `CHANGELOG.md`, version `0.0.1` (bêta 1)
- [x] Workflow : tag `v*.*.*` sur `main` vers APK signé + release
- [x] Version `1.0.0` (lancement) : étapes 6 à 9
- [ ] Clé de signature créée, sauvegardée hors du repo, secrets GitHub renseignés
- [ ] `0.0.1` installée sur un vrai téléphone, puis `0.0.2` installée **par-dessus** (même signature)

## Étape 0 : setup

- [x] Monorepo : racine générique, tout Flutter dans `nobemol-app/`
- [x] Workspace pub (`nobemol-app/pubspec.yaml`), package `packages/notation`
- [x] Identifiant `fr.antoninpamart.nobemol`, plateformes Android + web
- [x] Lint : `very_good_analysis` (package), `flutter_lints` (appli)
- [x] CI GitHub Actions : analyze, tests, build APK (Flutter 3.47.8, `ubuntu-24.04`)

## Étape 1 : une note sur une portée (MVP)

### Moteur

- [x] Structure `lib/src/{model,layout,render}`, retrait du `Calculator` du template
- [x] Modèle : `Pitch` (degré diatonique + octave + altération), `Clef` (ligne et hauteur de référence : sol, fa, ut alto, ut ténor)
- [x] Modèle : System > StaffGroup > Staff, grande portée prévue dès maintenant
- [x] Bravura : police embarquée + script `tool/` qui génère les métadonnées Dart des glyphes utilisés
- [x] Layout en interlignes vers une liste de dessin : portée, clé, accolade et barre initiale (grande portée), une note avec lignes supplémentaires et altération
- [x] Rendu : `CustomPainter` + fonction unique `drawGlyph`
- [x] Tests unitaires : position sur la portée en fonction de la clé et de la hauteur
- [x] Premiers golden tests : écrits, images à générer sur la CI (workflow `goldens.yml`)

### Appli

- [x] Riverpod, `go_router`, `gen-l10n` (FR)
- [x] Générateur d'exercice paramétrique : clé, tessiture, lignes supplémentaires, altérations
- [x] Écran de lecture de notes : 7 boutons do à si, score, chrono
- [x] Choix manuel du point de départ (« je débute », « je connais la clé de sol »...)

**Terminé quand** : l'APK tourne sur un vrai téléphone et une session de lecture se joue en clé de sol, en clé de fa et sur la grande portée.

## Étape 2 : leçons en texte

- [x] **Écrire le sous-ensemble ABC avant le parser** : grammaire + fichiers d'exemple, surtout `%%score` / `V:` ([doc/abc.md](nobemol-app/packages/notation/doc/abc.md), `test/abc/`)
- [x] Parser ABC vers le modèle, tests unitaires sur les fichiers d'exemple
- [x] Format de leçon YAML (théorie avec `abc: |` + exercice), chargement depuis `assets/lessons/` ([doc/lessons.md](nobemol-app/doc/lessons.md))
- [x] Validateur Dart dans `tool/`, lancé en CI : ABC, schéma, existence des compétences. Les cibles arrivent avec `identify-note` (étape 3)
- [x] Fixer l'indexation des cibles : **base 1**
- [x] Premier arbre de compétences (`assets/skills.yaml`, branche `note-reading.*`)
- [x] Premiers écrans de théorie : 5 leçons (clé de sol, clé de fa, lignes supplémentaires, altérations, grande portée)

**Terminé quand** : une leçon écrite à la main dans un fichier YAML s'affiche dans l'appli, et une leçon invalide fait échouer la CI.

À vérifier : la CI GitHub échoue bien sur une leçon invalide (vérifié en local : `dart run tool/validate_content.dart` sort en code 1).

## Étape 3 : courtes phrases

- [x] Sous-ensemble ABC étendu avant le code : `M:`, `L:` (obligatoire), tonalités de `K:`, durées, barres `|`, `||`, `|]` ([doc/abc.md](nobemol-app/packages/notation/doc/abc.md))
- [x] Modèle : `Fraction` (temps exact), `KeySignature`, `TimeSignature`, `Staff > Measure > Event`, figures ronde, blanche, noire
- [x] Parser : mesures complètes, mêmes mesures et mêmes barres dans toutes les voix
- [x] Mesures, chiffrage, armure (positions par clé, clé d'ut 4e ligne comprise), barres de mesure
- [x] Hampes (direction, longueur), ancres SMuFL générées depuis Bravura
- [x] Layout horizontal en **colonnes temporelles** communes à tout le système, espacement selon la durée
- [x] Barres de mesure qui traversent la grande portée
- [x] Exercice `identify-note` sur une note ciblée : cibles `{ staff, measure, event }` en base 1, vérifiées par le validateur, note colorée à l'écran
- [x] Leçons : mesures et figures, armure, grande portée en mesures

**Terminé quand** : une leçon `identify-note` sur la grande portée se joue sur un vrai téléphone, notes lisibles, et une cible inexistante fait échouer la CI.

À vérifier :

- Goldens à générer sur la CI (commit `[goldens]`) : `phrase_treble`, `phrase_grand_staff`, `key_signatures_sharps`, `key_signatures_flats`. Les 4 goldens existants ne devraient pas changer.
- Lisibilité sur téléphone : 3 mesures de noires en 4/4 donnent un interligne d'environ 7 px en portrait. Si c'est trop petit : phrases de 2 mesures, ou mode paysage.

## Étape 4 : rythme

- [x] Sous-ensemble ABC étendu avant le code : silences `z`, croches et doubles croches, un point, ligatures par collage, `-` ([doc/abc.md](nobemol-app/packages/notation/doc/abc.md))
- [x] Modèle : `Rest`, `NoteValue` jusqu'à la double croche, `dotted`, `tiedToNext`, `beamedToNext`, `System.tieChain`
- [x] Parser : liaison vers la même hauteur sans altération écrite, pas de silence dans une ligature, `>` refusé (une durée s'écrit d'une seule façon)
- [x] Bravura : silences, point, crochets, ancres `stemUpNW` / `stemDownSW`, épaisseurs de ligature et de liaison
- [x] Layout : silences (pause d'une mesure entière centrée), points, crochets, ligatures (sens commun, pente limitée, deuxième ligature, tronçon), liaisons du côté opposé à la hampe
- [x] Rendu : `BeamCommand` et `TieCommand` (arcs de Bézier pleins)
- [x] Exercice `identify-duration` : durée en temps (¼ à 4), chiffrages x/4, liaison entière colorée et comptée, vérifié par le validateur
- [x] Compétences `rhythm.*` et 6 leçons : temps, silences, croches, notes pointées, liaisons, doubles croches

**Terminé quand** : une leçon `identify-duration` avec croches ligaturées et liaison se joue sur un vrai téléphone, et une cible sur une note d'arrivée de liaison fait échouer la CI.

À vérifier :

- Goldens à générer sur la CI (commit `[goldens]`) : `rhythm_treble`, `rhythm_sixteenths`, `rhythm_grand_staff`. Les 8 goldens existants ne devraient pas changer : mêmes commandes de dessin, seules les hampes sont dessinées après les têtes (vérifié sur la liste de dessin, même couleur partout).
- Lisibilité des doubles croches sur téléphone (leçon « Les doubles croches », 3 mesures en 2/4).

## Étape 5 : symboles et termes

- [x] Sous-ensemble ABC étendu avant le code : nuances `!p!`, soufflets `!crescendo(!` / `!crescendo)!`, `.`, `!tenuto!`, `!accent!`, `!fermata!`, annotations `"^…"` / `"_…"` ([doc/abc.md](nobemol-app/packages/notation/doc/abc.md))
- [x] Modèle : `Event.decorations`, `Decoration` scellé (`Dynamic`, `Articulation`, `HairpinStart`, `HairpinEnd`, `Annotation`)
- [x] Parser : une écriture par signe (`!staccato!`, `!>!`, `H` refusés), une nuance et une articulation par note, silence avec `!fermata!` seulement, soufflets vérifiés par voix (fermés, même type, pas de nuance ni de texte au-dessous au milieu), annotations avant les décorations
- [x] Bravura : nuances (ancre `opticalCenter`), articulations, point d'orgue, épaisseur de soufflet
- [x] Police de texte : Edwin Italic (MuseScore, OFL), chasses générées en Dart par `tool/edwin.dart` (lecture des tables OpenType), rendu sans crénage pour coller aux chasses
- [x] Layout : articulations côté tête, staccato et tenuto dans un interligne, accent hors de la portée, point d'orgue au-dessus de tout ; une ligne de textes au-dessus, une ligne nuances + soufflets + textes au-dessous, sous ce qui dépasse le plus ; texte après la nuance de sa note (« p dolce »)
- [x] Rendu : `TextCommand`, `DrawCommand.decoration` et `decorationHighlights` pour colorer un signe sans sa note
- [x] Exercice `identify-marking` : sens du signe ciblé, réponses choisies par l'auteur (`choices`, 2 à 8), un seul signe par cible, termes connus, vérifié par le validateur
- [x] Compétences `terms.*` et `symbols.articulations`, 5 leçons : nuances, crescendo et diminuendo, articulations, termes de mouvement, termes de caractère

**Terminé quand** : une leçon `identify-marking` avec nuances, soufflet et terme se joue sur un vrai téléphone, et une cible sur une note à deux signes fait échouer la CI.

À vérifier :

- Goldens à générer sur la CI (commit `[goldens]`) : `markings_treble`, `markings_grand_staff`. Les 11 goldens existants ne devraient pas changer : aucune décoration, mêmes commandes de dessin.
- Taille des termes (em = 2 interlignes) et lisibilité des nuances sur téléphone.
- Le moteur n'évite pas les chevauchements horizontaux (deux nuances sur deux noires voisines, deux termes rapprochés) : règle d'écriture dans [doc/lessons.md](nobemol-app/doc/lessons.md). À revoir si les leçons en souffrent.

## Étape 6 : design system et navigation

Source : `Nobemol Touches.dc.html` et `tokens/nobemol-tokens.json` (projet Claude Design). Les écrans existants passent au nouveau design avant d'en ajouter.

- [x] Tokens clair / sombre en `ThemeExtension` : couleurs (`color.*`), rayons, profondeurs (ombre pleine décalée en Y), espacements (`lib/theme/tokens.dart`). Clair ou sombre selon le téléphone, ou forcé dans les réglages (étape 9)
- [x] Polices **embarquées** (pas de `google_fonts`, l'appli marche hors ligne) : Bricolage Grotesque (titres), Instrument Sans (texte), DM Mono (méta). Licences OFL à côté (`fonts/`). Les deux premières sont variables : graisse et taille optique par `fontVariations`
- [x] Composants : bouton à ombre pleine (repos, appui, juste, faux, inactif), tuile, chip, carte réponse (`lib/ui/`)
- [x] **Clavier** : 7 touches blanches do à si, 5 noires (inactives sans altérations), états juste / faux / appuyé
- [x] Navigation à 4 onglets (`StatefulShellRoute`) : Parcours, Réviser, Arcade, Profil. Écrans « Bientôt » pour les trois derniers. Leçons et exercices passent au-dessus de la barre
- [x] Moteur : **halo** coloré derrière une note ou un signe ciblé (`color.accent.soft`), à côté de la couleur actuelle. Sous la portée : les lignes restent visibles
- [x] Moteur : **noms sous les notes** pour la théorie (« fa, sol, la »). Champ `names: true` d'une page ([doc/lessons.md](nobemol-app/doc/lessons.md)), noms générés par l'appli (prêts pour C-D-E)
- [x] Écrans existants refaits : théorie (pages, précédent / suivant), lecture de notes, durées (8 tuiles), signes (cartes)

**Terminé quand** : les 4 exercices et la théorie se jouent au clavier et aux tuiles, en clair et en sombre, et les goldens existants n'ont pas changé sans halo.

Tranché :

- Le clavier remplace les 7 boutons **partout**, grande portée comprise : la réponse est un nom de note, sans octave.
- Cartes de signes : **le sens seul** pendant la question, le glyphe apparaît à la correction. Avec le glyphe sur la carte, l'exercice devenait de l'appariement de formes.
- Une note seule (lecture paramétrique) est aussi une cible : colorée et entourée d'un halo, comme dans le design.

À vérifier :

- Goldens du halo et des noms (`halo_targets`, `halo_markings`, `labels`) : à générer sur la CI (commit `[goldens]`), puis à relire.
- Sur un vrai téléphone : taille du clavier sur petit écran, rendu des polices variables, thème sombre.

## Étape 7 : progression persistée

Prérequis de toutes les étapes suivantes. Ouvre la base Drift prévue dans [IDEA.md](IDEA.md).

- [x] Drift : schéma v1 (sessions, réponses, théorie, compétences maîtrisées), **migrations testées dès la v1** : schéma figé dans `drift_schemas/`, tests dans `test/drift/` ([doc/database.md](nobemol-app/doc/database.md))
- [x] XP : 10 par bonne réponse, +5 à partir de la 5e d'affilée. Niveaux par paliers (100 × n × (n − 1) XP), objectif du jour (100 XP fixes, réglable depuis l'étape 9)
- [x] Maîtrise par compétence (%), états « à faire », « en cours », « maîtrisé » (80 %)
- [x] Déblocage par prérequis de l'arbre (`skills.yaml`) : « se débloque après … »
- [x] Parcours : niveau et XP, objectif du jour, carte « Reprendre » (leçon en cours, page de théorie), tuiles par branche
- [x] Écran compétence : théorie (n pages, progression), exercice (meilleur score), arcade (verrouillée avant l'exercice, « Bientôt » après)

**Terminé quand** : une leçon interrompue reprend à la bonne page après redémarrage de l'appli, et l'XP survit à une mise à jour de l'APK.

Tranché :

- **Maîtrise** = moyenne des meilleurs scores des leçons de la compétence (une leçon non jouée compte 0). Calculée, pas stockée : elle suit le contenu sans migration. Seul le fait d'avoir maîtrisé est stocké, pour qu'une nouvelle leçon ne reverrouille rien chez l'élève.
- Une leçon ne compte pour la maîtrise que si elle se joue **dès que la compétence est débloquée** (ses compétences sont celle-ci ou ses prérequis). Sinon `grand-staff-phrase` (grande portée + phrases) bloquait tout le rythme derrière la grande portée. Vérifié par le validateur.
- Une session **quittée avant la fin n'est pas gardée** (ni XP ni réponses) : cohérent avec la confirmation « ce qui sera perdu » de l'étape 8.
- Les points de départ restent en bas du Parcours (« Lecture libre ») jusqu'au démarrage de l'étape 9. Leurs sessions rapportent de l'XP, sans compter pour une compétence.
- Cible web : la base tourne dans le navigateur (`web/sqlite3.wasm`, `web/drift_worker.js`, 1,1 Mo, absents de l'APK).

À vérifier :

- Sur un vrai téléphone : `0.0.1` puis cette version **par-dessus**. La base se crée, puis une session jouée, une mise à jour de plus (`0.0.3`) : XP et page de théorie toujours là.
- ~~Équilibre XP : une session parfaite de 20 notes rapporte 280 XP, donc l'objectif de 100 XP tombe en une session.~~ Tranché à l'étape 9 : objectifs de 300 à 1 200 XP.
- Le design « Touches » n'a pas pu être relu pendant l'étape (pas d'accès au projet Claude Design) : Parcours et écran compétence sont construits avec les composants de l'étape 6, à comparer aux maquettes.

## Étape 8 : boucle d'exercice

- [x] **Panneau de correction** posé sur les réponses, à leur hauteur exacte : la portée ne bouge jamais. « Continuer » toujours au même endroit, juste ou faux
- [x] Feedback juste : « Juste, c'est un ré », XP gagnés, **explication** propre à la note (repère sur la portée)
- [x] Feedback faux : bonne réponse, réponse donnée, explication. La cible est colorée en rouge sur la portée
- [x] Explications : générées (note : place sur la portée, clé, cause de l'altération ; durée : figures et temps ; signe : comment le reconnaître) ou écrites par l'auteur, champ `explain` d'une cible ([doc/lessons.md](nobemol-app/doc/lessons.md)). Vérifié par le validateur, 160 caractères au plus
- [x] Combo (×n dans la barre du haut), combo perdu
- [x] Altérations : touche noire, puis choix de l'orthographe (fa dièse ou sol bémol). Un fa dièse n'est pas un sol bémol. L'armure et les altérations de la mesure comptent
- [x] Quitter la leçon : confirmation avec ce qui sera perdu (croix et retour du téléphone)
- [x] Résultats : score, chrono, meilleur combo, détail de l'XP, notes à revoir (une fois chacune, la note seule sur sa portée)
- [x] Écran « Niveau supérieur », avec les compétences maîtrisées et débloquées par la session

**Terminé quand** : une erreur affiche son explication, et la note ratée apparaît dans « À revoir » des résultats.

Tranché :

- **Altérations en toutes lettres** (« fa dièse », « si bémol ») : les trois polices de l'interface n'ont pas ♯ ni ♭. Ceux de Bravura sont calés sur la portée, pas sur une ligne de texte.
- **Mode leçon : « Continuer » obligatoire, juste ou faux.** Un feedback inséré dans le bas d'écran l'agrandissait et décalait la portée à chaque réponse. Le panneau monte par-dessus les réponses (200 ms), à hauteur fixe (au moins `Sizes.answerDock`) : le bouton ne bouge pas, quelle que soit l'explication. Il ne répond qu'après 300 ms : le panneau arrive sous le doigt, un double appui ne saute pas la correction.
- **Le rythme rapide, c'est l'arcade** (étape 11) : pas de panneau ni d'explication. La lecture libre (20 notes au hasard) garde le panneau en attendant, puis sera remplacée par l'arcade.
- Touches verte et rouge cachées par le panneau : le texte dit la bonne réponse et celle donnée, la cible est colorée sur la portée. Un signe se voit sur la portée, pas dans le panneau (seul, un staccato n'est qu'un point).
- **Les réponses de note portent l'altération lue** : dans la leçon sur l'armure, un fa en ré majeur se répond fa dièse (avant : fa). Les leçons sans altération ne changent pas : touches noires inactives.
- Seules les notes d'une touche du clavier existent : le générateur ne tire plus de mi dièse ni de do bémol, le validateur les refuse dans une leçon.
- Le palier se montre après les résultats : niveau gagné, ou compétence maîtrisée. Les compétences débloquées s'y ajoutent.
- Réponses gardées en base sous le même nom qu'avant pour les notes naturelles (`c`, `d`...) : les sessions de l'étape 7 restent lisibles. Altérées : `fSharp`, `gFlat`.

À vérifier :

- Sur un vrai téléphone : taille de la bulle d'orthographe sur petit écran, explications de 4 lignes dans le panneau (vérifié à 360 × 740 en test).

## Étape 9 : démarrage et réglages

- [x] Démarrage en 3 écrans (`/bienvenue`) : bienvenue, point de départ (4 niveaux), objectif quotidien (5 à 20 min). Rien n'est gardé avant « C'est parti »
- [x] Réglages dans `shared_preferences` (`lib/settings/`) : noms des notes do-ré-mi / C-D-E, point de départ, noms sous les touches, objectif, vibrations, thème clair / sombre / système. Ouverts depuis l'onglet Profil
- [x] Point de départ : ses compétences comptent comme **acquises** dans le parcours (`StartLevel.acquired`)
- [x] Vibrations : courte si c'est juste (`lightImpact`), plus longue si c'est faux (`vibrate`)
- [x] « Son des notes » affiché « Bientôt » tant que l'audio n'existe pas
- [x] À propos : version de l'appli (`package_info_plus`), licences des polices (Bravura, Edwin, polices d'interface) via `LicenseRegistry`

**Terminé quand** : le premier lancement passe par les 3 écrans, et le choix C-D-E change les touches, les feedbacks et la théorie.

Tranché :

- **Objectifs recalés : 300, 600, 900, 1 200 XP** pour 5, 10, 15, 20 min. Une réponse et sa correction prennent environ 10 s, soit une soixantaine d'XP par minute. Les 20 à 150 XP du design tombaient en deux réponses. Barème et niveaux inchangés. Objectif par défaut (avant le démarrage) : 5 min.
- **Point de départ = compétences acquises, pas maîtrisées.** « Je lis les deux clés » ouvre la clé de fa, les lignes supplémentaires et la grande portée comme prérequis, sans rien écrire en base. Changer de point de départ dans les réglages est donc réversible. « Commencer » propose d'abord une leçon hors de ces compétences, puis y revient quand tout le reste est fait. Les compétences acquises restent jouables et comptent pour la maîtrise comme les autres.
- **Tout le monde passe par le démarrage**, y compris après une mise à jour depuis une version sans réglages : la progression reste, et c'est l'occasion de choisir un objectif.
- **C-D-E** : lettres capitales, altérations en toutes lettres (« F dièse »). Le réglage change les touches, les corrections, les explications générées, « À revoir » et les noms sous la portée. Les textes des leçons restent en do-ré-mi : ils sont écrits à la main.
- **Noms sous les touches désactivés** : touches blanches muettes (le lecteur d'écran garde le nom). La bulle d'orthographe d'une touche noire garde ses noms.
- **Réglages dans l'onglet Profil**, sous la carte « Bientôt », en attendant le profil (étape 12).
- La lecture libre reste en bas du Parcours jusqu'à l'arcade (étape 11), qui la remplace.
- Licences des polices embarquées comme assets (`fonts/*-OFL.txt`, et celles de Bravura et Edwin dans le package `notation`) : quelques Ko.

À vérifier :

- Sur un vrai téléphone : vibrations (Android les coupe si le retour tactile du système est désactivé), écran Licences, thème forcé sombre sur un téléphone en clair.
- Le design « Touches » des écrans de démarrage et de réglages n'a pas pu être relu (pas d'accès au projet Claude Design) : construits avec les composants de l'étape 6, à comparer aux maquettes.
- Équilibre des objectifs : 300 XP pour 5 min est une estimation. À recaler avec les temps de réponse réels (table `answers`) si l'objectif tombe trop vite ou trop lentement.

## Étape 10 : révision espacée

- [x] **Choisir l'algorithme avant le code** : **Leitner**, 5 boîtes (1, 3, 7, 14, 30 jours). Décision dans [IDEA.md](IDEA.md)
- [x] Cartes : une note dans une clé, une durée, un signe. Créées à la première erreur (`lib/review/card.dart`). Schéma v2 : chaque réponse garde sa carte (`answers.card`, [doc/database.md](nobemol-app/doc/database.md))
- [x] Onglet Réviser : cartes dues aujourd'hui, nouvelles, acquises, session de révision (15 cartes, ~3 min)
- [x] « Les plus difficiles » : les cartes ratées au moins deux fois, les plus ratées d'abord

**Terminé quand** : une note ratée revient le lendemain, puis s'espace après des réponses justes.

Tranché :

- **Recto écarté** : il n'a pas d'algorithme d'espacement, seulement un tri par dernière note. **FSRS écarté** : il vise 4 notes auto-évaluées et des paramètres optimisés sur l'historique. Avec juste / faux et les paramètres par défaut, le gain est faible et les intervalles s'expliquent mal.
- **Cartes recalculées, pas stockées** : chaque réponse garde sa carte, et l'état de Leitner se rejoue depuis ce journal (`lib/review/leitner.dart`). Comme la maîtrise : changer d'algorithme ne demande pas de migration. Le journal sert aussi l'étape 12 : la clé de chaque note y est enfin.
- **Les réponses comptent partout** : la première bonne réponse du jour sur une carte due la fait monter d'une boîte, en leçon comme en révision. Une erreur, où qu'elle soit, la renvoie en boîte 1. Les bonnes réponses suivantes du même jour ne comptent pas : la carte n'est plus due.
- Une réponse compte **le jour où sa session finit**, en jours de calendrier locaux : une carte ratée à 23 h revient à minuit. Les changements d'heure ne décalent rien.
- **Une carte, c'est ce qui est écrit**, pas son sens : « rall. » et « rit. » font deux cartes, une blanche pointée et une blanche liée à une noire aussi. Une note garde l'altération lue (armure comprise) et s'affiche avec l'altération écrite.
- Une carte s'affiche **seule sur sa portée** : la note dans sa clé (la grande portée se défait), la durée et le signe sur un si en clé de sol. Pas la phrase d'origine : la carte doit se lire sans la leçon, qui peut changer.
- Réponses d'un signe en révision : celles de la **première leçon qui le demande**, choisies par son auteur. Un signe qu'aucune leçon ne demande plus est sauté.
- Session : les 15 cartes les plus en retard, puis les plus fragiles, **rangées par sorte** (notes, durées, signes) pour que les réponses ne changent pas à chaque question. Les touches noires s'ouvrent pour toutes les notes dès qu'une est altérée : elles ne trahissent pas la réponse. Pas de « Recommencer » aux résultats : les cartes ne sont plus dues.
- Une révision est gardée comme une lecture libre (`lessonId` vide) : de l'XP, pas de maîtrise.
- Les réponses d'avant la v2 n'ont pas de carte : l'onglet part vide après la mise à jour. Les recréer était impossible en lecture libre, la clé n'était pas gardée.

À vérifier :

- Sur un vrai téléphone : `1.0.0` puis cette version **par-dessus** (migration v2), une note ratée, puis l'onglet Réviser le lendemain.
- Le design « Touches » de l'onglet Réviser n'a pas pu être relu (pas d'accès au projet Claude Design) : construit avec les composants de l'étape 6, à comparer aux maquettes.
- Taille d'un soufflet ou d'une liaison en révision : affichés en grand comme une note seule (`StaffSpaces.exercise`), réduits s'ils débordent.
- Seuil des « plus difficiles » (2 erreurs) et durée d'une session (15 cartes) : à recaler avec l'usage.

## Étape 11 : arcade

- [x] Correction rapide, pour enchaîner : couleur sur la cible et la touche, vibration, sans panneau ni explication. Les erreurs vont à la révision (étape 10)
- [x] Remplace la lecture libre (points de départ du Parcours)
- [x] Générateur limité aux notes déjà apprises, choix de la clé (sol, fa, grande portée)
- [x] Chrono : 60 s, +50 par note × multiplicateur de combo
- [x] Sans fin : les notes accélèrent, une erreur et c'est fini
- [x] Survie : 3 erreurs, nouvelles clés en route, débloqué au niveau 5
- [x] Records par mode et par clé, écran de fin (record, notes justes, précision, temps par note, XP), pause. Schéma v3 : `sessions.arcade` et `sessions.score` ([doc/database.md](nobemol-app/doc/database.md))

**Terminé quand** : un record battu en Chrono s'affiche comme nouveau record et survit au redémarrage.

Tranché :

- **Notes seulement** : l'arcade travaille la lecture rapide. Durées et signes restent aux leçons et à la révision.
- **Notes apprises** = compétences dont un exercice a été joué, ou données par le point de départ. Une clé s'ouvre avec sa compétence (`note-reading.treble`, `.bass`, `.grand`). Les lignes supplémentaires (une) et les altérations s'ajoutent à toutes les clés une fois leur leçon jouée. Avant tout exercice de notes, l'arcade est fermée.
- **Multiplicateur** : ×2 à la 5e note juste d'affilée, ×3 à la 10e, ×4 à partir de la 15e. Une erreur ne coûte que le combo, et le temps de la correction (600 ms).
- **Accélération** (sans fin et survie) : 6 s pour la première note, 5 % de moins à chaque note juste, jamais sous 1,5 s. Le temps écoulé compte comme une erreur, et part en révision (réponse gardée `timeout`).
- **Survie** : une nouvelle clé apprise toutes les 10 notes justes (sol, puis fa, puis grande portée), tirées au hasard parmi celles ouvertes. Un seul record, toutes clés mêlées. Les deux autres modes : un record par clé.
- Score : des points en chrono, des notes justes en sans fin et en survie.
- **3 XP par note juste**, sans bonus de combo : le combo compte déjà dans le score. Une note toutes les 2 à 3 s donne environ 60 XP par minute, le rythme de l'objectif du jour.
- **Records calculés** depuis les sessions, comme la maîtrise. « Nouveau record » : un score au-dessus du précédent, ou un premier score non nul.
- **Pause** : bouton, retour du téléphone, appli en arrière-plan. La note est cachée pendant la pause. Le chrono, le temps de la note et le temps de réponse s'arrêtent. Une partie quittée n'est pas gardée, comme une leçon.
- La correction : 150 ms en vert, 600 ms en rouge avec la bonne touche allumée. Pas de son tant que l'audio n'existe pas.
- Écran compétence : la tuile « Arcade » ouvre l'onglet, une fois l'exercice joué. Elle n'apparaît que sur les leçons de lecture de notes.
- Pas d'écran « Niveau supérieur » après une partie : l'XP compte, le palier se verra à la prochaine leçon.
- Les tests de l'écran de lecture passent par les exercices des leçons de clé de sol, de clé de fa et de grande portée : mêmes paramètres que les anciens points de départ.

À vérifier :

- Sur un vrai téléphone : fluidité de la barre de temps (rafraîchie toutes les 33 ms), vibration à chaque note, pause en passant sur une autre appli.
- Le design « Touches » de l'arcade n'a pas pu être relu (pas d'accès au projet Claude Design) : construit avec les composants de l'étape 6, à comparer aux maquettes.
- Équilibre : durée des notes en sans fin (6 s, −5 %), paliers du multiplicateur, 3 XP par note. À recaler avec les temps de réponse réels.

## Étape 12 : profil, statistiques, succès, sauvegarde

- [x] Profil : niveau, chiffres clés (leçons terminées, meilleur combo, record chrono, précision globale), liens vers les statistiques, les succès, la sauvegarde et les réglages
- [x] Statistiques sur 7 jours, 30 jours, tout : XP par jour face à l'objectif (par semaine sur « Tout »), précision par note et par clé, temps moyen par note, temps de pratique (`lib/profile/stats.dart`)
- [x] Succès (18) : définis en données (`assets/achievements.yaml`, [doc/achievements.md](nobemol-app/doc/achievements.md)), vérifiés par le validateur. Débloqués à la fin d'une session, gardés en base. Schéma v4 : table `achievements` ([doc/database.md](nobemol-app/doc/database.md))
- [x] Sauvegarde : export / import d'un fichier JSON (pas de compte, pas de serveur). Branché sur « J'ai déjà une sauvegarde » au démarrage
- [x] Nom du profil : retiré du design

**Terminé quand** : une sauvegarde exportée sur un téléphone se réimporte sur un autre avec la progression, les records et les succès.

Tranché :

- **Pas de nom de profil** : pas de compte, une personne par téléphone. Le nom n'apportait rien, et aurait ajouté un écran au démarrage.
- **Succès calculés, déblocage stocké**, comme la maîtrise : le compte suit la progression, seul le fait d'avoir débloqué (et sa date) est gardé. Durcir une condition ne reverrouille rien. Un succès retiré du fichier reste en base, ignoré.
- **Déblocage en fin de session** : une session quittée n'est pas gardée, elle ne débloque rien non plus. Les maîtrises sont enregistrées d'abord : « maîtriser une compétence » se débloque dans la même session.
- Les 18 succès sont définis ici, pas repris du design (illisible) : leçons, sans faute, bonnes réponses, combo, séries de jours, niveaux, maîtrise, lecture de notes complète, chrono, sans fin, cartes acquises. Pas de succès sur l'objectif du jour : l'historique de l'objectif n'est pas gardé, un changement de réglage aurait réécrit le passé.
- Après la mise à jour, les succès déjà atteints s'affichent **débloqués sans date**, puis s'enregistrent à la session suivante, qui les fête tous d'un coup.
- **Statistiques à l'objectif d'aujourd'hui** : l'historique des réglages n'est pas gardé. La précision par note vient des cartes de révision : les réponses d'avant la v2 n'y sont pas, et une note de la grande portée compte dans sa propre clé. Le temps moyen par note ne compte pas les temps écoulés de l'arcade.
- **Série** = jours de calendrier locaux avec au moins une session terminée.
- **Record arcade du profil = record chrono**, toutes clés : un score en points se lit seul. Sans fin et survie restent dans l'onglet Arcade.
- **Sauvegarde : feuille de partage à l'export (`share_plus`), sélecteur de fichiers à l'import (`file_picker`)**. Le partage mène au Drive, au mail ou aux Fichiers, le chemin naturel d'un téléphone à l'autre. Le sélecteur accepte tout fichier : le contenu est vérifié ensuite.
- **L'import remplace tout**, progression et réglages, d'un seul bloc. Pas de fusion : deux historiques mêlés fausseraient la révision et les records. Confirmation si le téléphone a déjà une progression (y compris au démarrage, après une mise à jour). Un fichier refusé ne change rien.
- **Format versionné** (`format: 1`), indépendant du schéma Drift : pas d'identifiants, réponses rangées dans leur session, dates en UTC. Un fichier d'un format plus récent est refusé avec « mets l'appli à jour ». Règles dans [doc/database.md](nobemol-app/doc/database.md#sauvegarde).
- Confirmation commune (`lib/ui/confirm_dialog.dart`) : quitter un exercice et remplacer la progression.

À vérifier :

- Sur deux vrais téléphones : export vers le Drive, import sur l'autre au démarrage (« J'ai déjà une sauvegarde »). Progression, records, succès et réglages identiques.
- Sélecteur de fichiers Android sur un fichier du Drive (fournisseur de contenu, pas un chemin local) et nom du fichier partagé (`nobemol-AAAA-MM-JJ.json`).
- `1.0.0` puis cette version **par-dessus** (migration v4) : les succès déjà atteints s'affichent, puis se fêtent à la session suivante.
- Le design « Touches » du profil, des statistiques et des succès n'a pas pu être relu (pas d'accès au projet Claude Design) : construits avec les composants de l'étape 6, à comparer aux maquettes.
- Seuils des succès (chrono 2 500, sans fin 25, combo 25) et couleurs de précision (80 % et 50 %) : à recaler avec l'usage.

## En parallèle

- [ ] Réglages d'exercice : clé de sol, clé de fa ou grande portée, tessiture, altérations
- [ ] Journal de comparaison Flutter / React Native (dans [IDEA.md](IDEA.md))
- [ ] Icône d'appli depuis `nobemol-icone.svg` (aujourd'hui l'icône Flutter par défaut)
- [ ] Vérification de mise à jour : pas de Play Store, donc l'appli peut interroger la dernière release GitHub et le signaler. Demande un repo public (l'API des releases d'un repo privé exige un token)

## Plus tard

- Accords, n-olets, liaisons d'expression
- Test de positionnement adaptatif
- Audio : jouer une note (soundfont piano seule ou synthèse), puis intervalles, oreille, rythme tapé
- Détection de hauteur au micro (projet à part)
- Back-office Symfony, quand le contenu devra être servi à distance
- Publication du package `notation` (découpage `notation_core` / `notation_flutter`)
