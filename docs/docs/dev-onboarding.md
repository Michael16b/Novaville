---
sidebar_position: 4
---

# Onboarding Développeurs

Ce document vise à permettre à une nouvelle équipe de développement de reprendre rapidement le projet Novaville : comprendre l'architecture, exécuter le code localement, lancer les tests et contribuer en toute sécurité.

## Objectifs

- Présenter l'architecture globale
- Décrire le flux de développement local (setup, services, variables d'environnement)
- Expliquer comment exécuter la suite de tests
- Indiquer les points d'attention pour la production et le déploiement

## Structure du dépôt

Les dossiers principaux :

- `backend/` : API Django REST
- `frontend/` : Application Flutter (mobile/web)
- `docs/` : Documentation (Docusaurus)
- `docker-compose.yml` et `docker-compose-azure.yml` : définitions d'environnement

## Pré-requis

- Docker & Docker Compose
- Node.js (pour la doc) et npm
- Flutter SDK (si vous travaillez sur le frontend)

## Démarrage local (rapide)

1. Copier les variables d'environnement depuis `.env.example` et adapter.
2. Lancer les services :

```bash
docker compose up -d --build
```

3. API disponible sur `http://localhost:8000`, Frontend sur `http://localhost:80`.

## Exécuter les tests backend

```bash
docker compose exec backend pytest
```

## Débogage et points d'attention

- `DJANGO_SECRET_KEY` et autres secrets ne doivent jamais être committés
- Vérifier les migrations après modification des modèles
- Les intégrations externes et variables de production sont définies dans `docker-compose-azure.yml` et la documentation d'infra

## Où chercher plus d'information

- Architecture détaillée : [Documentation technique](../docs/technical/architecture)
- API : [Documentation API](../docs/api/overview)
- CI/CD et déploiement : voir les workflows GitHub Actions et `docs/DOCUMENTATION_README.md`

---
Si vous voulez, je peux ajouter un script d'initialisation ou un guide pas-à-pas plus détaillé.
