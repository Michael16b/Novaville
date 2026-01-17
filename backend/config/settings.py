"""
Squelette settings.py - compléter avant usage
Remarque: utilisez des variables d'environnement pour les secrets
"""
import os
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "change-me")
DEBUG = os.environ.get("DJANGO_DEBUG", "False").lower() in ("1", "true", "yes")
ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost").split(",")

INSTALLED_APPS = [
    # Add corsheaders for cross-origin requests from the frontend (dev)
    'corsheaders',
    # Optional nicer admin UI (grappelli) - installed only when in requirements
    # Put grappelli before admin to override admin templates and static files
    # Note: Grappelli overrides Django admin static files intentionally.
    # collectstatic uses grep to filter out duplicate file warnings in logs.
    "grappelli",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # third-party
    "rest_framework",
    # OpenAPI schema generation and Swagger UI
    "drf_spectacular",
    "rest_framework_simplejwt",
    "django_filters",
    # local apps
    "core",
    "api",
    "application",
    "infrastructure",
]

# Par défaut pour les nouvelles apps (évite le warning sur AutoField)
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

MIDDLEWARE = [
    # corsheaders middleware should be placed as high as possible
    'corsheaders.middleware.CorsMiddleware',
    # Admin IP restriction middleware (applies only if ADMIN_ALLOWED_IPS is set)
    "config.middleware.AdminIPRestrictionMiddleware",
    "django.middleware.security.SecurityMiddleware",
    # WhiteNoise middleware serves static files efficiently from Gunicorn
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# Templates: nécessaire pour l'admin et les pages basées sur templates
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        # dossier global templates (optionnel)
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# Static files (URL)
STATIC_URL = "/static/"
# Directory where `collectstatic` will collect static files for production.
# Must be a filesystem path when using the staticfiles app (and for collectstatic).
STATIC_ROOT = os.environ.get("DJANGO_STATIC_ROOT", str(BASE_DIR / "staticfiles"))

# Media files (user uploaded)
MEDIA_URL = "/media/"
MEDIA_ROOT = os.environ.get("DJANGO_MEDIA_ROOT", str(BASE_DIR / "media"))

# STATICFILES_DIRS: Not configured because all static files come from installed apps.
# Django will automatically collect static files from each app's static/ directory.
# If you need custom static files not part of any app, add them here:
# STATICFILES_DIRS = [BASE_DIR / "static"]

# Database: prefer DATABASE_URL, else support DB_* or POSTGRES_* env vars
DATABASE_URL = os.environ.get("DATABASE_URL")
try:
    import dj_database_url  # provided in requirements.txt
except Exception:
    dj_database_url = None

if DATABASE_URL and dj_database_url:
    DATABASES = {"default": dj_database_url.parse(DATABASE_URL, conn_max_age=600)}
else:
    # Support both DB_* (used in docker-compose) and POSTGRES_* (common)
    DB_ENGINE = os.environ.get("DB_ENGINE") or os.environ.get("POSTGRES_ENGINE") or "django.db.backends.postgresql_psycopg2"
    DB_NAME = os.environ.get("DB_NAME") or os.environ.get("POSTGRES_DB") or "novaville"
    DB_USER = os.environ.get("DB_USER") or os.environ.get("POSTGRES_USER") or "postgres"
    DB_PASSWORD = os.environ.get("DB_PASSWORD") or os.environ.get("POSTGRES_PASSWORD") or ""
    DB_HOST = os.environ.get("DB_HOST") or os.environ.get("POSTGRES_HOST") or "localhost"
    DB_PORT = os.environ.get("DB_PORT") or os.environ.get("POSTGRES_PORT") or "5432"

    DATABASES = {
        "default": {
            "ENGINE": DB_ENGINE,
            "NAME": DB_NAME,
            "USER": DB_USER,
            "PASSWORD": DB_PASSWORD,
            "HOST": DB_HOST,
            "PORT": DB_PORT,
        }
    }

# REST framework: JWT, pagination, throttling, filters
REST_FRAMEWORK = {
    # Force JSON responses only (no Browsable API / HTML) - frontend handles rendering
    "DEFAULT_RENDERER_CLASSES": (
        "rest_framework.renderers.JSONRenderer",
    ),
    # Use drf-spectacular for OpenAPI schema generation
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": int(os.environ.get("DJANGO_PAGINATION_PAGE_SIZE", 20)),
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.OrderingFilter",
        "rest_framework.filters.SearchFilter",
    ),
    "DEFAULT_THROTTLE_CLASSES": (
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ),
    "DEFAULT_THROTTLE_RATES": {
        "anon": os.environ.get("ANON_RATE", "100/day"),
        "user": os.environ.get("USER_RATE", "1000/day"),
    },
}

# Admin exposure & security
# In production, prefer ENABLE_ADMIN="0" and place the admin behind VPN / auth-proxy.
ENABLE_ADMIN = os.environ.get("ENABLE_ADMIN", "1").lower() in ("1", "true", "yes")
# Comma separated list of allowed IPs (e.g. "127.0.0.1,10.0.0.0/8"). Empty means no IP restriction.
ADMIN_ALLOWED_IPS = [ip.strip() for ip in os.environ.get("ADMIN_ALLOWED_IPS", "").split(",") if ip.strip()]

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=int(os.environ.get("JWT_ACCESS_MINUTES", 60))),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=int(os.environ.get("JWT_REFRESH_DAYS", 7))),
    "AUTH_HEADER_TYPES": ("Bearer",),
}

# WhiteNoise staticfiles storage: compressed + manifest for caching
STATICFILES_STORAGE = os.environ.get(
    "DJANGO_STATICFILES_STORAGE",
    "whitenoise.storage.CompressedManifestStaticFilesStorage",
)

# drf-spectacular OpenAPI settings
SPECTACULAR_SETTINGS = {
    "TITLE": os.environ.get("PROJECT_TITLE", "Novaville API"),
    "DESCRIPTION": "OpenAPI schema for Novaville backend API",
    "VERSION": os.environ.get("PROJECT_VERSION", "1.0.0"),
    # Optional: give the URL where Swagger UI will be served
    "SERVE_INCLUDE_SCHEMA": False,
}

# Control whether API docs are exposed (useful to disable in production)
ENABLE_API_DOCS = os.environ.get("ENABLE_API_DOCS", "1").lower() in ("1", "true", "yes")

# Add JWT bearer security scheme for Swagger / OpenAPI (drf-spectacular)
SPECTACULAR_SETTINGS.update({
    "COMPONENTS": {
        "securitySchemes": {
            "BearerAuth": {
                "type": "http",
                "scheme": "bearer",
                "bearerFormat": "JWT",
            }
        }
    },
    # Apply BearerAuth globally to endpoints in the UI (can be overridden per-view)
    "SECURITY": [{"BearerAuth": []}],
})

# Development-friendly CORS settings
# For development only: allow all origins so flutter web / other frontends can access the API.
# In production, prefer setting CORS_ALLOWED_ORIGINS to a strict list instead of allowing all.
CORS_ALLOW_ALL_ORIGINS = True
# Example for a stricter configuration:
# CORS_ALLOWED_ORIGINS = [
#     'http://localhost:8080',
#     'http://localhost:8000',
#     'http://127.0.0.1:8080',
# ]
