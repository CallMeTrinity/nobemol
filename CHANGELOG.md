# Changelog

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), versions en [SemVer](https://semver.org/lang/fr/). Tant que la version commence par `0.`, l'appli est en bêta : les releases GitHub sont marquées « pré-version ».

Le workflow de release reprend la section de la version comme notes de release : son titre doit commencer par `## [x.y.z]`.

## [Non publié]

### Ajouté

- Onglet Réviser : chaque note, durée ou signe raté devient une carte. Elle revient le lendemain, puis dans 3, 7, 14 et 30 jours tant que la réponse est juste. Une erreur, et elle repart du début.
- Révision du jour (15 cartes, environ 3 minutes), cartes nouvelles et acquises, et les plus difficiles.
- Onglet Arcade, avec les notes déjà apprises en clé de sol, en clé de fa ou sur la grande portée. Trois modes : Chrono (60 secondes, combo multiplicateur), Sans fin (les notes accélèrent, une erreur et c'est fini) et Survie (3 erreurs, de nouvelles clés en route, dès le niveau 5).
- Records par mode et par clé, écran de fin de partie, pause. Les erreurs de l'arcade partent en révision.
- Onglet Profil : niveau, leçons terminées, meilleur combo, record en chrono, précision globale.
- Statistiques sur 7 jours, 30 jours ou depuis le début : XP par jour face à l'objectif, temps de pratique, temps moyen par note, précision par clé et par note.
- 18 succès, débloqués à la fin d'une leçon, d'une révision ou d'une partie, avec leur date.
- Sauvegarde : la progression, les records, les succès et les réglages s'exportent dans un fichier (Drive, mail...) et se réimportent sur un autre téléphone, depuis le Profil ou dès le démarrage avec « J'ai déjà une sauvegarde ».
- Arcade, mode Entraînement : 20 notes sans chrono ni record, avec la clé, les lignes supplémentaires et les altérations au choix.
- Icône de Nobémol à la place de celle de Flutter, adaptée à la forme choisie par le téléphone et aux icônes à thème.
- L'appli signale une nouvelle version publiée sur GitHub, en haut du Profil. Le réglage « Vérifier les mises à jour » coupe cette vérification, seul accès de l'appli à Internet.

### Modifié

- L'arcade remplace la lecture libre en bas du Parcours.
- Chaque réponse garde la carte de sa question. La mise à jour depuis la `1.0.0` garde toute la progression, mais les erreurs passées ne créent pas de cartes.
- Les réglages passent dans le Profil, sous la sauvegarde. Les succès déjà mérités avant la mise à jour s'affichent tout de suite, et se fêtent à la session suivante.

## [1.0.0] - 2026-10-30 (lancement)

Version de lancement : les étapes 6 à 9 de la [feuille de route](https://github.com/CallMeTrinity/nobemol/blob/main/ROADMAP.md) sur le MVP de la bêta. Une mise à jour depuis la `0.0.1` s'installe par-dessus.

### Ajouté

- Nouveau design « Touches » : couleurs, polices embarquées (Bricolage Grotesque, Instrument Sans, DM Mono), boutons à ombre pleine, thème sombre selon le téléphone.
- Clavier d'une octave pour nommer les notes, sur toutes les portées. Les touches noires restent inactives.
- Navigation à quatre onglets : Parcours, Réviser, Arcade, Profil. Les trois derniers arrivent bientôt.
- Halo coloré derrière la note ou le signe à trouver.
- Noms des notes sous la portée dans certaines pages de théorie.
- Progression gardée sur le téléphone : XP (10 par bonne réponse, plus avec un combo), niveaux, objectif du jour.
- Parcours : compétences par branche, avec leur maîtrise. Une compétence se débloque quand ses prérequis sont maîtrisés (80 %).
- Carte « Reprendre » : une leçon interrompue reprend à sa page de théorie, même après redémarrage.
- Écran compétence : théorie, exercice (meilleur score) et arcade (bientôt).
- Correction expliquée après chaque réponse : place de la note sur la portée, origine de l'altération, figures d'une durée, sens d'un signe. Les leçons peuvent écrire leurs propres explications.
- Altérations au clavier : touche noire, puis fa dièse ou sol bémol.
- Combo affiché pendant l'exercice, et perdu à la première erreur.
- Résultats détaillés : XP par bonnes réponses et bonus de combo, notes à revoir.
- Écran « Niveau supérieur » et compétences débloquées.
- Confirmation avant de quitter un exercice commencé.
- Démarrage au premier lancement : bienvenue, point de départ, objectif du jour de 5 à 20 minutes.
- Le point de départ débloque le parcours : « je lis les deux clés » ouvre directement la clé de fa et la grande portée.
- Réglages (onglet Profil) : noms des notes do-ré-mi ou C-D-E, noms sous les touches, point de départ, objectif du jour, vibrations, thème clair, sombre ou système.
- Vibration courte si la réponse est juste, plus longue si elle est fausse.
- À propos : version de l'appli et licences des polices.

### Modifié

- Théorie : l'idée de la page en titre, la suite en dessous.
- Durées en 8 tuiles, signes en cartes. Le signe s'affiche sur les cartes après la réponse.
- Les points de départ passent en bas du Parcours, sous « Lecture libre ».
- Les leçons se débloquent dans l'ordre de l'arbre de compétences.
- Après chaque réponse, juste ou fausse, un panneau de correction monte sur les réponses et attend « Continuer ».
- Avec une armure, la réponse porte l'altération : en sol majeur, un fa se répond fa dièse.
- Objectif du jour en XP selon la durée choisie : 300 XP pour 5 minutes, jusqu'à 1 200 pour 20 minutes (100 XP fixes avant).

### Limites connues

- Réviser, Arcade et Profil (statistiques, succès, sauvegarde) arrivent bientôt.
- Pas encore de son : « Son des notes » est annoncé dans les réglages.
- Pas de vérification de mise à jour : surveiller les releases GitHub.

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

[Non publié]: https://github.com/CallMeTrinity/nobemol/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/CallMeTrinity/nobemol/releases/tag/v1.0.0
[0.0.1]: https://github.com/CallMeTrinity/nobemol/releases/tag/v0.0.1
