---
sidebar_position: 6
---

# Distribution des applications

Ce document explique comment les différentes versions natives et web de Novaville sont compilées, renommées et distribuées via l'Intégration Continue (CI).

## Workflow de Release

La distribution repose sur le workflow GitHub Actions nommé `flutter_release.yml`. Il s'exécute à chaque push sur `main` et à chaque création de Tag Git.

### 1. Renommage automatique (Tooling)

Par défaut, lors de la création d'un projet Flutter, le nom interne du dossier principal (ici `frontend`) est utilisé pour nommer les exécutables (ex: `frontend.apk`, l'application s'appelle "frontend" une fois installée).

Pour éviter cela de manière automatisée, nous utilisons le package communautaire `rename`. À chaque build dans la CI, ou lors de la construction de l'image Docker, la commande suivante est exécutée :

```bash
dart pub global activate rename
export PATH="$PATH":"$HOME/.pub-cache/bin"
rename setAppName --targets ios,android,macos,windows,linux --value "Novaville"
```

Cela garantit que l'application compilée portera toujours le nom correct aux yeux de l'utilisateur final. *(Note: Si vous modifiez le Dockerfile du frontend, veillez à y intégrer ces mêmes lignes juste avant `flutter build web` !)*

### 2. Compilation ciblée et Artefacts

Le workflow va compiler l'application pour Android (APK et AAB), Linux, Windows (Installeur `.exe` via Inno Setup), macOS/iOS, et Web (PWA). Les fichiers générés sont stockés temporairement en tant que **GitHub Artifacts** (conservation de 14 jours, nécessite d'être connecté à GitHub pour télécharger).

### 3. GitHub Releases

C'est la méthode de distribution principale et pérenne de l'application. Pour déclencher une distribution publique des exécutables, il suffit de pousser un Tag Git commençant par `v` ou `V` (ex: `V1.0.0`) :

```bash
git tag V1.0.0
git push origin V1.0.0
```

La CI capturera automatiquement tous les artefacts construits, les regroupera et les uploadera publiquement sur la page **Releases** du dépôt. Ce sont ces liens publics qui sont référencés dans la page de "Téléchargements" de cette documentation.