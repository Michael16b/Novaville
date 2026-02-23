"""
Neighborhood model.
"""

from django.db import models


class Neighborhood(models.Model):
    """Neighborhood/District within the city"""
    name = models.CharField(max_length=255, help_text="Neighborhood name")
    postal_code = models.CharField(max_length=10, help_text="Postal code")
    
    class Meta:
        db_table = 'neighborhoods'
        ordering = ['name']
        verbose_name = 'Neighborhood'
        verbose_name_plural = 'Neighborhoods'
    
    def __str__(self):
        return f"{self.name} ({self.postal_code})"
