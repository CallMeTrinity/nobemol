# nobemol-app

Appli Flutter (Android + web) et moteur de rendu de notation.

## Structure

```
nobemol-app/
├── pubspec.yaml          appli + racine du workspace pub (un seul pubspec.lock)
├── lib/
│   ├── l10n/             textes (app_fr.arb), AppLocalizations généré par pub get
│   ├── home/             choix du point de départ
│   └── reading/          lecture de notes : générateur, session, écran
└── packages/notation/    moteur de rendu de notation (publiable)
    ├── fonts/            Bravura + licence OFL
    ├── lib/src/          model -> layout (glyph.g.dart généré) -> render
    └── tool/bravura.dart télécharge Bravura et génère glyph.g.dart
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
```

Depuis `packages/notation/` :

```sh
flutter test              # tests du moteur
dart run tool/bravura.dart # après ajout d'un glyphe dans tool/bravura.dart
```

## Golden tests

Le rendu des polices varie selon l'OS : les goldens (`packages/notation/test/render/goldens/`) ne sont **générés et comparés que sous Linux**. Sur macOS, ils sont ignorés.

Pour les (re)générer, sur la plateforme de la CI :

- pousser un commit dont le message contient `[goldens]` : le workflow `goldens.yml` committe les images sur la branche ;
- ou, une fois `goldens.yml` présent sur `main`, le lancer à la main (Actions > Goldens).

Les commits du bot ne relancent pas la CI : pousser à nouveau (ou relancer) pour la voir passer.
