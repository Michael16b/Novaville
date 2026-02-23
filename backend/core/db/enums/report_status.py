"""
Report status enumeration.
"""

from django.db import models


class ReportStatusEnum(models.TextChoices):
    """Status of a citizen report"""
    RECORDED = 'RECORDED', 'Recorded'
    IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
    RESOLVED = 'RESOLVED', 'Resolved'
