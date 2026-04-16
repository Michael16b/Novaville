from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0009_newsquestion"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name="newsquestion",
            name="citizen_deleted",
            field=models.BooleanField(
                default=False,
                help_text="Whether the citizen removed the discussion from their inbox",
            ),
        ),
        migrations.AddField(
            model_name="newsquestion",
            name="hidden_by_staff",
            field=models.BooleanField(
                default=False,
                help_text="Whether municipal staff archived the answered discussion",
            ),
        ),
        migrations.CreateModel(
            name="NewsPhoto",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("title", models.CharField(help_text="Photo title", max_length=255)),
                (
                    "subtitle",
                    models.CharField(
                        blank=True,
                        default="",
                        help_text="Optional photo subtitle",
                        max_length=255,
                    ),
                ),
                ("image_url", models.URLField(help_text="Remote image URL")),
                (
                    "created_at",
                    models.DateTimeField(auto_now_add=True, help_text="Creation date"),
                ),
                (
                    "created_by",
                    models.ForeignKey(
                        blank=True,
                        help_text="User who added the photo",
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="news_photos",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "verbose_name": "News photo",
                "verbose_name_plural": "News photos",
                "db_table": "news_photos",
                "ordering": ["-created_at"],
            },
        ),
    ]
