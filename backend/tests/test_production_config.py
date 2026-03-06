"""Production configuration resilience tests.

Validates that critical Django settings are correctly configured to prevent
failures specific to the Azure cloud deployment environment.

These tests run as part of the normal pytest suite (see unittest.yml) and are
also executed by the dedicated resilience workflow (resilience.yml).
"""
import os
import sys
import subprocess
from io import StringIO

import pytest
from django.conf import settings
from django.core.management import call_command


pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# ALLOWED_HOSTS
# ---------------------------------------------------------------------------

class TestAllowedHosts:
    """ALLOWED_HOSTS must include every hostname used by the Azure deployment."""

    def test_localhost_is_allowed(self):
        assert "localhost" in settings.ALLOWED_HOSTS

    def test_loopback_ip_is_allowed(self):
        assert "127.0.0.1" in settings.ALLOWED_HOSTS

    def test_azure_app_service_root_hostname_is_allowed(self):
        """The Azure Web App primary hostname must be in ALLOWED_HOSTS."""
        # Use .count() for exact list-membership (not substring) to be explicit.
        assert settings.ALLOWED_HOSTS.count("novavilleapp.azurewebsites.net") >= 1, (
            "novavilleapp.azurewebsites.net must be in ALLOWED_HOSTS"
        )

    def test_azure_random_subdomain_is_covered_by_wildcard(self):
        """Random Azure subdomains must be matched by a wildcard pattern in ALLOWED_HOSTS.

        Azure App Service assigns a unique subdomain on every new deployment
        (e.g. novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net).
        The '.azurewebsites.net' entry (leading period = Django subdomain wildcard)
        covers all such hostnames without requiring a code change when Azure
        regenerates the subdomain.

        The hostname used below is a representative example; any Azure-assigned
        subdomain under azurewebsites.net will match the same wildcard pattern,
        so this test remains valid even after a redeployment changes the hash part.

        Note: '*.azurewebsites.net' is NOT a valid Django pattern — only a leading
        period acts as a wildcard in ALLOWED_HOSTS.
        """
        from django.http.request import validate_host

        representative_azure_host = (
            "novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net"
        )
        assert validate_host(representative_azure_host, settings.ALLOWED_HOSTS), (
            f"ALLOWED_HOSTS must match Azure random subdomains like '{representative_azure_host}'. "
            "Add '.azurewebsites.net' (leading period) to ALLOWED_HOSTS."
        )

    def test_docker_internal_backend_alias_is_allowed(self):
        """The 'backend' alias is used by Nginx to proxy to Django inside Docker."""
        assert "backend" in settings.ALLOWED_HOSTS

    def test_allowed_hosts_env_variable_values_are_included(self):
        """Every host listed in DJANGO_ALLOWED_HOSTS env var must end up in ALLOWED_HOSTS."""
        env_val = os.environ.get("DJANGO_ALLOWED_HOSTS", "")
        if not env_val.strip():
            pytest.skip("DJANGO_ALLOWED_HOSTS not set in this environment")
        for host in env_val.split(","):
            host = host.strip()
            if host:
                assert host in settings.ALLOWED_HOSTS, (
                    f"Host '{host}' from DJANGO_ALLOWED_HOSTS is missing in settings.ALLOWED_HOSTS"
                )


# ---------------------------------------------------------------------------
# SECRET_KEY & JWT signing key
# ---------------------------------------------------------------------------

class TestSecretKeyConfiguration:
    """SECRET_KEY must always be set; absence in production must cause a hard failure."""

    def test_secret_key_is_set_in_current_environment(self):
        assert settings.SECRET_KEY, "DJANGO_SECRET_KEY must not be empty"

    def test_jwt_signing_key_is_set(self):
        assert settings.SIMPLE_JWT.get("SIGNING_KEY"), "JWT_SIGNING_KEY must not be empty"

    def test_missing_secret_key_raises_runtime_error_in_production(self):
        """A missing DJANGO_SECRET_KEY must cause RuntimeError at startup when DEBUG=False.

        This prevents silent deployments with an empty secret key.
        """
        env = {
            **os.environ,
            "DJANGO_SECRET_KEY": "",
            "DJANGO_DEBUG": "false",
            "DB_ENGINE": "django.db.backends.sqlite3",
            "DB_NAME": ":memory:",
            "DJANGO_SETTINGS_MODULE": "config.settings",
        }
        result = subprocess.run(
            [
                sys.executable,
                "-c",
                "import importlib, config.settings; importlib.reload(config.settings)",
            ],
            cwd=str(settings.BASE_DIR),
            env=env,
            capture_output=True,
            text=True,
        )
        assert result.returncode != 0, (
            "Expected RuntimeError to be raised when DJANGO_SECRET_KEY is missing "
            "in production (DEBUG=False)"
        )
        assert "DJANGO_SECRET_KEY" in result.stderr, (
            f"Expected the error message to mention DJANGO_SECRET_KEY.\nstderr: {result.stderr}"
        )


# ---------------------------------------------------------------------------
# JWT token configuration
# ---------------------------------------------------------------------------

class TestJWTConfiguration:
    """JWT token settings must be fully configured for authentication to work."""

    def test_access_token_lifetime_is_set(self):
        assert settings.SIMPLE_JWT.get("ACCESS_TOKEN_LIFETIME"), (
            "ACCESS_TOKEN_LIFETIME must be configured"
        )

    def test_refresh_token_lifetime_is_set(self):
        assert settings.SIMPLE_JWT.get("REFRESH_TOKEN_LIFETIME"), (
            "REFRESH_TOKEN_LIFETIME must be configured"
        )

    def test_auth_header_type_is_bearer(self):
        assert "Bearer" in settings.SIMPLE_JWT.get("AUTH_HEADER_TYPES", []), (
            "AUTH_HEADER_TYPES must include 'Bearer'"
        )


# ---------------------------------------------------------------------------
# CORS configuration
# ---------------------------------------------------------------------------

class TestCORSConfiguration:
    """CORS must be configured so that the Flutter frontend can reach the API."""

    def test_cors_credentials_are_allowed(self):
        assert settings.CORS_ALLOW_CREDENTIALS is True, (
            "CORS_ALLOW_CREDENTIALS must be True for JWT token exchange to work"
        )

    def test_cors_headers_include_authorization(self):
        assert "authorization" in settings.CORS_ALLOW_HEADERS, (
            "The 'authorization' header must be in CORS_ALLOW_HEADERS for JWT to work"
        )

    def test_cors_headers_include_content_type(self):
        assert "content-type" in settings.CORS_ALLOW_HEADERS

    def test_cors_methods_include_get(self):
        assert "GET" in settings.CORS_ALLOW_METHODS

    def test_cors_methods_include_post(self):
        assert "POST" in settings.CORS_ALLOW_METHODS

    def test_cors_methods_include_put_and_patch(self):
        assert "PUT" in settings.CORS_ALLOW_METHODS
        assert "PATCH" in settings.CORS_ALLOW_METHODS


# ---------------------------------------------------------------------------
# Database configuration
# ---------------------------------------------------------------------------

class TestDatabaseConfiguration:
    """Database settings must be properly configured."""

    def test_default_database_is_configured(self):
        assert "default" in settings.DATABASES

    def test_database_engine_is_set(self):
        assert settings.DATABASES["default"]["ENGINE"], (
            "Database ENGINE must not be empty"
        )

    def test_database_name_is_set(self):
        assert settings.DATABASES["default"]["NAME"], (
            "Database NAME must not be empty"
        )


# ---------------------------------------------------------------------------
# Static files configuration (WhiteNoise)
# ---------------------------------------------------------------------------

class TestStaticFilesConfiguration:
    """Static files must be configured correctly so the admin and API docs load."""

    def test_static_url_is_configured(self):
        assert settings.STATIC_URL, "STATIC_URL must be configured"

    def test_static_root_is_configured(self):
        assert settings.STATIC_ROOT, "STATIC_ROOT must be configured"

    def test_whitenoise_middleware_is_present(self):
        """WhiteNoise serves static files in production without a separate web server."""
        assert any("WhiteNoise" in mw for mw in settings.MIDDLEWARE), (
            "WhiteNoise middleware must be in MIDDLEWARE for static file serving"
        )


# ---------------------------------------------------------------------------
# Migration completeness
# ---------------------------------------------------------------------------

class TestMigrationState:
    """Every model change must have a corresponding migration."""

    def test_no_missing_migrations(self):
        """makemigrations --check exits 0 when models and migrations are in sync.

        A non-zero exit means a developer added or changed a model without
        running makemigrations, which would cause errors on the first deploy.
        """
        from django.core.management.base import CommandError

        out = StringIO()
        try:
            call_command(
                "makemigrations",
                "--check",
                "--dry-run",
                stdout=out,
                stderr=out,
                verbosity=0,
            )
        except SystemExit as exc:
            if exc.code != 0:
                pytest.fail(
                    "Missing migrations detected — run "
                    "`python manage.py makemigrations` and commit the result.\n"
                    f"Details:\n{out.getvalue()}"
                )
        except CommandError as exc:
            pytest.fail(
                "Migration check raised a CommandError "
                "(possible conflicting migrations):\n"
                f"{exc}"
            )
