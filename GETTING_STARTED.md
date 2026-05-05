# 🚀 Getting Started - Novaville Platform

This guide is for **first-time setup** of the Novaville project on your machine.

## Prerequisites

- **Docker** and **Docker Compose** installed
- **Git** (to clone the repository)

## Quick Start (Development)

The simplest way to get started:

```bash
git clone https://github.com/YOUR_ORG/Novaville.git
cd Novaville
docker compose up -d --build
```

**That's it!** ✨ Everything is ready:
- Frontend: http://localhost:80
- API Swagger: http://localhost:8000/api/docs/
- Django Admin: http://localhost:8000/admin/ (admin / ChangeMe123)

Done! Load sample data if you want (see below).

---

## Customization (Optional)

If you need to use different passwords or settings:

### Step 1: Create .env

```bash
# Windows (PowerShell)
.\init-env.bat

# macOS/Linux
bash init-env.sh
```

Or manually:
```bash
cp .env.example .env
```

### Step 2: Edit .env

Open `.env` and customize values:

```env
DB_PASSWORD=your_secure_password
DJANGO_SUPERUSER_PASSWORD=your_admin_password
```

### Step 3: Restart

```bash
docker compose down -v
docker compose up -d --build
```

---

## Load Sample Data

Create test data for development:

```bash
docker compose exec backend python manage.py shell -c "exec(open('tests/fixtures/create_sample_data.py', encoding='utf-8').read())"
```

This loads:
- ✓ 25 neighborhoods
- ✓ Admin + municipal agents + test citizens
- ✓ Sample reports, surveys, and events

---

## Useful Commands

### View logs
```bash
# All services:
docker compose logs -f

# Just backend:
docker compose logs -f backend

# Last 20 lines:
docker compose logs --tail 20
```

### Run Django commands
```bash
# Create superuser:
docker compose exec backend python manage.py createsuperuser

# Django shell:
docker compose exec backend python manage.py shell

# Run tests:
docker compose exec backend pytest
```

### Stop and clean up
```bash
# Stop all services:
docker compose down

# Remove everything (including database):
docker compose down -v

# Remove and rebuild images:
docker compose down --rmi all
docker compose up -d --build
```

## Next Steps

- Read [Backend README](backend/README.md) for API development
- Read [Frontend README](frontend/README.md) for Flutter development
- Check [DOCUMENTATION.md](DOCUMENTATION.md) for full project docs
- Review [Copilot Instructions](.github/copilot-instructions.md) for dev practices

## Need Help?

- Check this guide's **Common Issues** section above
- Review [README.md](README.md) for full project documentation
- Ask team members or open a GitHub issue

Happy coding! 🎉
