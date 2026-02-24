---
sidebar_position: 4
---

# Supprimer un utilisateur

Supprimer un compte utilisateur (admin uniquement).

## Endpoint

```http
DELETE /api/v1/users/{id}/
```

## Authentification

- Requise : `Authorization: Bearer <access_token>`
- Admin uniquement.

## Réponse

- **204 No Content** — Utilisateur supprimé.
- **403 Forbidden** — L'appelant n'est pas admin.
- **404 Not Found** — Identifiant inexistant.

## Notes

- La suppression est définitive : confirmer avant de supprimer un compte.