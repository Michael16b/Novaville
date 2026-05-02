---
sidebar_position: 3
---

# Internal Guides (for handover)

This document gathers internal procedures and documents to allow a new team to take over development, ship features and deploy the application for a new client.

## 1) Development environment setup and initialization

Prerequisites: `git`, `docker`, `docker compose`, `node`, `npm`, `flutter` (optional for frontend).

Quick steps:

1. Clone the repo:

```bash
git clone https://github.com/Michael16b/Novaville.git
cd Novaville
```

2. Copy env and adapt:

```bash
cp .env.example .env
# Edit .env with local credentials
```

3. Start services:

```bash
docker compose up -d --build
```

4. Run migrations and create superuser:

```bash
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py createsuperuser
```

5. Verify endpoints: `http://localhost:8000/api/`, `http://localhost:8000/admin`.

Practical notes: keep a `docs/dev-setup.md` if you plan to automate bootstrapping further.

## 2) "First steps to modify the code" document

Goal: help a developer implement first changes, for example modifying the home page UI.

Example: change the text and button on the documentation homepage (Docusaurus) — similar steps apply to the Flutter frontend:

- Locate the component: `docs/src/pages/index.tsx` (docs) or `frontend/lib/main.dart` (app).
- Change the text and links.
- Test locally: `npm start` (docs) or `flutter run -d chrome` (frontend web).
- Open a PR with a clear description and tests if applicable.

Quick UI change checklist:

- Run the local server and verify behavior
- Keep commits atomic
- Update UI snapshots/tests if any
- Add changelog entry for user-visible changes

## 3) Concrete example — change the homepage (mini-tutorial)

1. Open `frontend/lib/main.dart` or `docs/src/pages/index.tsx` depending on target.
2. Find the responsible component (e.g. `HomepageHeader`).
3. Edit copy and recompile: `flutter run` or `npm start`.
4. Validate across resolutions/platforms.

## 4) Deployment procedure for a new client

Goal: deploy the application for a client using their domain and env variables.

1. Prepare infrastructure (Azure / target server):
   - Create resources (App Service / Container Registry / Database)
   - Configure networking and firewall rules

2. Prepare secrets and env variables:
   - Generate `SECRET_KEY`
   - Configure DB credentials, SMTP, third-party keys

3. Build images and push to registry:

```bash
docker build -t myregistry/novaville-backend:latest -f backend/Dockerfile .
docker build -t myregistry/novaville-frontend:latest -f frontend/Dockerfile .
docker push myregistry/novaville-backend:latest
docker push myregistry/novaville-frontend:latest
```

4. Deploy using orchestration (az cli / terraform / docker compose):

```bash
# Example: deploy via docker-compose on a VM
docker compose -f docker-compose-prod.yml up -d
```

5. Run migrations and post-deploy tasks:

```bash
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py collectstatic --noinput
```

6. Configure TLS (Let's Encrypt / provided certificate) and check `ALLOWED_HOSTS`.

7. Run smoke tests and check monitoring (health endpoints, logs, alerts).

## 5) Recommended docs to include in the repo

- `docs/technical/internal-guides.md` (this file)
- `docs/dev-setup.md`: bootstrap script and detailed steps
- `docs/change-process.md`: PR / review / release guide
- `docs/deploy-playbook.md`: step-by-step playbook for client deployment

---

I can generate `dev-setup.md` and `deploy-playbook.md` and prepare a PR. Tell me which to prioritise.
