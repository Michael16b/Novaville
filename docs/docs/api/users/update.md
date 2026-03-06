---
sidebar_position: 3
---

# Mettre à jour un utilisateur

Mettre à jour le profil d'un utilisateur.

## Endpoint

```http
PATCH /api/v1/users/{id}/
PUT   /api/v1/users/{id}/
```

## Authentification

- Requise : `Authorization: Bearer <access_token>`
- Les utilisateurs peuvent modifier leur propre profil.
- Les admins peuvent modifier n'importe quel utilisateur.

## Corps de requête (partiel)

| Champ | Type | Description |
|-------|------|-------------|
| `first_name` | string | Mettre à jour le prénom |
| `last_name` | string | Mettre à jour le nom |
| `email` | string | Mettre à jour l'email |
| `password` | string | Mettre à jour le mot de passe (hashé côté serveur) |
| `neighborhood` | integer | Mettre à jour le quartier |
| `role` | string | Admin uniquement ; ignoré pour les utilisateurs classiques |
| `is_active` | boolean | Admin uniquement |

### Exemple (auto-mise à jour)

```http
PATCH /api/v1/users/1/
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "first_name": "MisAJour",
  "password": "NewPassword123"
}
```

### Réponses

- **200 OK** — Mise à jour appliquée ; le mot de passe n'est jamais renvoyé.
- **403 Forbidden** — Tentative de modifier un autre utilisateur sans droit admin.

## Notes

- Les mots de passe sont validés et hashés.
- Les utilisateurs non-admin ne peuvent pas changer leur rôle.