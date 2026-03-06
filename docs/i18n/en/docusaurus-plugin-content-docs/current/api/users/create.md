---
sidebar_position: 2
---

# Create User

Register a new user account.

## Endpoint

```http
POST /api/v1/users/
```

## Authentication

- Not required (public registration).

## Request body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `username` | string | ✅ | Unique username |
| `email` | string | ✅ | Email address |
| `password` | string | ✅ | Password (validated, hashed server-side) |
| `first_name` | string | ❌ | First name |
| `last_name` | string | ❌ | Last name |
| `neighborhood` | integer | ❌ | Neighborhood id |
| `role` | string | ❌ | Ignored for non-admin; defaults to `citizen` |

### Example

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

## Response

### Success (201 Created)

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

### Error (400 Bad Request)

Returned for invalid email, duplicate username, weak password, or missing fields.

## Notes

- Passwords are never returned in responses.
- Role stays `citizen` unless the request is made by an admin.