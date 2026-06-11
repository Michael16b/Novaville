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
  DJANGO_RESET_ADMIN_ON_DEPLOY – when true, update an existing superuser in
                                 place before creating one if needed. It never
                                 deletes users, because user deletion cascades
                                 to reports, surveys, events, and votes.
"""

import os
import secrets

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
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

        username = os.environ.get("DJANGO_SUPERUSER_USERNAME", "admin") or "admin"
        email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "admin@novaville.fr") or "admin@novaville.fr"
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD", "")
        first_name = os.environ.get("DJANGO_SUPERUSER_FIRST_NAME", "Admin") or "Admin"
        last_name = os.environ.get("DJANGO_SUPERUSER_LAST_NAME", "Novaville") or "Novaville"
        reset_admin = os.environ.get("DJANGO_RESET_ADMIN_ON_DEPLOY", "0").lower() in (
            "1",
            "true",
            "yes",
        )

        auto_generated = False
        if not password:
            password = secrets.token_urlsafe(_AUTO_PASSWORD_LENGTH)
            auto_generated = True

        target_user = User.objects.filter(username=username).first()

        if reset_admin:
            if target_user and not target_user.is_superuser:
                self.stderr.write(
                    self.style.WARNING(
                        f"[ensure_admin] User '{username}' already exists but is not a superuser. "
                        "Skipping admin reset to avoid promoting the wrong account."
                    )
                )
                return

            admin_user = target_user or (
                User.objects.filter(is_superuser=True).order_by("id").first()
            )
            if admin_user:
                admin_user.username = username
                admin_user.email = email
                admin_user.first_name = first_name
                admin_user.last_name = last_name
                admin_user.role = RoleEnum.GLOBAL_ADMIN
                admin_user.is_staff = True
                admin_user.is_superuser = True
                validate_password(password, user=admin_user)
                admin_user.set_password(password)
                admin_user.save()
                self.stdout.write(
                    self.style.SUCCESS(
                        "[ensure_admin] Existing admin account updated in place. No users deleted."
                    )
                )
                if auto_generated:
                    self.stdout.write(
                        self.style.WARNING(
                            f"[ensure_admin] DJANGO_SUPERUSER_PASSWORD was not set. "
                            f"Auto-generated password for '{username}': {password}\n"
                            "  ⚠  Please change this password immediately after first login."
                        )
                    )
                return

        if User.objects.filter(is_superuser=True).exists():
            self.stdout.write(
                self.style.SUCCESS("[ensure_admin] A superuser already exists – nothing to do.")
            )
            return

        if target_user:
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
