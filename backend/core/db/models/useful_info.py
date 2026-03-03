from django.conf import settings
from django.db import models



class UsefulInfo(models.Model):
    """Singleton model holding arbitrary JSON data with useful information.

    We only ever create a single row (pk=1) which is returned by the
    API. This allows the administrators to update the information without
    needing to manage multiple entries.
    """

    info = models.JSONField(default=dict, blank=True)

    def __str__(self) -> str:
        return "Useful information"
