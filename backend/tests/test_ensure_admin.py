"""Tests for the ensure_admin management command."""
import pytest
from django.contrib.auth import get_user_model
from django.core.management import call_command
from io import StringIO

from core.db.enums import RoleEnum

User = get_user_model()

pytestmark = pytest.mark.django_db


class TestEnsureAdminCommand:
    """Tests for the ensure_admin management command."""

    def test_skips_when_password_not_set(self, monkeypatch):
        """Command does nothing when DJANGO_SUPERUSER_PASSWORD is not set."""
        monkeypatch.delenv("DJANGO_SUPERUSER_PASSWORD", raising=False)
        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "admin")

        stderr = StringIO()
        call_command("ensure_admin", stderr=stderr)

        assert not User.objects.filter(is_superuser=True).exists()
        assert "DJANGO_SUPERUSER_PASSWORD is not set" in stderr.getvalue()

    def test_creates_superuser_when_none_exists(self, monkeypatch):
        """Command creates a superuser using the provided env variables."""
        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "admintest")
        monkeypatch.setenv("DJANGO_SUPERUSER_EMAIL", "admintest@novaville.fr")
        monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "StrongPass123!")

        stdout = StringIO()
        call_command("ensure_admin", stdout=stdout)

        assert User.objects.filter(username="admintest", is_superuser=True).exists()
        assert "created successfully" in stdout.getvalue()

    def test_created_superuser_has_global_admin_role(self, monkeypatch):
        """Superuser created by ensure_admin must have role=GLOBAL_ADMIN, matching the fixture."""
        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "adminrole")
        monkeypatch.setenv("DJANGO_SUPERUSER_EMAIL", "adminrole@novaville.fr")
        monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "StrongPass123!")

        call_command("ensure_admin")

        user = User.objects.get(username="adminrole", is_superuser=True)
        assert user.role == RoleEnum.GLOBAL_ADMIN, (
            "Superuser created by ensure_admin must have role=GLOBAL_ADMIN to match the fixture schema."
        )

    def test_created_superuser_has_default_first_and_last_name(self, monkeypatch):
        """Superuser created with default env values should have first_name='Admin', last_name='Novaville'."""
        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "adminfullname")
        monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "StrongPass123!")
        monkeypatch.delenv("DJANGO_SUPERUSER_FIRST_NAME", raising=False)
        monkeypatch.delenv("DJANGO_SUPERUSER_LAST_NAME", raising=False)

        call_command("ensure_admin")

        user = User.objects.get(username="adminfullname", is_superuser=True)
        assert user.first_name == "Admin"
        assert user.last_name == "Novaville"

    def test_created_superuser_respects_custom_first_and_last_name(self, monkeypatch):
        """Superuser created with custom FIRST/LAST name env vars should use them."""
        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "admincustom")
        monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "StrongPass123!")
        monkeypatch.setenv("DJANGO_SUPERUSER_FIRST_NAME", "Marie")
        monkeypatch.setenv("DJANGO_SUPERUSER_LAST_NAME", "Dupont")

        call_command("ensure_admin")

        user = User.objects.get(username="admincustom", is_superuser=True)
        assert user.first_name == "Marie"
        assert user.last_name == "Dupont"

    def test_idempotent_when_superuser_already_exists(self, monkeypatch):
        """Command does nothing when a superuser already exists."""
        User.objects.create_superuser(
            username="existing_admin",
            email="existing@example.com",
            password="ExistingPass123!",
        )

        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "another_admin")
        monkeypatch.setenv("DJANGO_SUPERUSER_EMAIL", "another@example.com")
        monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "AnotherPass123!")

        stdout = StringIO()
        call_command("ensure_admin", stdout=stdout)

        # No new superuser should have been created
        assert User.objects.filter(is_superuser=True).count() == 1
        assert "already exists" in stdout.getvalue()

    def test_skips_when_username_exists_as_non_superuser(self, monkeypatch):
        """Command skips creation when the target username belongs to a regular user."""
        User.objects.create_user(
            username="admin",
            email="admin@example.com",
            password="UserPass123!",
        )

        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "admin")
        monkeypatch.setenv("DJANGO_SUPERUSER_EMAIL", "admin@example.com")
        monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "AdminPass123!")

        stderr = StringIO()
        call_command("ensure_admin", stderr=stderr)

        # The regular user should not have been promoted to superuser
        assert not User.objects.filter(username="admin", is_superuser=True).exists()
        assert "already exists but is not a superuser" in stderr.getvalue()

    def test_created_superuser_has_usable_non_null_password(self, monkeypatch):
        """Superuser created by ensure_admin must have a usable, non-null password.

        This guards against silent misconfigurations where the admin account is
        created with an unusable password (e.g. set_unusable_password()) or an
        empty password, which would prevent login on first production deployment.
        """
        monkeypatch.setenv("DJANGO_SUPERUSER_USERNAME", "adminprod")
        monkeypatch.setenv("DJANGO_SUPERUSER_EMAIL", "adminprod@example.com")
        monkeypatch.setenv("DJANGO_SUPERUSER_PASSWORD", "StrongProdPass123!")

        call_command("ensure_admin")

        user = User.objects.get(username="adminprod", is_superuser=True)
        assert user.has_usable_password(), (
            "Superuser created by ensure_admin must have a usable password. "
            "Ensure DJANGO_SUPERUSER_PASSWORD is set to a non-empty value."
        )
        assert user.check_password("StrongProdPass123!"), (
            "Superuser password must match the value provided in DJANGO_SUPERUSER_PASSWORD."
        )
