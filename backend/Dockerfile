FROM python:3.12-slim AS backend

# 1. Variables techniques (OK de les laisser ici)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8000 \
    DJANGO_STATIC_ROOT=/app/staticfiles \
    DJANGO_MEDIA_ROOT=/app/media

# 2. Dépendances système
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 10001 app
WORKDIR /app
COPY . /app/

# 3. Installation des dépendances
RUN set -eux; \
    python -m pip install --upgrade pip; \
    if [ -f requirements.txt ]; then \
        pip install -r requirements.txt; \
    elif [ -f pyproject.toml ]; then \
        pip install .; \
    else \
        pip install 'Django>=4.2,<6' 'gunicorn>=22' 'psycopg2-binary>=2.9'; \
    fi

# 4. Préparation des dossiers
RUN mkdir -p "$DJANGO_STATIC_ROOT" "$DJANGO_MEDIA_ROOT" && chown -R app:app /app

# --- NOTE : J'AI SUPPRIMÉ LE GROS BLOC ENV DB_... ICI ---
# Azure injectera ces variables au runtime.

VOLUME ["/app/staticfiles", "/app/media"]
EXPOSE 8000

USER app

# 5. CMD robuste
# On utilise des valeurs par défaut directement dans le script shell au besoin
CMD ["sh", "-c", " \
    python wait_for_db.py && \
    python manage.py migrate --noinput && \
    python manage.py createsuperuser --noinput \
        --username \"$DJANGO_SUPERUSER_USERNAME\" \
        --email \"$DJANGO_SUPERUSER_EMAIL\" || echo 'Admin existe déjà' && \
    python manage.py collectstatic --noinput && \
    exec gunicorn ${DJANGO_WSGI_MODULE:-config.wsgi}:application \
        --bind 0.0.0.0:${PORT} \
        --workers ${GUNICORN_WORKERS:-3} \
        --timeout ${GUNICORN_TIMEOUT:-120} \
        --access-logfile - \
        --error-logfile - \
    "]
