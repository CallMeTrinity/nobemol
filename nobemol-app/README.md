# nobemol-app

Appli Flutter (Android + web) et moteur de rendu de notation.

## Structure

```
nobemol-app/
├── pubspec.yaml          appli + racine du workspace pub (un seul pubspec.lock)
├── lib/                  code de l'appli
└── packages/notation/    moteur de rendu de notation (publiable)
```

## Prérequis

- **Flutter 3.47.8** (stable). Même version que la CI (`../.github/workflows/flutter.yml`) : changer les deux en même temps.
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

Tests du moteur, depuis `packages/notation/` : `flutter test`.
