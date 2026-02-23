"""
Report model.
"""

from django.conf import settings
from django.db import models

from core.db.enums import ProblemTypeEnum, ReportStatusEnum, RoleEnum


class Report(models.Model):
    """Citizen report about city issues"""
    problem_type = models.CharField(
        max_length=20,
        choices=ProblemTypeEnum.choices,
        help_text="Type of problem reported"
    )
    description = models.TextField(help_text="Detailed description of the issue")
    created_at = models.DateTimeField(auto_now_add=True, help_text="Report creation date")
    status = models.CharField(
        max_length=20,
        choices=ReportStatusEnum.choices,
        default=ReportStatusEnum.RECORDED,
        help_text="Current status of the report"
    )
    citizen_target = models.CharField(
        max_length=20,
        choices=RoleEnum.choices,
        blank=True,
        null=True,
        help_text="Target role for this report"
    )
    # Foreign keys
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports',
        help_text="User who created the report"
    )
    neighborhood = models.ForeignKey(
        'Neighborhood',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reports',
        help_text="Neighborhood where the issue was reported"
    )
    
    class Meta:
        db_table = 'reports'
        ordering = ['-created_at']
        verbose_name = 'Report'
        verbose_name_plural = 'Reports'
    
    def __str__(self):
        return f"Report #{self.id} - {self.get_problem_type_display()} ({self.get_status_display()})"
