---
sidebar_position: 3
---

# Guides internes (pour reprise par une autre équipe)

Ce document regroupe les procédures et documents internes destinés à permettre à une nouvelle équipe de reprendre le développement, apporter des évolutions et déployer l'application pour un nouveau client.

## 1) Procédure d'installation et d'initialisation de l'environnement de développement

Prérequis : `git`, `docker`, `docker compose`, `node`, `npm`, `flutter` (optionnel pour frontend).

Étapes rapides :

1. Cloner le dépôt :

```bash
git clone https://github.com/Michael16b/Novaville.git
cd Novaville
```

2. Copier les variables d'environnement et adapter :

```bash
cp .env.example .env
# Modifier .env avec les credentials locaux
```

3. Lancer les services :

```bash
docker compose up -d --build
```

4. Lancer les migrations et créer un superuser :

```bash
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py createsuperuser
```

5. Vérifier endpoints : `http://localhost:8000/api/`, `http://localhost:8000/admin`.

Notes pratiques : conserver un fichier `dev-setup.md` dans `docs/` si vous automatisez davantage.

## 2) Document "Premiers pas pour modifier le code"

Objectif : guider le développeur sur les premières modifications à apporter, par exemple changer l'ergonomie de la page d'accueil.

Exemple : modifier le texte et le bouton sur la page d'accueil de la doc (frontend Docusaurus) — étapes similaires pour le frontend Flutter :

- Localiser le composant : `docs/src/pages/index.tsx` (doc) ou `frontend/lib/main.dart` (app mobile/web).
- Modifier le texte et les liens.
- Tester en local : `npm start` (docs) ou `flutter run -d chrome` (frontend web).
- Soumettre une PR avec description et tests si nécessaire.

Checklist rapide pour une modification UI :

- Lancer le serveur local et vérifier comportement
- Garder les commits atomiques
- Mettre à jour les snapshots/tests UI si applicables
- Ajouter une ligne dans le changelog si le changement est visible par l'utilisateur

## 3) Exemple concret — modifier la première page (mini-tutoriel)

1. Ouvrir `frontend/lib/main.dart` ou `docs/src/pages/index.tsx` selon la cible.
2. Rechercher le composant correspondant (ex. `HomepageHeader`).
3. Modifier le texte et recompiler : `flutter run` ou `npm start`.
4. Valider sur plusieurs résolutions et plateformes si possible.

## 4) Procédure de déploiement pour un nouveau client

Objectif : déployer l'application pour un client avec son propre domaine et variables d'environnement.

1. Préparer l'infrastructure (Azure / serveur cible) :
   - Créer les ressources (App Service / Container Registry / Database)
   - Configurer le réseau et les règles (NSG, firewalls)

2. Préparer les secrets et variables d'environnement :
   - Générer `SECRET_KEY`
   - Configurer les credentials DB, SMTP, clés tierces

3. Construire les images et pousser vers le registre :

```bash
docker build -t myregistry/novaville-backend:latest -f backend/Dockerfile .
docker build -t myregistry/novaville-frontend:latest -f frontend/Dockerfile .
docker push myregistry/novaville-backend:latest
docker push myregistry/novaville-frontend:latest
```

4. Déployer via orchestration (az cli / terraform / docker compose selon l'environnement) :

```bash
# Exemple : déployer via docker-compose sur un VM
docker compose -f docker-compose-prod.yml up -d
```

5. Appliquer les migrations et tâches post-déploiement :

```bash
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py collectstatic --noinput
```

6. Configurer le TLS (Let's Encrypt / certificat fourni par le client) et vérifier `ALLOWED_HOSTS`.

7. Effectuer tests smoke et vérifier monitoring (health endpoints, logs, alertes).

## 5) Documents à joindre au dépôt (recommandés)

- `docs/technical/internal-guides.md` (ce fichier)
- `docs/dev-setup.md` : script et étapes d'initialisation détaillées
- `docs/change-process.md` : guide PR / code-review / release
- `docs/deploy-playbook.md` : playbook pas-à-pas pour déploiement chez un client

---

Si tu veux, je peux générer directement `dev-setup.md` et `deploy-playbook.md` détaillés et préparer un commit/PR. Indique-moi lequel prioriser.
