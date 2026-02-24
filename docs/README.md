# 📚 Documentation Novaville

Documentation complète de la plateforme Novaville, construite avec [Docusaurus](https://docusaurus.io/).

## 🚀 Démarrage rapide

### Avec npm (Développement)

```bash
# Installer les dépendances
npm install

# Lancer le serveur de développement
npm start
```

La documentation sera accessible sur : **http://localhost:3000**

### Avec Docker (Production)

```bash
# Lancer avec Docker Compose
docker-compose up -d

# Ou depuis la racine du projet
docker-compose --profile docs up -d
```

La documentation sera accessible sur : **http://localhost:3000**

## 📖 À propos

Cette documentation couvre tous les aspects de Novaville :

- **📘 Guide de démarrage** - Installation et configuration
- **🔧 Documentation technique** - Architecture, backend, frontend
- **🌐 Documentation API** - Référence complète de l'API REST
- **📗 Manuel utilisateur** - Guide pour les utilisateurs finaux

## 🛠️ Développement

### Installation

### Installation

```bash
npm install
```

### Commandes disponibles

```bash
# Développement avec hot reload
npm start

# Build pour la production
npm run build

# Prévisualiser le build
npm run serve

# Nettoyer le cache
npm run clear

# Générer les traductions
npm run write-translations -- --locale en

# Vérifier les types TypeScript
npm run typecheck
```

## 🐳 Docker

### Docker Compose (Recommandé)

```bash
docker-compose up -d
```

### Docker manuel

```bash
# Build
docker build -t novaville-docs .

# Run
docker run -d -p 3000:80 novaville-docs
```

**Guide complet** : [DOCKER_GUIDE.md](DOCKER_GUIDE.md)

## 🌍 Internationalisation

### Langues supportées

- 🇫🇷 **Français (fr)** - Défaut
- 🇬🇧 **Anglais (en)** - Configuré

### Ajouter une traduction

```bash
# Générer les fichiers
npm run write-translations -- --locale en

# Créer la structure
mkdir -p i18n/en/docusaurus-plugin-content-docs/current

# Copier et traduire
cp -r docs/* i18n/en/docusaurus-plugin-content-docs/current/
```

### Tester avec une locale

```bash
npm run start -- --locale en
npm run build -- --locale en
```

**Guide complet** : [I18N_GUIDE.md](I18N_GUIDE.md)

## 📁 Structure

```
docs/
├── docs/                  # Contenu de la documentation (FR par défaut)
│   ├── intro.md
│   ├── getting-started/
│   ├── technical/
│   ├── api/
│   └── user-manual/
├── i18n/                  # Traductions
│   ├── en/               # Anglais
│   └── [locale]/         # Autres langues
├── blog/                  # Articles et notes de version
├── src/                   # Code source personnalisé
│   ├── components/       # Composants React
│   ├── css/              # Styles personnalisés
│   └── pages/            # Pages personnalisées
├── static/                # Fichiers statiques
│   └── img/              # Images
├── Dockerfile             # Image Docker
├── docker-compose.yml     # Orchestration Docker
├── nginx.conf            # Configuration nginx
├── docusaurus.config.js  # Configuration principale
└── sidebars.js           # Configuration des sidebars
```

## ✍️ Contribuer

### Ajouter une page

1. Créer un fichier `.md` dans `docs/`
2. Ajouter le front matter :

```markdown
---
sidebar_position: 1
title: Mon titre
---

# Mon titre

Contenu...
```

3. La page apparaît automatiquement dans la navigation

### Ajouter des images

```markdown
![Description](/img/mon-image.png)
```

Placez les images dans `static/img/`

### Ajouter un article de blog

Créer un fichier dans `blog/` : `YYYY-MM-DD-titre.md`

```markdown
---
slug: mon-article
title: Mon Article
authors: [novaville-team]
tags: [release]
---

Contenu...
```

## 🚀 Déploiement

### GitHub Pages (Automatique)

Le déploiement est automatique via GitHub Actions à chaque push sur `main` qui modifie le dossier `docs/`.

URL : `https://YOUR_GITHUB_USERNAME.github.io/Novaville/`

### Déploiement manuel

```bash
npm run build
# Déployer le contenu de build/ sur votre serveur
```

## 🔧 Configuration

### Modifier l'URL de déploiement

Dans `docusaurus.config.js` :

```javascript
url: 'https://YOUR_GITHUB_USERNAME.github.io',
baseUrl: '/Novaville/',
organizationName: 'YOUR_GITHUB_USERNAME',
projectName: 'Novaville',
```

### Personnaliser le thème

Modifiez `src/css/custom.css` :

```css
:root {
  --ifm-color-primary: #2e8555;
  /* ... */
}
```

## 📚 Guides complets

- [DOCUMENTATION_GUIDE.md](../DOCUMENTATION_GUIDE.md) - Guide complet d'utilisation
- [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Tout sur Docker
- [I18N_GUIDE.md](I18N_GUIDE.md) - Guide des traductions
- [TODO_DOCUMENTATION.md](TODO_DOCUMENTATION.md) - Fichiers à créer

## 🆘 Support

- [Documentation Docusaurus](https://docusaurus.io/)
- [Ouvrir une issue](https://github.com/YOUR_GITHUB_USERNAME/Novaville/issues)

## 📄 Licence

Même licence que le projet Novaville.

---

**Construit avec ❤️ en utilisant Docusaurus**

# 🚀 Quick Start - Documentation

## Launch in 30 seconds

```bash
cd Novaville
bash control-center.sh
# Choose option 1 (Start Documentation)
# Done! → http://localhost:3000
```

## What's inside?

- ✅ Professional documentation site
- ✅ Runs in Docker (production-ready)
- ✅ English by default
- ✅ Source: `docs/` folder

## Available Commands

### Using the menu (easiest)
```bash
bash control-center.sh
```

### Direct Docker
```bash
cd docs
docker-compose up -d
# Access: http://localhost:3000

docker-compose logs -f      # See logs
docker-compose down         # Stop
```

### Direct npm (dev mode)
```bash
cd docs
npm install
npm start           # http://localhost:3000 (hot reload)
```

## Need help?

- **Docker issues?** → See `docs/DOCKER_GUIDE.md`
- **Add content?** → Files in `docs/docs/`
- **Translations?** → See `docs/I18N_GUIDE.md`
- **General ?** → See `DOCUMENTATION_GUIDE.md`

## That's it! 

Documentation is live and ready to use. 📚

