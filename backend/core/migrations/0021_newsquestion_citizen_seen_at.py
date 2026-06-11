from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0020_drop_reportphoto_legacy_image_column"),
    ]

    operations = [
        migrations.AddField(
            model_name="newsquestion",
            name="citizen_seen_at",
            field=models.DateTimeField(
                blank=True,
                help_text="Date when the citizen read the municipal response",
                null=True,
            ),
        ),
    ]
