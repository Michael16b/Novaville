"""
Survey-related models.
"""

from django.conf import settings
from django.db import models


class Survey(models.Model):
    """Public survey/consultation"""
    title = models.CharField(max_length=255, help_text="Survey title")
    description = models.TextField(help_text="Survey description")
    created_at = models.DateTimeField(auto_now_add=True, help_text="Survey creation date")
    start_date = models.DateTimeField(help_text="Survey start date")
    end_date = models.DateTimeField(help_text="Survey end date")
    # Foreign keys
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_surveys',
        help_text="User who created the survey"
    )
    
    class Meta:
        db_table = 'surveys'
        ordering = ['-created_at']
        verbose_name = 'Survey'
        verbose_name_plural = 'Surveys'
    
    def __str__(self):
        return f"{self.title}"
    
    @property
    def is_active(self):
        from django.utils import timezone
        now = timezone.now()
        return self.start_date <= now <= self.end_date


class SurveyOption(models.Model):
    """Option/choice for a survey"""
    survey = models.ForeignKey(
        'Survey',
        on_delete=models.CASCADE,
        related_name='options',
        help_text="Survey this option belongs to"
    )
    text = models.CharField(max_length=255, help_text="Option text")
    
    class Meta:
        db_table = 'survey_options'
        ordering = ['id']
        verbose_name = 'Survey Option'
        verbose_name_plural = 'Survey Options'
    
    def __str__(self):
        return f"{self.survey.title} - {self.text}"


class Vote(models.Model):
    """User vote on a survey"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="User who voted"
    )
    survey = models.ForeignKey(
        'Survey',
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="Survey being voted on"
    )
    option = models.ForeignKey(
        'SurveyOption',
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="Selected option"
    )
    created_at = models.DateTimeField(auto_now_add=True, help_text="Vote timestamp")
    
    class Meta:
        db_table = 'votes'
        ordering = ['-created_at']
        verbose_name = 'Vote'
        verbose_name_plural = 'Votes'
        # Ensure a user can only vote once per survey
        unique_together = [['user', 'survey']]
    
    def __str__(self):
        return f"{self.user.username} voted on {self.survey.title}"
