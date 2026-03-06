"""
Management command to ensure a superuser/admin account exists.

Creates a superuser if none is present in the database, using credentials
from environment variables. Safe to run multiple times (idempotent).

Environment variables:
  DJANGO_SUPERUSER_USERNAME  – username for the admin (default: admin)
  DJANGO_SUPERUSER_EMAIL     – e-mail address           (default: admin@example.com)
  DJANGO_SUPERUSER_PASSWORD  – password (required; command is skipped when absent)
"""

import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    """Create a superuser from environment variables if one does not already exist."""

    help = "Create a superuser from environment variables if no superuser exists."

    def handle(self, *args, **options):
        """Execute the command."""
        User = get_user_model()

        username = os.environ.get("DJANGO_SUPERUSER_USERNAME", "admin")
        email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "admin@example.com")
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD", "")

        if not password:
            self.stderr.write(
                self.style.WARNING(
                    "[ensure_admin] DJANGO_SUPERUSER_PASSWORD is not set – skipping admin creation."
                )
            )
            return

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

        User.objects.create_superuser(username=username, email=email, password=password)
        self.stdout.write(
            self.style.SUCCESS(f"[ensure_admin] Superuser '{username}' created successfully.")
        )
