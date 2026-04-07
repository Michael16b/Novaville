from django.db import migrations, models


def _get_report_columns(schema_editor):
    connection = schema_editor.connection
    with connection.cursor() as cursor:
        description = connection.introspection.get_table_description(
            cursor,
            "reports",
        )
    return {column.name for column in description}


def align_report_address_column(apps, schema_editor):
    columns = _get_report_columns(schema_editor)
    if "address" in columns and "exact_address" not in columns:
        schema_editor.execute(
            'ALTER TABLE reports RENAME COLUMN address TO exact_address'
        )


def reverse_align_report_address_column(apps, schema_editor):
    columns = _get_report_columns(schema_editor)
    if "exact_address" in columns and "address" not in columns:
        schema_editor.execute(
            'ALTER TABLE reports RENAME COLUMN exact_address TO address'
        )


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0008_report_address"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    align_report_address_column,
                    reverse_align_report_address_column,
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
