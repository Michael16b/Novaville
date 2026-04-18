"""
Event-related models.
"""

from django.conf import settings
from django.db import models


class ThemeEvent(models.Model):
    """Event theme/category"""
    title = models.CharField(max_length=100, unique=True, help_text="Theme title")
    
    class Meta:
        db_table = 'theme_events'
        ordering = ['title']
        verbose_name = 'Event Theme'
        verbose_name_plural = 'Event Themes'
    
    def __str__(self):
        return self.title


class Event(models.Model):
    """City or association event"""
    title = models.CharField(max_length=255, help_text="Event title")
    description = models.TextField(help_text="Event description")
    created_at = models.DateTimeField(auto_now_add=True, help_text="Event creation date")
    start_date = models.DateTimeField(help_text="Event start date and time")
    end_date = models.DateTimeField(help_text="Event end date and time")
    # Foreign keys
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_events',
        help_text="User who created the event"
    )
    theme = models.ForeignKey(
        'ThemeEvent',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='events',
        help_text="Event theme/category"
    )
    
    class Meta:
        db_table = 'events'
        ordering = ['start_date']
        verbose_name = 'Event'
        verbose_name_plural = 'Events'
    
    def __str__(self):
        return f"{self.title} ({self.start_date.strftime('%Y-%m-%d')})"
