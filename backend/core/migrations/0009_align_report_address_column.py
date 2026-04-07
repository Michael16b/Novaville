from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0008_report_address"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunSQL(
                    sql="""
                    DO $$
                    BEGIN
                        IF EXISTS (
                            SELECT 1
                            FROM information_schema.columns
                            WHERE table_name = 'reports' AND column_name = 'address'
                        ) AND NOT EXISTS (
                            SELECT 1
                            FROM information_schema.columns
                            WHERE table_name = 'reports' AND column_name = 'exact_address'
                        ) THEN
                            ALTER TABLE reports RENAME COLUMN address TO exact_address;
                        END IF;
                    END
                    $$;
                    """,
                    reverse_sql="""
                    DO $$
                    BEGIN
                        IF EXISTS (
                            SELECT 1
                            FROM information_schema.columns
                            WHERE table_name = 'reports' AND column_name = 'exact_address'
                        ) AND NOT EXISTS (
                            SELECT 1
                            FROM information_schema.columns
                            WHERE table_name = 'reports' AND column_name = 'address'
                        ) THEN
                            ALTER TABLE reports RENAME COLUMN exact_address TO address;
                        END IF;
                    END
                    $$;
                    """,
                ),
            ],
            state_operations=[
                migrations.AlterField(
                    model_name="report",
                    name="address",
                    field=models.CharField(
                        blank=True,
                        db_column="exact_address",
                        default="",
                        help_text="Exact address where the issue was reported",
                        max_length=255,
                    ),
                ),
            ],
        ),
    ]
