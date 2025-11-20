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
exec "$@"

# Optionally create a Django superuser in development.
# Set DJANGO_CREATE_SUPERUSER=1 and optionally DJANGO_ADMIN_USER, DJANGO_ADMIN_EMAIL, DJANGO_ADMIN_PASSWORD
# This block is idempotent and will NOT overwrite an existing user.

# if [ "${DJANGO_CREATE_SUPERUSER:-0}" = "1" ] || [ "${DJANGO_CREATE_SUPERUSER:-false}" = "true" ]; then
#   ADMIN_USER=${DJANGO_ADMIN_USER:-admin}
#   ADMIN_EMAIL=${DJANGO_ADMIN_EMAIL:-admin@example.com}
#   ADMIN_PASS=${DJANGO_ADMIN_PASSWORD:-ChangeMe123}
#   echo "[entrypoint] ensure superuser exists: ${ADMIN_USER}"
#   run_as_appuser python - <<PY
# from django.contrib.auth import get_user_model
# User = get_user_model()
# username = "${ADMIN_USER}"
# email = "${ADMIN_EMAIL}"
# password = "${ADMIN_PASS}"
# if not User.objects.filter(username=username).exists():
#     User.objects.create_superuser(username, email, password)
#     print('Superuser created: {}'.format(username))
# else:
#     print('Superuser already exists: {}'.format(username))
# PY
# fi
