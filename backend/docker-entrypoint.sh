#!/usr/bin/env bash
set -euo pipefail

# docker-entrypoint.sh
# If MIGRATE=1 will run migrations
# If COLLECTSTATIC=1 will run collectstatic --noinput
# Any arguments passed to the container will be exec'd (e.g. gunicorn ...)

echo "[entrypoint] starting with user: $(whoami)"

if [ "${MIGRATE:-0}" = "1" ] || [ "${MIGRATE:-false}" = "true" ]; then
  echo "[entrypoint] running migrations"
  python manage.py migrate --noinput
fi

if [ "${COLLECTSTATIC:-0}" = "1" ] || [ "${COLLECTSTATIC:-false}" = "true" ]; then
  echo "[entrypoint] collectstatic --noinput"
  python manage.py collectstatic --noinput
fi

echo "[entrypoint] executing: $@"
exec "$@"
