"""
Media model.
"""

from django.db import models


class Media(models.Model):
    """Media attached to a report"""
    file = models.FileField(upload_to='reports/media/', help_text="File uploaded")
    created_at = models.DateTimeField(auto_now_add=True, help_text="Upload date")
    
    # Foreign keys
    report = models.ForeignKey(
        'Report',
        on_delete=models.CASCADE,
        related_name='media',
        help_text="Report this media belongs to"
    )
    
    class Meta:
        db_table = 'media'
        ordering = ['-created_at']
        verbose_name = 'Media'
        verbose_name_plural = 'Media'
    
    def __str__(self):
        return f"Media #{self.id} for Report #{self.report_id}"
