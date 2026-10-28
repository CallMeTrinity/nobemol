# Nobémol

Application Android pour apprendre et réviser le solfège. Voir [IDEA.md](IDEA.md) pour le produit et les décisions techniques.

## Structure du repo

```
nobemol/
├── IDEA.md               produit et décisions techniques
├── ROADMAP.md            étapes et avancement
├── CHANGELOG.md          versions publiées
├── nobemol-*.svg         identité visuelle
├── .github/workflows/    CI (un workflow par projet)
└── nobemol-app/          appli Flutter + moteur de notation (voir son README)
```

Un futur back-office Symfony viendrait à côté de `nobemol-app/`, avec son propre workflow.

## Releases

Pas de Play Store : chaque version est un APK publié sur GitHub Releases, à installer à la main sur le téléphone (autoriser les sources inconnues). Un tag `vX.Y.Z` poussé sur un commit de `main` lance `.github/workflows/release.yml` : vérification complète, APK signé, release avec la section du changelog. Les versions `0.x` sont marquées pré-version.

### Une fois : la clé de signature

Android n'installe une mise à jour que si elle est signée **avec la même clé** que la version installée. Sans clé fixe, chaque release obligerait à désinstaller, donc à perdre la progression.

```sh
# Hors du repo : le .gitignore racine n'exclut pas les .jks.
keytool -genkeypair -v -keystore ~/nobemol-release.jks -alias nobemol \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -i ~/nobemol-release.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_ALIAS --body nobemol
gh secret set ANDROID_KEY_PASSWORD
```

**Sauvegarder `nobemol-release.jks` et ses mots de passe hors du repo** (gestionnaire de mots de passe). Clé perdue = plus aucune mise à jour possible sans désinstaller. Le `.gitignore` d'Android exclut déjà `*.jks` et `key.properties`.

Pour signer en local, créer `nobemol-app/android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Sans ce fichier, le build release est signé en debug.

### À chaque version

1. Dans `nobemol-app/pubspec.yaml`, monter `version` : `X.Y.Z+N`, avec **N toujours plus grand** que la version d'avant (c'est le `versionCode` Android, une mise à jour plus petite est refusée).
2. Dans `CHANGELOG.md`, renommer `## [Non publié]` en `## [X.Y.Z] - date`, en remettre un vide au-dessus, mettre à jour les liens en bas.
3. Merger sur `main`, puis :

```sh
git switch main && git pull
git tag vX.Y.Z
git push origin vX.Y.Z
```

Le workflow échoue si le tag n'est pas sur `main`, si `pubspec.yaml` ou `CHANGELOG.md` ne disent pas la même version, ou si les secrets de signature manquent.
