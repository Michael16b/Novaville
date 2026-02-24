---
sidebar_position: 1
---

# Liste des utilisateurs

Lister les utilisateurs de l'annuaire.

## Endpoint

```http
GET /api/v1/users/
```

## Authentification

- Requise : `Authorization: Bearer <access_token>`
- Tout utilisateur authentifié peut appeler cet endpoint.
- Les comptes staff/admin peuvent voir plus d'informations.

## Paramètres de query

- `page` : Numéro de page (défaut `1`)
- `page_size` : Nombre d'éléments par page (défaut `25`, max `100`)

## Réponse

```json
{
  "count": 42,
  "next": "https://api.novaville.com/api/v1/users/?page=3",
  "previous": null,
  "results": [
    {
      "id": 1,
      "username": "citizen1",
      "first_name": "Jane",
      "last_name": "Doe",
      "role": "citizen"
    },
    {
      "id": 2,
      "username": "agent1",
      "first_name": "Alex",
      "last_name": "Smith",
      "role": "agent"
    }
  ]
}
```

## Endpoint lié

- `GET /api/v1/users/me/` — retourne le profil de l'utilisateur authentifié.