from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0007_user_registration_workflow"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunSQL(
                    sql="""
                    ALTER TABLE reports
                    ADD COLUMN IF NOT EXISTS exact_address varchar(255) NOT NULL DEFAULT '';
                    ALTER TABLE reports
                    ALTER COLUMN exact_address DROP DEFAULT;
                    """,
                    reverse_sql="""
                    ALTER TABLE reports
                    DROP COLUMN IF EXISTS exact_address;
                    """,
                ),
            ],
            state_operations=[
                migrations.AddField(
                    model_name="report",
                    name="exact_address",
                    field=models.CharField(
                        blank=True,
                        default="",
                        help_text="Exact address where the issue was reported",
                        max_length=255,
                    ),
                ),
            ],
        ),
    ]
