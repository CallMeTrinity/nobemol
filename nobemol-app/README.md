# nobemol-app

Appli Flutter (Android + web) et moteur de rendu de notation.

## Structure

```
nobemol-app/
├── pubspec.yaml          appli + racine du workspace pub (un seul pubspec.lock)
├── assets/
│   ├── skills.yaml       arbre de compétences
│   └── lessons/          une leçon par fichier YAML (voir doc/lessons.md)
├── doc/lessons.md        format des leçons
├── doc/database.md       base de la progression, migrations
├── drift_schemas/        schéma figé de chaque version de la base
├── fonts/                polices de l'interface + licences OFL
├── lib/
│   ├── l10n/             textes (app_fr.arb), AppLocalizations généré par pub get
│   ├── theme/            tokens du design « Touches » et thème clair / sombre
│   ├── ui/               composants : boutons à ombre pleine, tuiles, clavier
│   ├── shell/            barre à 4 onglets, onglets à venir
│   ├── home/             Parcours (niveau, reprise, compétences) et écran compétence
│   ├── progress/         base Drift, XP et niveaux, maîtrise et déblocage
│   ├── lessons/          lecture du contenu (Dart pur) et écran de théorie
│   └── reading/          lecture de notes : générateur, session, écran
├── tool/validate_content.dart  validateur du contenu, lancé en CI
└── packages/notation/    moteur de rendu de notation (publiable)
    ├── doc/abc.md        sous-ensemble ABC accepté par le parser
    ├── fonts/            Bravura, Edwin Italic (termes) + licences OFL
    ├── lib/core.dart     Dart pur : abc -> model -> layout (glyph.g.dart généré)
    ├── lib/notation.dart core + render (Flutter)
    ├── test/abc/         exemples ABC valides et invalides, joués comme tests
    └── tool/             bravura.dart et edwin.dart : polices + métadonnées
                          générées (glyph.g.dart, text_font.g.dart)
```

## Prérequis

- **Flutter 3.47.8** (stable). Même version que la CI (`../.github/workflows/flutter.yml` et `goldens.yml`) : changer partout en même temps, ainsi que `NDK_VERSION` dans `flutter.yml` (valeur de `flutter.ndkVersion`).
- Android Studio avec le SDK, les **Android SDK Command-line Tools** et les licences acceptées (`flutter doctor --android-licenses`).
- Java 17.

## Commandes

Depuis `nobemol-app/` :

```sh
flutter pub get           # résout tout le workspace
flutter analyze           # appli + package notation
flutter test              # tests de l'appli
flutter run -d chrome     # itération rapide sur le moteur
flutter run               # appareil Android ou émulateur
dart run tool/validate_content.dart  # après modification d'une leçon
dart run build_runner build          # après modification de la base (doc/database.md)
```

Le validateur et `lib/lessons/` (hors écrans) n'importent pas Flutter : ils passent par `package:notation/core.dart`, pas `notation.dart`. Sinon `dart run` échoue (`dart:ui` absent).

Depuis `packages/notation/` :

```sh
flutter test              # tests du moteur
dart run tool/bravura.dart # après ajout d'un glyphe dans tool/bravura.dart
dart run tool/edwin.dart   # police des textes et ses chasses
```

## Golden tests

Le rendu des polices varie selon l'OS : les goldens (`packages/notation/test/render/goldens/`) ne sont **générés et comparés que sous Linux**. Sur macOS, ils sont ignorés.

Pour les (re)générer, sur la plateforme de la CI :

- pousser un commit dont le message contient `[goldens]` : le workflow `goldens.yml` committe les images sur la branche ;
- ou, une fois `goldens.yml` présent sur `main`, le lancer à la main (Actions > Goldens).

Les commits du bot ne relancent pas la CI : pousser à nouveau (ou relancer) pour la voir passer.
