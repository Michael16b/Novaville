from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0017_survey_multiple_answers_vote_constraints"),
    ]

    operations = [
        migrations.CreateModel(
            name="ReportPhoto",
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
                (
                    "filename",
                    models.CharField(
                        blank=True,
                        default="",
                        help_text="Original uploaded photo filename",
                        max_length=255,
                    ),
                ),
                (
                    "content_type",
                    models.CharField(
                        blank=True,
                        default="application/octet-stream",
                        help_text="Uploaded photo MIME type",
                        max_length=100,
                    ),
                ),
                (
                    "image_data",
                    models.BinaryField(
                        help_text="Uploaded report photo bytes stored in the database",
                    ),
                ),
                (
                    "uploaded_at",
                    models.DateTimeField(
                        auto_now_add=True,
                        help_text="Photo upload date",
                    ),
                ),
                (
                    "report",
                    models.ForeignKey(
                        help_text="Report associated with this photo",
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="photos",
                        to="core.report",
                    ),
                ),
            ],
            options={
                "verbose_name": "Report photo",
                "verbose_name_plural": "Report photos",
                "db_table": "report_photos",
                "ordering": ["uploaded_at"],
            },
        ),
    ]
