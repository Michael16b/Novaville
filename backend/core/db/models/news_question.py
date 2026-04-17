"""
News question model.
"""

from django.conf import settings
from django.db import models


class NewsQuestionStatus(models.TextChoices):
    """Lifecycle of a citizen message sent to city hall."""

    PENDING = "PENDING", "Pending"
    ANSWERED = "ANSWERED", "Answered"


class NewsQuestion(models.Model):
    """Question sent by a citizen to the municipality from the news page."""

    subject = models.CharField(max_length=255, help_text="Question subject")
    message = models.TextField(help_text="Question body")
    response = models.TextField(blank=True, default="", help_text="Municipal response")
    status = models.CharField(
        max_length=20,
        choices=NewsQuestionStatus.choices,
        default=NewsQuestionStatus.PENDING,
        help_text="Processing status",
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Question creation date",
    )
    answered_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Date when the municipality answered",
    )
    citizen_deleted = models.BooleanField(
        default=False,
        help_text="Whether the citizen removed the discussion from their inbox",
    )
    hidden_by_staff = models.BooleanField(
        default=False,
        help_text="Whether municipal staff archived the answered discussion",
    )
    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="news_questions",
        help_text="Citizen who sent the question",
    )
    answered_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="answered_news_questions",
        help_text="Staff member who answered the question",
    )

    class Meta:
        db_table = "news_questions"
        ordering = ["-created_at"]
        verbose_name = "News question"
        verbose_name_plural = "News questions"

    def __str__(self):
        return f"Question #{self.id} - {self.subject}"
