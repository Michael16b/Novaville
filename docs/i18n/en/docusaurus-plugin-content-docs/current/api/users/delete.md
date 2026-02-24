---
sidebar_position: 4
---

# Delete User

Delete a user account (admin only).

## Endpoint

```http
DELETE /api/v1/users/{id}/
```

## Authentication

- Required: `Authorization: Bearer <access_token>`
- Admin only.

## Response

- **204 No Content** — User deleted.
- **403 Forbidden** — Caller is not an admin.
- **404 Not Found** — User id does not exist.

## Notes

- Deleting a user is irreversible; ensure the account should be removed.