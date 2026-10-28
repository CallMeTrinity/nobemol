# Feuille de route

Le produit et les décisions techniques sont dans [IDEA.md](IDEA.md).

**Règle de base** : le moteur avance au rythme de l'appli. On n'implémente une fonctionnalité de gravure que si un exercice en a besoin.

## Vue d'ensemble

| Étape | Moteur | Appli débloquée | État |
|---|---|---|---|
| 0 | Setup du repo | | Fait |
| 1 | Modèle avec grande portée, rendu portée + clé + **une note** | **MVP** : lecture de notes | En cours |
| 2 | Parser ABC (sous-ensemble) + validateur | Leçons écrites en texte | En cours |
| 3 | Mesures, chiffrage, armure, barres, hampes, **alignement entre portées** | Lecture de courtes phrases | En cours |
| 4 | Silences, points, ligatures, liaisons de prolongation | Exercices de rythme | En cours |
| 5 | Décorations : nuances, articulations, termes | Apprentissage des symboles | En cours |
| Plus tard | Accords, n-olets, liaisons d'expression | Au besoin | |

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

## En parallèle

- [ ] Réglages : clé de sol, clé de fa ou grande portée, tessiture, altérations
- [ ] Révision espacée des erreurs avec Drift. Algorithme à choisir : celui de Recto, Leitner ou FSRS
- [ ] Journal de comparaison Flutter / React Native (dans [IDEA.md](IDEA.md))

## Plus tard

- Accords, n-olets, liaisons d'expression
- Test de positionnement adaptatif
- Réglage des noms de notes C-D-E
- Audio : jouer une note (soundfont piano seule ou synthèse), puis intervalles, oreille, rythme tapé
- Détection de hauteur au micro (projet à part)
- Back-office Symfony, quand le contenu devra être servi à distance
- Publication du package `notation` (découpage `notation_core` / `notation_flutter`)
