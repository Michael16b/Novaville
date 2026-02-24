---
sidebar_position: 1
---

# List Users

List users in the directory.

## Endpoint

```http
GET /api/v1/users/
```

## Authentication

- Required: `Authorization: Bearer <access_token>`
- Any authenticated user can call this endpoint.
- Staff/admin accounts may see more fields; everyone sees the public directory.

## Query parameters

- `page`: Page number (default `1`)
- `page_size`: Items per page (default `25`, max `100`)

## Response

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

## Related endpoint

- `GET /api/v1/users/me/` — returns the currently authenticated user profile.