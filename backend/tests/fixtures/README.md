# Test Fixtures

This directory contains scripts to populate the database with sample data for **development and testing purposes only**.

## Files

- **`create_sample_data.py`**: Creates comprehensive sample data for development testing
  - 4 neighborhoods
  - 5 event themes
  - Multiple users (admin, elected, agent, citizens)
  - Sample reports with various statuses
  - Active surveys with options
  - Upcoming events

## Usage

⚠️ **FOR DEVELOPMENT ONLY** - Never run these scripts in production!

```bash
# From the backend container
# Execute the sample data creation script
docker compose exec backend python manage.py shell -c "exec(open('tests/fixtures/create_sample_data.py', encoding='utf-8').read())"
```

## Initial User Creation

The initial superuser is automatically created by Docker Compose using environment variables in `docker-entrypoint.sh`:

- `DJANGO_SUPERUSER_USERNAME`
- `DJANGO_SUPERUSER_EMAIL`
- `DJANGO_SUPERUSER_PASSWORD`

This ensures a default admin user exists on first deployment without manual intervention.
