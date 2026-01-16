FROM python:3.12-slim AS backend

ENV PYTHONDONTWRITEBYTECODE=1 \
		PYTHONUNBUFFERED=1 \
		PIP_NO_CACHE_DIR=1 \
		PORT=8000

# Dépendances système (libpq pour PostgreSQL)
RUN set -eux; \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			build-essential \
			libpq-dev \
			curl \
		; \
		rm -rf /var/lib/apt/lists/*

# Utilisateur non-root
RUN useradd -m -u 10001 app

# Code Django attendu dans /app (manage.py, apps/, templates/ ...)
WORKDIR /app

# Copie du backend (inclut potentiellement requirements.txt ou pyproject.toml)
COPY . /app/

# Installation des dépendances (support requirements.txt ou pyproject.toml)
RUN set -eux; \
		python -m pip install --upgrade pip; \
		if [ -f requirements.txt ]; then \
			pip install -r requirements.txt; \
		elif [ -f pyproject.toml ]; then \
			pip install .; \
		else \
			echo "Aucun fichier de dépendances détecté (requirements.txt/pyproject.toml). Installation minimale."; \
			pip install 'Django>=4.2,<6' 'gunicorn>=22,<23' 'psycopg2-binary>=2.9'; \
		fi

# Dossiers pour les assets MVT
ENV DJANGO_STATIC_ROOT=/app/staticfiles \
		DJANGO_MEDIA_ROOT=/app/media
RUN mkdir -p "$DJANGO_STATIC_ROOT" "$DJANGO_MEDIA_ROOT" && chown -R app:app /app

# Variables DB CloudSQL (TCP ou Unix socket via /cloudsql/INSTANCE)
ENV DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE:-config.settings} \
		DB_ENGINE=${DB_ENGINE:-django.db.backends.postgresql} \
		DB_HOST=${DB_HOST:-localhost} \
		DB_PORT=${DB_PORT:-5432} \
		DB_NAME=${DB_NAME:-novaville_db} \
		DB_USER=${DB_USER:-novaville_user} \
		DB_PASSWORD=${DB_PASSWORD:-YOUR_SECURE_PASSWORD} \
		INSTANCE_CONNECTION_NAME=${INSTANCE_CONNECTION_NAME:-}

# Si vous utilisez les sockets Cloud SQL dans Cloud Run/GKE:
#   - Montez /cloudsql et définissez DB_HOST="/cloudsql/${INSTANCE_CONNECTION_NAME}"
VOLUME ["/app/staticfiles", "/app/media"]

EXPOSE 8000


# Lancement: migrations/statics optionnels, puis Gunicorn (MVT via module WSGI)
ENV DJANGO_WSGI_MODULE=${DJANGO_WSGI_MODULE:-config.wsgi} \
		GUNICORN_WORKERS=3 \
		GUNICORN_TIMEOUT=120

USER app

CMD ["sh", "-c", " \
    python manage.py migrate --noinput && \
    python manage.py createsuperuser --noinput \
        --username \"$DJANGO_SUPERUSER_USERNAME\" \
        --email \"$DJANGO_SUPERUSER_EMAIL\" || echo 'Création ignorée (existe déjà ou variables manquantes)' && \
    python manage.py collectstatic --noinput && \
    exec gunicorn ${DJANGO_WSGI_MODULE}:application \
        --bind 0.0.0.0:${PORT} \
        --workers ${GUNICORN_WORKERS} \
        --timeout ${GUNICORN_TIMEOUT} \
        --access-logfile - \
        --error-logfile - \
    "]


# CMD ["sh", "-c", "set -eux; \
#     if [ -f manage.py ] && [ \"${MIGRATE:-0}\" = \"1\" ]; then \
#         python manage.py migrate --noinput; \
#     fi; \
#     if [ -f manage.py ] && [ \"${COLLECTSTATIC:-0}\" = \"1\" ]; then \
#         python manage.py collectstatic --noinput; \
#     fi; \
#     exec gunicorn \"${DJANGO_WSGI_MODULE}:application\" \
#         --bind 0.0.0.0:${PORT} \
#         --workers ${GUNICORN_WORKERS} \
#         --timeout ${GUNICORN_TIMEOUT} \
#         --access-logfile - \
#         --error-logfile -"]