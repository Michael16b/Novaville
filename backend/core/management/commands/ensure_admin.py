"""
Management command to ensure a superuser/admin account exists.

Creates a superuser if none is present in the database, using credentials
from environment variables. Safe to run multiple times (idempotent).

The created account mirrors the fixture schema: role is set to GLOBAL_ADMIN,
and first/last name can be customised via environment variables.

If DJANGO_SUPERUSER_PASSWORD is not provided a cryptographically secure
random password is generated automatically and printed to stdout so the
operator can retrieve it on first deployment.

Environment variables:
  DJANGO_SUPERUSER_USERNAME    – username for the admin (default: admin)
  DJANGO_SUPERUSER_EMAIL       – e-mail address         (default: admin@novaville.fr)
  DJANGO_SUPERUSER_PASSWORD    – password (auto-generated when absent)
  DJANGO_SUPERUSER_FIRST_NAME  – first name              (default: Admin)
  DJANGO_SUPERUSER_LAST_NAME   – last name               (default: Novaville)
"""

import os
import secrets

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from core.db.enums import RoleEnum

# Length of the auto-generated password (characters from a URL-safe alphabet).
_AUTO_PASSWORD_LENGTH = 32


class Command(BaseCommand):
    """Create a superuser from environment variables if one does not already exist."""

    help = "Create a superuser from environment variables if no superuser exists."

    def handle(self, *args, **options):
        """Execute the command."""
        User = get_user_model()

        username = os.environ.get("DJANGO_SUPERUSER_USERNAME", "admin")
        email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "admin@novaville.fr")
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD", "")
        first_name = os.environ.get("DJANGO_SUPERUSER_FIRST_NAME", "Admin")
        last_name = os.environ.get("DJANGO_SUPERUSER_LAST_NAME", "Novaville")

        auto_generated = False
        if not password:
            password = secrets.token_urlsafe(_AUTO_PASSWORD_LENGTH)
            auto_generated = True

        if User.objects.filter(is_superuser=True).exists():
            self.stdout.write(
                self.style.SUCCESS("[ensure_admin] A superuser already exists – nothing to do.")
            )
            return

        if User.objects.filter(username=username).exists():
            self.stderr.write(
                self.style.WARNING(
                    f"[ensure_admin] User '{username}' already exists but is not a superuser. "
                    "Skipping creation to avoid overwriting an existing account."
                )
            )
            return

        User.objects.create_superuser(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            role=RoleEnum.GLOBAL_ADMIN,
        )
        self.stdout.write(
            self.style.SUCCESS(f"[ensure_admin] Superuser '{username}' created successfully.")
        )
        if auto_generated:
            self.stdout.write(
                self.style.WARNING(
                    f"[ensure_admin] DJANGO_SUPERUSER_PASSWORD was not set. "
                    f"Auto-generated password for '{username}': {password}\n"
                    "  ⚠  Please change this password immediately after first login."
                )
            )
