# 📘 Guide des Makefiles Novaville

## Vue d'ensemble

Le projet Novaville dispose de 3 Makefiles pour faciliter le développement :

- **Makefile racine** : Orchestration Docker et commandes globales
- **frontend/Makefile** : Commandes spécifiques Flutter/Dart
- **backend/Makefile** : Commandes spécifiques Django/Python

---

## 🚀 Makefile Racine (Orchestration)

### Commandes Docker

```bash
make up              # Lance toute l'application (backend + frontend)
make down            # Arrête toute l'application
make restart         # Redémarre toute l'application
make ps              # Affiche l'état des conteneurs
```

### Build

```bash
make build           # Build toutes les images sans cache
make build-backend   # Build uniquement le backend
make build-frontend  # Build uniquement le frontend
```

### Logs

```bash
make logs            # Affiche les logs de tous les conteneurs
make logs-backend    # Logs du backend uniquement
make logs-frontend   # Logs du frontend uniquement
```

### Code Quality (Global)

```bash
make fix             # Formate et corrige frontend + backend
make lint            # Analyse le code (frontend + backend)
make test            # Lance tous les tests
```

### Accès aux sous-Makefiles

```bash
make frontend        # Affiche les commandes Flutter disponibles
make backend         # Affiche les commandes Django disponibles

# Exécuter une commande spécifique
make frontend format # Formate le code Flutter
make backend migrate # Lance les migrations Django
```

---

## 📱 Frontend Makefile (Flutter/Dart)

**Accès :** `make frontend <commande>` ou `cd frontend && make <commande>`

### Formatage & Qualité

```bash
make frontend format    # Formate le code Dart
make frontend fix       # Applique les corrections automatiques
make frontend analyze   # Analyse le code Flutter
make frontend lint      # Alias pour analyze
```

### Tests

```bash
make frontend test           # Lance les tests
make frontend test-coverage  # Tests avec couverture
make frontend watch          # Mode watch pour les tests
```

### Build

```bash
make frontend build-web  # Build pour le web
make frontend build-apk  # Build APK Android
make frontend build-ios  # Build iOS
```

### Développement

```bash
make frontend run       # Lance l'app en debug
make frontend run-web   # Lance l'app web
make frontend pub-get   # Récupère les dépendances
```

### BLoC

```bash
make frontend bloc-create name=MyFeature
# Crée la structure BLoC dans lib/blocs/myfeature/
```

### Maintenance

```bash
make frontend clean          # Nettoie les builds
make frontend doctor         # Vérifie l'installation Flutter
make frontend upgrade-flutter # Met à jour Flutter
```

---

## 🐍 Backend Makefile (Django/Python)

**Accès :** `make backend <commande>` ou `cd backend && make <commande>`

### Formatage & Qualité

```bash
make backend format  # Formate avec black + isort
make backend fix     # Corrections automatiques
make backend lint    # Analyse avec flake8 + pylint
```

### Tests

```bash
make backend test           # Lance les tests Django
make backend test-coverage  # Tests avec couverture
```

### Base de données

```bash
make backend migrate         # Applique les migrations
make backend makemigrations  # Crée de nouvelles migrations
make backend showmigrations  # Affiche l'état des migrations
```

### Développement

```bash
make backend runserver      # Lance le serveur de dev
make backend shell          # Shell Django
make backend dbshell        # Shell de la base de données
make backend check          # Vérifie le projet Django
```

### Administration

```bash
make backend createsuperuser  # Crée un superuser
make backend collectstatic    # Collecte les fichiers statiques
```

### Dépendances

```bash
make backend install      # Installe les dépendances
make backend install-dev  # Installe les outils de dev
make backend freeze       # Génère requirements.txt
```

### Maintenance

```bash
make backend clean  # Nettoie les fichiers Python compilés
```

---

## 💡 Exemples d'utilisation

### Workflow de développement typique

```bash
# 1. Démarrer l'application
make up

# 2. Vérifier que tout tourne
make ps

# 3. Travailler sur le frontend
make frontend run-web

# 4. Formater le code avant commit
make fix

# 5. Lancer les tests
make test

# 6. Arrêter l'application
make down
```

### Créer un nouveau feature (BLoC)

```bash
# Créer la structure BLoC
make frontend bloc-create name=UserProfile

# Formater le code généré
make frontend format

# Analyser le code
make frontend analyze
```

### Migrations Django

```bash
# Créer les migrations
make backend makemigrations

# Les appliquer dans le conteneur Docker
make migrate
```

### Debugging

```bash
# Voir les logs en temps réel
make logs

# Accéder au shell du backend
make shell-backend

# Accéder au shell Python Django
make backend shell
```

---

## 🛠️ Installation des outils de développement

### Pour le backend (Python)

```bash
make install-dev-tools
# Installe: black, isort, flake8, autoflake

# Ou depuis le backend :
make backend install-dev
# Installe aussi: pylint, coverage, pytest
```

### Pour le frontend (Flutter)

Les outils sont inclus avec Flutter SDK (dart format, flutter analyze, etc.)

---

## 📋 Commandes rapides

```bash
make help              # Aide générale
make frontend          # Aide frontend
make backend           # Aide backend

make up                # Démarrer
make down              # Arrêter
make restart           # Redémarrer

make fix               # Tout formater
make lint              # Tout analyser
make test              # Tout tester

make logs              # Voir les logs
make ps                # État des conteneurs
```

---

## 🎯 Best Practices

1. **Toujours formater avant de commit** : `make fix`
2. **Analyser le code régulièrement** : `make lint`
3. **Lancer les tests** : `make test`
4. **Vérifier les logs en cas d'erreur** : `make logs`
5. **Utiliser les sous-Makefiles pour des commandes spécifiques**

---

## 🆘 Troubleshooting

### Le backend ne démarre pas

```bash
make logs-backend
# Vérifier les erreurs de connexion DB

make down
make up
```

### Le frontend ne build pas

```bash
make frontend clean
make frontend pub-get
make build-frontend
```

### Erreurs de formatage

```bash
# Installer les outils manquants
make install-dev-tools
make backend install-dev
```

---

**Pour plus d'aide, utilisez `make help` ou `make <frontend|backend>`**