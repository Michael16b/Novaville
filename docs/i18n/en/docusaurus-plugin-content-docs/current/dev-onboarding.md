---
sidebar_position: 4
---

# Developer Onboarding

This document helps a new development team quickly take over the Novaville project: understand the architecture, run the code locally, run tests and contribute safely.

## Goals

- Present the overall architecture
- Describe the local development flow (setup, services, environment variables)
- Explain how to run the test suite
- Highlight production and deployment considerations

## Repository structure

Main folders:

- `backend/`: Django REST API
- `frontend/`: Flutter application (mobile/web)
- `docs/`: Documentation (Docusaurus)
- `docker-compose.yml` and `docker-compose-azure.yml`: environment definitions

## Quick start

1. Copy environment variables from `.env.example` and adapt them.
2. Start services:

```bash
docker compose up -d --build
```

API is available at `http://localhost:8000`, Frontend at `http://localhost:80`.

## Run backend tests

```bash
docker compose exec backend pytest
```

## Debugging and considerations

- `DJANGO_SECRET_KEY` and other secrets must never be committed
- Check migrations after model changes
- External integrations and production variables are in `docker-compose-azure.yml`

## More information

- Architecture: [Technical documentation](../docs/technical/architecture)
- API: [API documentation](../docs/api/overview)
- CI/CD and deployment: see workflows and `docs/DOCUMENTATION_README.md`
