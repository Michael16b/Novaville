---
sidebar_position: 3
---

# Update User

Update a user profile.

## Endpoint

```http
PATCH /api/v1/users/{id}/
PUT   /api/v1/users/{id}/
```

## Authentication

- Required: `Authorization: Bearer <access_token>`
- Users can update their own profile.
- Admins can update any user.

## Request body (partial)

| Field | Type | Description |
|-------|------|-------------|
| `first_name` | string | Update first name |
| `last_name` | string | Update last name |
| `email` | string | Update email |
| `password` | string | Update password (hashed server-side) |
| `neighborhood` | integer | Update neighborhood id |
| `role` | string | Admin only; ignored for regular users |
| `is_active` | boolean | Admin only |

### Example (self-update)

```http
PATCH /api/v1/users/1/
Content-Type: application/json
Authorization: Bearer <access_token>

{
  "first_name": "Updated",
  "password": "NewPassword123"
}
```

### Responses

- **200 OK** — Update applied; password is not echoed back.
- **403 Forbidden** — Attempt to update another user without admin rights.

## Notes

- Passwords are validated and hashed before storage.
- Non-admin users cannot elevate their role.