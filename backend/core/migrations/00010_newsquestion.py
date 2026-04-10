from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0008_report_address"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="NewsQuestion",
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
                ("subject", models.CharField(help_text="Question subject", max_length=255)),
                ("message", models.TextField(help_text="Question body")),
                (
                    "response",
                    models.TextField(
                        blank=True,
                        default="",
                        help_text="Municipal response",
                    ),
                ),
                (
                    "status",
                    models.CharField(
                        choices=[("PENDING", "Pending"), ("ANSWERED", "Answered")],
                        default="PENDING",
                        help_text="Processing status",
                        max_length=20,
                    ),
                ),
                (
                    "created_at",
                    models.DateTimeField(
                        auto_now_add=True,
                        help_text="Question creation date",
                    ),
                ),
                (
                    "answered_at",
                    models.DateTimeField(
                        blank=True,
                        help_text="Date when the municipality answered",
                        null=True,
                    ),
                ),
                (
                    "answered_by",
                    models.ForeignKey(
                        blank=True,
                        help_text="Staff member who answered the question",
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="answered_news_questions",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "citizen",
                    models.ForeignKey(
                        help_text="Citizen who sent the question",
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="news_questions",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "verbose_name": "News question",
                "verbose_name_plural": "News questions",
                "db_table": "news_questions",
                "ordering": ["-created_at"],
            },
        ),
    ]
