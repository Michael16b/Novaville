# Documentation Novaville

Documentation technique et fonctionnelle de la plateforme Novaville, construite avec [Docusaurus](https://docusaurus.io/).

## 🚀 Démarrage rapide

### Installation

```bash
cd docs
npm install
```

### Développement local

```bash
npm start
```

Cette commande démarre un serveur de développement local et ouvre une fenêtre de navigateur. La plupart des modifications sont reflétées en direct sans avoir à redémarrer le serveur.

La documentation sera accessible sur : http://localhost:3000

### Build

```bash
npm run build
```

Cette commande génère le contenu statique dans le répertoire `build` qui peut être servi par n'importe quel service d'hébergement de contenu statique.

### Aperçu du build

```bash
npm run serve
```

Permet de prévisualiser localement la version build de la documentation.

## 📁 Structure

```
docs/
├── blog/                       # Articles de blog (notes de version)
├── docs/                       # Documentation principale
│   ├── getting-started/       # Guide de démarrage
│   ├── technical/             # Documentation technique
│   ├── api/                   # Documentation API
│   └── user-manual/           # Manuel utilisateur
├── src/                       # Code source personnalisé
│   ├── components/            # Composants React personnalisés
│   ├── css/                   # Styles personnalisés
│   └── pages/                 # Pages personnalisées
├── static/                    # Fichiers statiques (images, etc.)
│   └── img/                   # Images
├── docusaurus.config.js       # Configuration Docusaurus
├── sidebars.js                # Configuration des sidebars
└── package.json               # Dépendances

```

## ✍️ Contribuer à la documentation

### Ajouter une nouvelle page

1. Créez un nouveau fichier Markdown dans le dossier approprié sous `docs/`
2. Ajoutez le front matter YAML en haut du fichier :

```markdown
---
sidebar_position: 1
title: Mon titre
---

# Mon titre

Contenu de la page...
```

3. Mettez à jour `sidebars.js` si nécessaire pour inclure la nouvelle page dans la navigation

### Ajouter des images

1. Placez les images dans `static/img/`
2. Référencez-les dans votre Markdown :

```markdown
![Description](/img/mon-image.png)
```

### Ajouter une note de version

1. Créez un nouveau fichier dans `blog/` avec le format : `YYYY-MM-DD-titre.md`
2. Ajoutez le front matter :

```markdown
---
slug: version-1-2-0
title: Version 1.2.0
authors: [votre-nom]
tags: [release, backend, frontend]
---

Description de la version...
```

## 🎨 Personnalisation

### Thème et couleurs

Modifiez `src/css/custom.css` pour personnaliser les couleurs et le style.

### Configuration

Modifiez `docusaurus.config.js` pour :
- Changer le titre et le tagline
- Configurer l'URL de déploiement
- Ajouter des plugins
- Personnaliser la navbar et le footer

## 🌍 Internationalisation

La documentation supporte le français (par défaut) et l'anglais.

### Ajouter une traduction

```bash
npm run write-translations -- --locale en
```

Puis traduisez les fichiers dans `i18n/en/`.

### Construire pour une locale spécifique

```bash
npm run build -- --locale en
```

## 🚀 Déploiement

### GitHub Pages (automatique)

La documentation est automatiquement déployée sur GitHub Pages à chaque push sur la branche `main` qui modifie le dossier `docs/`.

Le workflow GitHub Actions se trouve dans `.github/workflows/deploy-docs.yml`.

### Déploiement manuel

```bash
npm run build
# Puis déployez le contenu du dossier build/ sur votre serveur
```

## 📝 Configuration GitHub Pages

Pour configurer GitHub Pages dans votre dépôt :

1. Allez dans **Settings** > **Pages**
2. Sous **Build and deployment** :
   - Source : GitHub Actions
3. Le workflow s'exécutera automatiquement

### Mettre à jour l'URL

N'oubliez pas de remplacer dans `docusaurus.config.js` :

```javascript
url: 'https://YOUR_GITHUB_USERNAME.github.io',
baseUrl: '/Novaville/',
organizationName: 'YOUR_GITHUB_USERNAME',
projectName: 'Novaville',
```

## 🔧 Commandes utiles

```bash
# Installer les dépendances
npm install

# Démarrer en développement
npm start

# Build pour la production
npm run build

# Prévisualiser le build
npm run serve

# Nettoyer le cache
npm run clear

# Vérifier les liens brisés
npm run build && npx broken-link-checker http://localhost:3000

# Formater le code
npm run format

# Linter
npm run lint
```

## 📚 Ressources

- [Documentation Docusaurus](https://docusaurus.io/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Docusaurus GitHub](https://github.com/facebook/docusaurus)

## 🆘 Support

Pour toute question ou problème :

1. Consultez la [documentation Docusaurus](https://docusaurus.io/docs)
2. Ouvrez une issue sur [GitHub](https://github.com/YOUR_GITHUB_USERNAME/Novaville/issues)

## 📄 Licence

Cette documentation est sous licence [LICENSE](../LICENSE).
