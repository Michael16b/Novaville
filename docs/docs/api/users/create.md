---
sidebar_position: 2
---

# Créer un utilisateur

Inscrire un nouvel utilisateur.

## Endpoint

```http
POST /api/v1/users/
```

## Authentification

- Non requise (inscription publique).

## Corps de requête

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `username` | string | ✅ | Nom d'utilisateur unique |
| `email` | string | ✅ | Adresse email |
| `password` | string | ✅ | Mot de passe (validé et hashé côté serveur) |
| `first_name` | string | ❌ | Prénom |
| `last_name` | string | ❌ | Nom |
| `neighborhood` | integer | ❌ | Identifiant du quartier |
| `role` | string | ❌ | Ignoré pour les non-admin ; défaut `citizen` |

### Exemple

```json
{
  "username": "newuser",
  "email": "newuser@test.com",
  "password": "NewPass123",
  "first_name": "New",
  "last_name": "User",
  "neighborhood": 1
}
```

## Réponse

### Succès (201 Created)

```json
{
  "id": 7,
  "username": "newuser",
  "email": "newuser@test.com",
  "first_name": "New",
  "last_name": "User",
  "role": "citizen",
  "neighborhood": 1,
  "date_joined": "2024-01-15T10:30:00Z"
}
```

### Erreur (400 Bad Request)

Retourne une erreur en cas d'email invalide, doublon de username, mot de passe faible ou champ manquant.

## Notes

- Les mots de passe ne sont jamais retournés dans les réponses.
- Le rôle reste `citizen` sauf si la requête vient d'un admin.