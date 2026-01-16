#!/usr/bin/env bash
set -euo pipefail

# docker-entrypoint.sh
# If MIGRATE=1 will run migrations
# If COLLECTSTATIC=1 will run collectstatic --noinput
# Any arguments passed to the container will be exec'd (e.g. gunicorn ...)

echo "[entrypoint] starting with user: $(whoami)"

# Ensure STATIC_ROOT and MEDIA_ROOT directories exist and have correct ownership
DJANGO_STATIC_ROOT=${DJANGO_STATIC_ROOT:-/app/staticfiles}
DJANGO_MEDIA_ROOT=${DJANGO_MEDIA_ROOT:-/app/media}
mkdir -p "$DJANGO_STATIC_ROOT" "$DJANGO_MEDIA_ROOT" /app/static

if [ "$(id -u)" = "0" ]; then
  echo "[entrypoint] running as root - fixing ownership of static/media"
  chown -R appuser:appuser "$DJANGO_STATIC_ROOT" "$DJANGO_MEDIA_ROOT" /app || true
fi

# Helper to run commands as appuser if possible
run_as_appuser() {
  if [ "$(id -u)" = "0" ]; then
    # try runuser (should exist in Debian/Ubuntu)
    if command -v runuser >/dev/null 2>&1; then
      runuser -u appuser -- "$@"
      return $?
    fi
    # fallback to su
    if command -v su >/dev/null 2>&1; then
      su appuser -s /bin/sh -c "$*"
      return $?
    fi
    # last resort: run as root (not ideal)
    echo "[entrypoint] warning: cannot switch to appuser, running as root"
    "$@"
    return $?
  else
    # already non-root
    "$@"
    return $?
  fi
}

if [ "${MIGRATE:-0}" = "1" ] || [ "${MIGRATE:-false}" = "true" ]; then
  echo "[entrypoint] running migrations"
  run_as_appuser python manage.py migrate --noinput
fi

if [ "${COLLECTSTATIC:-0}" = "1" ] || [ "${COLLECTSTATIC:-false}" = "true" ]; then
  echo "[entrypoint] collectstatic --noinput"
  run_as_appuser python manage.py collectstatic --noinput
fi

echo "[entrypoint] executing: $@"


# Création auto du superuser si variables présentes
if [ "${DJANGO_SUPERUSER_USERNAME:-}" != "" ]; then
  python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
u='${DJANGO_SUPERUSER_USERNAME}'
e='${DJANGO_SUPERUSER_EMAIL:-admin@example.com}'
p='${DJANGO_SUPERUSER_PASSWORD:-}'
if p and not User.objects.filter(username=u).exists():
    User.objects.create_superuser(u, e, p)
"
fi

exec "$@"