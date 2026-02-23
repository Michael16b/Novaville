"""
Event theme enumeration.
"""

from django.db import models


class ThemeEnum(models.TextChoices):
    """Event themes"""
    SPORT = 'SPORT', 'Sport'
    CULTURE = 'CULTURE', 'Culture'
    CITIZENSHIP = 'CITIZENSHIP', 'Citizenship'
    ENVIRONMENT = 'ENVIRONMENT', 'Environment'
    OTHER = 'OTHER', 'Other'
