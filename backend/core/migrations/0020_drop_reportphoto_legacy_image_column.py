from django.db import migrations


def drop_legacy_report_photo_image_column(apps, schema_editor):
    """Drop the legacy FileField column left by early report photo migrations."""
    table_name = "report_photos"
    connection = schema_editor.connection

    with connection.cursor() as cursor:
        table_names = connection.introspection.table_names(cursor)
        if table_name not in table_names:
            return

        columns = {
            column.name
            for column in connection.introspection.get_table_description(
                cursor,
                table_name,
            )
        }
        if "image" not in columns:
            return

        quoted_table = schema_editor.quote_name(table_name)
        quoted_column = schema_editor.quote_name("image")
        cursor.execute(f"ALTER TABLE {quoted_table} DROP COLUMN {quoted_column}")


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0019_ensure_reportphoto_db_storage"),
    ]

    operations = [
        migrations.RunPython(
            drop_legacy_report_photo_image_column,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
