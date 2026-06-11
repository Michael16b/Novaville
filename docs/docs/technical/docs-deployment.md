---
sidebar_position: 5
---

# Déploiement de la documentation

Ce document explique comment déployer le site de documentation Novaville, généré avec Docusaurus, sur GitHub Pages.

## Vue d'ensemble

La documentation est déployée automatiquement via le workflow GitHub Actions suivant :

- `.github/workflows/deploy-docs.yml`

Le workflow se déclenche :

- à chaque `push` sur les fichiers sous `docs/**`
- manuellement via `workflow_dispatch`

## Ce que fait le workflow

1. Il récupère le dépôt avec l'historique complet.
2. Il installe les dépendances Node.js dans `docs/`.
3. Il lance le build Docusaurus.
4. Il publie le contenu généré sur GitHub Pages.

## Déploiement local avant publication

Avant de publier, vérifiez toujours la documentation en local :

```bash
cd docs
npm ci
npm run build
npm run serve
```

À vérifier avant toute mise en ligne :

- la build doit réussir sans erreur
- les liens FR/EN doivent fonctionner
- la navigation doit afficher les nouvelles pages
- les pages traduites doivent exister dans les deux locales

## Déploiement sur GitHub Pages

Le déploiement est automatique dès qu'un commit est poussé sur la branche suivie par le workflow.

### Déclenchement automatique

```text
push sur docs/**
    ↓
GitHub Actions lance le workflow
    ↓
npm ci
    ↓
npm run build
    ↓
upload de l'artifact
    ↓
deploy vers GitHub Pages
```

### Déclenchement manuel

Vous pouvez aussi relancer la publication depuis l'onglet **Actions** de GitHub :

1. Ouvrir le dépôt GitHub.
2. Aller dans **Actions**.
3. Choisir **Deploy Documentation to GitHub Pages**.
4. Cliquer sur **Run workflow**.

## Pré-requis côté GitHub

Le workflow utilise les permissions GitHub Pages suivantes :

- `contents: read`
- `pages: write`
- `id-token: write`

Il publie ensuite l'artifact dans l'environnement `github-pages`.

## Cas d'usage courant

### Modifier la documentation

1. Modifier les fichiers dans `docs/`.
2. Lancer le build localement.
3. Pousser la branche.
4. Attendre le déploiement automatique.

### Publier une correction urgente

1. Corriger la page concernée.
2. Vérifier localement avec `npm run build`.
3. Commit + push.
4. Vérifier le workflow dans **Actions**.

## Dépannage

### Le build échoue

Vérifier :

- le contenu de `sidebars.js`
- les liens entre les pages FR et EN
- les fichiers manquants dans `docs/i18n/en/...`

### La publication GitHub Pages n'apparaît pas

Vérifier :

- que le workflow `.github/workflows/deploy-docs.yml` a bien été exécuté
- que l'onglet **Pages** du dépôt est bien configuré
- que l'artifact de build a été généré

### Le site ne reflète pas les derniers changements

Vérifier :

- le commit a bien touché `docs/**`
- le workflow s'est bien terminé avec succès
- le navigateur n'affiche pas une ancienne version mise en cache

## Voir aussi

- [Déploiement local](./local-deployment)
- [Déploiement sur Azure](./azure-deployment)
- [Distribution des applications](./app-distribution)
- [Guides internes](./internal-guides)
