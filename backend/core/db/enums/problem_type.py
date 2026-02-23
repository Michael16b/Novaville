"""
Problem type enumeration for reports.
"""

from django.db import models


class ProblemTypeEnum(models.TextChoices):
    """Types of problems that can be reported"""
    ROADS = 'ROADS', 'Roads'
    LIGHTING = 'LIGHTING', 'Lighting'
    CLEANLINESS = 'CLEANLINESS', 'Cleanliness'
