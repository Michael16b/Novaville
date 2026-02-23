"""
User role enumeration.
"""

from django.db import models


class RoleEnum(models.TextChoices):
    """User roles in the system"""
    CITIZEN = 'CITIZEN', 'Citizen'
    ELECTED = 'ELECTED', 'Elected Official'
    AGENT = 'AGENT', 'Municipal Agent'
    GLOBAL_ADMIN = 'GLOBAL_ADMIN', 'Global Administrator'
