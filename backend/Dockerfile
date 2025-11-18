###############################################
# Backend Dockerfile - single-stage clean
# Build context: ./backend (docker-compose sets this)
###############################################

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

# System deps (libpq for Postgres)
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl util-linux \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first for better caching
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /app/requirements.txt

# Copy project sources (context is ./backend)
COPY . /app

# Ensure the entrypoint script exists in context as ./docker-entrypoint.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create non-root user and fix permissions (we'll run entrypoint as root to fix volume ownership)
RUN useradd --create-home appuser && chown -R appuser:appuser /app

ENV DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE:-config.settings}

EXPOSE ${PORT}

# Do not switch to non-root here: entrypoint will perform chown on mounted volumes
# and then execute the final command as the non-root user when possible.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "120"]

