# Guide d'internationalisation (i18n)

Ce guide explique comment gérer les traductions de la documentation Novaville pour différentes langues.

## 🌍 Langues supportées

Par défaut, la documentation supporte :
- **Français (fr)** - Langue par défaut
- **Anglais (en)** - Langue secondaire

D'autres langues peuvent être facilement ajoutées.

## 📁 Structure des traductions

```
docs/
├── docs/                      # Documentation en français (défaut)
│   ├── intro.md
│   ├── getting-started/
│   └── ...
├── i18n/                      # Traductions
│   ├── en/                    # Anglais
│   │   ├── docusaurus-plugin-content-docs/
│   │   │   └── current/       # Docs traduites
│   │   │       ├── intro.md
│   │   │       └── ...
│   │   ├── docusaurus-plugin-content-blog/
│   │   │   └── ...            # Blog traduit
│   │   └── docusaurus-theme-classic/
│   │       └── navbar.json    # Navigation traduite
│   └── [autre-langue]/
│       └── ...
├── docusaurus.config.js       # Configuration i18n
└── sidebars.js                # Structure (partagée)
```

## 🚀 Démarrage rapide

### 1. Initialiser les traductions pour une langue

```bash
cd docs

# Générer les fichiers de traduction pour l'anglais
npm run write-translations -- --locale en

# Créer les fichiers markdown à traduire
mkdir -p i18n/en/docusaurus-plugin-content-docs/current
cp -r docs/* i18n/en/docusaurus-plugin-content-docs/current/
```

### 2. Traduire les fichiers

Traduisez manuellement les fichiers dans `i18n/en/docusaurus-plugin-content-docs/current/`

**Important** : Conservez la même structure de dossiers et les mêmes noms de fichiers.

### 3. Tester la traduction localement

```bash
# Démarrer avec la locale anglaise
npm run start -- --locale en

# Build pour une locale spécifique
npm run build -- --locale en
```

### 4. Build multi-langue

Pour construire toutes les langues :

```bash
npm run build
```

Cela génère :
- `/build/fr/` - Version française (défaut accessible à `/`)
- `/build/en/` - Version anglaise

## 📝 Éléments à traduire

### 1. Pages de documentation (Markdown)

**Emplacement** : `i18n/[locale]/docusaurus-plugin-content-docs/current/`

Traduisez tout le contenu markdown, incluant :
- Titres et textes
- Exemples de code (commentaires)
- Messages d'erreur dans les exemples

**Exemple** : `docs/intro.md` → `i18n/en/docusaurus-plugin-content-docs/current/intro.md`

```markdown
---
sidebar_position: 1
slug: /
---

# Welcome to Novaville Documentation

Welcome to the complete documentation of **Novaville**...
```

### 2. Navigation et UI

**Emplacement** : `i18n/[locale]/docusaurus-theme-classic/`

Fichiers JSON générés automatiquement par :

```bash
npm run write-translations -- --locale en
```

**Fichiers principaux** :
- `navbar.json` - Menu de navigation
- `footer.json` - Pied de page
- `docs.json` - Labels des docs

**Exemple** : `i18n/en/docusaurus-theme-classic/navbar.json`

```json
{
  "title": {
    "message": "Novaville",
    "description": "The title in the navbar"
  },
  "item.label.Documentation": {
    "message": "Documentation",
    "description": "Navbar item"
  }
}
```

### 3. Articles de blog

**Emplacement** : `i18n/[locale]/docusaurus-plugin-content-blog/`

Copiez et traduisez les articles :

```bash
cp -r blog/* i18n/en/docusaurus-plugin-content-blog/
```

## 🔧 Configuration avancée

### Ajouter une nouvelle langue

#### 1. Modifier `docusaurus.config.js`

```javascript
i18n: {
  defaultLocale: 'fr',
  locales: ['fr', 'en', 'es'], // Ajouter 'es' pour l'espagnol
  localeConfigs: {
    fr: {
      label: 'Français',
      direction: 'ltr',
      htmlLang: 'fr-FR',
    },
    en: {
      label: 'English',
      direction: 'ltr',
      htmlLang: 'en-US',
    },
    es: {
      label: 'Español',
      direction: 'ltr',
      htmlLang: 'es-ES',
    },
  },
},
```

#### 2. Initialiser la traduction

```bash
npm run write-translations -- --locale es
mkdir -p i18n/es/docusaurus-plugin-content-docs/current
```

#### 3. Ajouter le sélecteur de langue dans la navbar

C'est déjà configuré avec `type: 'localeDropdown'` dans la navbar.

### Langues RTL (Arabe, Hébreu)

Pour les langues de droite à gauche :

```javascript
ar: {
  label: 'العربية',
  direction: 'rtl',
  htmlLang: 'ar',
},
```

## 🎯 Workflow de traduction recommandé

### Option 1 : Traduction manuelle

1. Copier les fichiers sources
2. Traduire manuellement chaque fichier
3. Vérifier localement
4. Commit

**Avantages** : Contrôle total, qualité
**Inconvénients** : Temps, maintenance

### Option 2 : Traduction semi-automatique

1. Utiliser un outil de traduction (DeepL, Google Translate) pour une première passe
2. Réviser et corriger manuellement
3. Vérifier la cohérence terminologique
4. Commit

**Avantages** : Plus rapide
**Inconvénients** : Nécessite révision

### Option 3 : CrowdIn (Plateforme collaborative)

Pour les projets open source, utilisez [Crowdin](https://crowdin.com/) :

1. Créer un projet Crowdin
2. Connecter le dépôt GitHub
3. Les contributeurs traduisent via l'interface web
4. Sync automatique avec le dépôt

## 📋 Checklist par langue

Pour chaque nouvelle langue :

- [ ] Ajouter la locale dans `docusaurus.config.js`
- [ ] Générer les fichiers de traduction (`write-translations`)
- [ ] Traduire les pages de documentation principales
- [ ] Traduire les éléments de navigation (navbar, footer)
- [ ] Traduire au moins 1 article de blog
- [ ] Tester localement (`npm start -- --locale xx`)
- [ ] Vérifier tous les liens internes
- [ ] Build et vérifier (`npm run build`)
- [ ] Documenter la langue dans le README

## 🔍 Vérification et qualité

### Tester une langue

```bash
# Démarrer uniquement en anglais
npm run start -- --locale en

# Build uniquement en anglais
npm run build -- --locale en

# Servir le build
npm run serve -- --locale en
```

### Vérifier les liens brisés

```bash
# Build toutes les langues
npm run build

# Vérifier les liens
npx broken-link-checker http://localhost:3000/Novaville/
```

### Bonnes pratiques

1. **Cohérence terminologique** : Créez un glossaire des termes techniques
2. **Mise à jour** : Gardez les traductions synchronisées avec le contenu français
3. **Révision** : Faites relire par un natif si possible
4. **Exemples de code** : Traduisez les commentaires, pas le code
5. **URLs** : Les slugs peuvent rester en anglais pour la cohérence

## 🌐 Sélecteur de langue

### Dans la navbar (déjà configuré)

```javascript
items: [
  // ... autres items
  {
    type: 'localeDropdown',
    position: 'right',
  },
]
```

### Personnaliser le sélecteur

```javascript
{
  type: 'localeDropdown',
  position: 'right',
  dropdownItemsAfter: [
    {
      type: 'html',
      value: '<hr style="margin: 0.3rem 0;">',
    },
    {
      href: 'https://github.com/YOUR_USERNAME/Novaville/issues/new',
      label: 'Proposer une traduction',
    },
  ],
}
```

## 📊 Statut des traductions

### Français (fr) - Défaut
- ✅ Pages principales
- ✅ Documentation technique
- ✅ API
- ✅ Manuel utilisateur
- ✅ Blog

### Anglais (en)
- ⏳ À traduire
- 🎯 Priorité : Pages principales, API

### Autres langues
- ⬜ Non démarrées

## 🚀 Déploiement multi-langue

### GitHub Pages (automatique)

Le workflow GitHub Actions build automatiquement toutes les langues :

```yaml
- name: Build documentation
  run: npm run build
  # Build toutes les locales configurées
```

### Docker

Le Dockerfile build également toutes les langues :

```dockerfile
RUN npm run build
# Génère /app/build/ avec tous les dossiers de langues
```

### Languages disponibles

Les langues sont accessibles via :
- `https://your-domain.github.io/Novaville/` - Français (défaut)
- `https://your-domain.github.io/Novaville/en/` - Anglais
- `https://your-domain.github.io/Novaville/es/` - Espagnol (si ajouté)

## 💡 Astuces

### Utiliser des variables pour les termes répétés

Créez un fichier `src/constants/translations.js` :

```javascript
export const translations = {
  fr: {
    appName: 'Novaville',
    slogan: 'Plateforme citoyenne intelligente',
  },
  en: {
    appName: 'Novaville',
    slogan: 'Smart citizen platform',
  },
};
```

### Traductions partielles

Vous pouvez avoir des traductions partielles. Les pages non traduites afficheront un bandeau "Cette page n'est pas encore traduite".

### Fallback

Si une traduction n'existe pas, Docusaurus utilise la langue par défaut (français).

## 📚 Ressources

- [Documentation i18n Docusaurus](https://docusaurus.io/docs/i18n/introduction)
- [Tutoriel i18n Docusaurus](https://docusaurus.io/docs/i18n/tutorial)
- [DeepL](https://www.deepl.com/) - Outil de traduction de qualité
- [Crowdin](https://crowdin.com/) - Plateforme de traduction collaborative

## 🆘 Support

Pour toute question sur les traductions :
- Consultez la [documentation Docusaurus i18n](https://docusaurus.io/docs/i18n/introduction)
- Ouvrez une issue sur GitHub
- Contactez l'équipe de documentation

---

**Merci de contribuer aux traductions de Novaville !** 🌍
