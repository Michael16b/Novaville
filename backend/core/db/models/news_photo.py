"""
News photo model.
"""

from django.conf import settings
from django.db import models


class NewsPhoto(models.Model):
    """Photo showcased on the news page."""

    title = models.CharField(max_length=255, help_text="Photo title")
    subtitle = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Optional photo subtitle",
    )
    image_url = models.URLField(help_text="Remote image URL")
    created_at = models.DateTimeField(auto_now_add=True, help_text="Creation date")
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="news_photos",
        help_text="User who added the photo",
    )

    class Meta:
        db_table = "news_photos"
        ordering = ["-created_at"]
        verbose_name = "News photo"
        verbose_name_plural = "News photos"

    def __str__(self):
        return self.title
