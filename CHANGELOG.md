# Changelog

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), versions en [SemVer](https://semver.org/lang/fr/). Tant que la version commence par `0.`, l'appli est en bêta : les releases GitHub sont marquées « pré-version ».

Le workflow de release reprend la section de la version comme notes de release : son titre doit commencer par `## [x.y.z]`.

## [Non publié]

### Ajouté

- Nouveau design « Touches » : couleurs, polices embarquées (Bricolage Grotesque, Instrument Sans, DM Mono), boutons à ombre pleine, thème sombre selon le téléphone.
- Clavier d'une octave pour nommer les notes, sur toutes les portées. Les touches noires restent inactives.
- Navigation à quatre onglets : Parcours, Réviser, Arcade, Profil. Les trois derniers arrivent bientôt.
- Halo coloré derrière la note ou le signe à trouver.
- Noms des notes sous la portée dans certaines pages de théorie.

### Modifié

- Théorie : l'idée de la page en titre, la suite en dessous.
- Durées en 8 tuiles, signes en cartes. Le signe s'affiche sur les cartes après la réponse.

## [0.0.1] - 2026-10-28 (bêta 1)

Première bêta : le MVP, étapes 1 à 5 de la [feuille de route](https://github.com/CallMeTrinity/nobemol/blob/main/ROADMAP.md).

### Ajouté

- Lecture de notes : clé de sol, clé de fa, grande portée, lignes supplémentaires, altérations. Score et chrono.
- Choix du point de départ (« je débute », « je connais la clé de sol »...).
- 19 leçons écrites en YAML + ABC : théorie puis exercice, rangées dans un arbre de compétences.
- Exercice `identify-note` : nommer une note ciblée dans une courte phrase, grande portée comprise.
- Exercice `identify-duration` : durée en temps d'une note ou d'un silence ciblé (¼ à 4), liaisons comprises.
- Exercice `identify-marking` : sens d'une nuance, d'un soufflet, d'une articulation ou d'un terme.
- Moteur de notation maison (`packages/notation`) : parser d'un sous-ensemble strict de l'ABC, mesures, armures, chiffrages, hampes, silences, points, ligatures, liaisons, nuances, soufflets, articulations, termes. Polices Bravura et Edwin Italic.
- Validateur de contenu lancé en CI : une leçon invalide fait échouer le build.

### Limites connues

- Pas de progression sauvegardée : tout repart de zéro au redémarrage.
- Lisibilité sur téléphone pas encore vérifiée (doubles croches, nuances, termes).
- Le moteur n'évite pas les chevauchements horizontaux entre signes voisins.
- Icône d'appli par défaut.

[Non publié]: https://github.com/CallMeTrinity/nobemol/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/CallMeTrinity/nobemol/releases/tag/v0.0.1
