---
sidebar_position: 1
---

# Aperçu de l'API

L'API REST de Novaville permet d'interagir avec la plateforme de manière programmatique.

## URL de base

- **Développement** : `http://localhost:8000/api/v1/`
- **Production** : `https://api.novaville.com/api/v1/`

## Authentification

L'API utilise **JWT (JSON Web Tokens)** pour l'authentification.

### Obtenir un token

```http
POST /api/v1/auth/login/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "votre_mot_de_passe"
}
```

**Réponse :**

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "Jean",
    "last_name": "Dupont",
    "role": "citizen"
  }
}
```

### Utiliser le token

Incluez le token d'accès dans l'en-tête `Authorization` de chaque requête :

```http
GET /api/v1/events/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

### Rafraîchir le token

Les tokens d'accès expirent après 60 minutes. Utilisez le token de rafraîchissement pour en obtenir un nouveau :

```http
POST /api/v1/auth/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Réponse :**

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

## Format des réponses

### Succès

```json
{
  "data": { /* votre données */ },
  "message": "Succès",
  "status": 200
}
```

### Liste paginée

```json
{
  "count": 42,
  "next": "http://api.example.org/accounts/?page=3",
  "previous": "http://api.example.org/accounts/?page=1",
  "results": [
    { /* objet 1 */ },
    { /* objet 2 */ }
  ]
}
```

### Erreur

```json
{
  "error": {
    "code": "validation_error",
    "message": "Les données fournies sont invalides",
    "details": {
      "email": ["Ce champ est requis."]
    }
  },
  "status": 400
}
```

## Codes de statut HTTP

| Code | Signification | Description |
|------|--------------|-------------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée avec succès |
| 204 | No Content | Requête réussie, pas de contenu à retourner |
| 400 | Bad Request | Données invalides |
| 401 | Unauthorized | Non authentifié |
| 403 | Forbidden | Non autorisé |
| 404 | Not Found | Ressource introuvable |
| 500 | Internal Server Error | Erreur serveur |

## Pagination

Les listes sont paginées par défaut (25 éléments par page).

### Paramètres de pagination

- `page` : Numéro de page (défaut: 1)
- `page_size` : Nombre d'éléments par page (max: 100)

**Exemple :**

```http
GET /api/v1/events/?page=2&page_size=50
```

## Filtrage

Utilisez des paramètres de query pour filtrer les résultats.

**Exemple :**

```http
GET /api/v1/reports/?status=open&category=infrastructure
```

## Tri

Utilisez le paramètre `ordering` pour trier les résultats.

**Exemple :**

```http
GET /api/v1/events/?ordering=-created_at  # Décroissant
GET /api/v1/events/?ordering=title        # Croissant
```

## Recherche

Utilisez le paramètre `search` pour effectuer une recherche textuelle.

**Exemple :**

```http
GET /api/v1/reports/?search=nid-de-poule
```

## Limites de taux (Rate Limiting)

- **Authentifié** : 1000 requêtes/heure
- **Non authentifié** : 100 requêtes/heure

Les limites sont indiquées dans les en-têtes de réponse :

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Ressources principales

### Authentification
- [Login](./auth/login) - Authentification utilisateur
- [Refresh Token](./auth/refresh-token) - Rafraîchissement du token

### Utilisateurs
- [Liste des utilisateurs](./users/list)
- [Créer un utilisateur](./users/create)
- [Modifier un utilisateur](./users/update)
- [Supprimer un utilisateur](./users/delete)

### Événements
- [Liste des événements](./events/list)
- [Créer un événement](./events/create)
- [Modifier un événement](./events/update)
- [Supprimer un événement](./events/delete)

### Rapports
- [Liste des rapports](./reports/list)
- [Créer un rapport](./reports/create)
- [Modifier un rapport](./reports/update)
- [Supprimer un rapport](./reports/delete)

## Versions de l'API

L'API est versionnée dans l'URL. La version actuelle est **v1**.

- `/api/v1/` - Version actuelle (stable)

Les anciennes versions seront maintenues pendant au moins 12 mois après la sortie d'une nouvelle version majeure.

## Support

Pour toute question ou problème avec l'API :

1. Consultez la documentation complète
2. Vérifiez les [exemples de code](https://github.com/Michael16b/Novaville/tree/main/examples)
3. Ouvrez une issue sur [GitHub](https://github.com/YOUR_GITHUBMichael16b_USERNAME/Novaville/issues)

## Outils recommandés

- **Postman** : [Collection Postman](https://www.postman.com/)
- **Bruno** : Voir `/api/Novaville/` pour les requêtes pré-configurées
- **curl** : Exemples fournis dans chaque endpoint

## Changelog

Consultez les [Notes de version](/blog) pour voir les dernières modifications de l'API.
