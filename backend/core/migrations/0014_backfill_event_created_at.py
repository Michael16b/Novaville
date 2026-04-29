"""Data migration to backfill Event.created_at from start_date.

Existing events received timezone.now() at migration time (0013). This
migration replaces that placeholder with start_date so that older events
are not incorrectly treated as "recent" in analytics / the dashboard.
"""

from django.db import migrations
from django.db.models import F


def backfill_event_created_at(apps, schema_editor):
    """Set created_at = start_date for events whose created_at > start_date."""
    Event = apps.get_model("core", "Event")
    # Only update rows where the migration timestamp placeholder is newer
    # than the event's own start_date (i.e. pre-existing rows).
    Event.objects.filter(created_at__gt=F("start_date")).update(
        created_at=F("start_date")
    )


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0013_event_created_at"),
    ]

    operations = [
        migrations.RunPython(
            backfill_event_created_at,
            migrations.RunPython.noop,
        ),
    ]
