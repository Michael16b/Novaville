from django.db import migrations


def ensure_report_photo_db_storage(apps, schema_editor):
    """Repair databases where 0018 was applied before DB-backed photos."""
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

        if connection.vendor == "postgresql":
            quoted_table = schema_editor.quote_name(table_name)
            if "filename" not in columns:
                cursor.execute(
                    f"ALTER TABLE {quoted_table} "
                    "ADD COLUMN filename varchar(255) NOT NULL DEFAULT ''"
                )
            if "content_type" not in columns:
                cursor.execute(
                    f"ALTER TABLE {quoted_table} "
                    "ADD COLUMN content_type varchar(100) NOT NULL "
                    "DEFAULT 'application/octet-stream'"
                )
            if "image_data" not in columns:
                cursor.execute(
                    f"ALTER TABLE {quoted_table} "
                    "ADD COLUMN image_data bytea NOT NULL DEFAULT decode('', 'hex')"
                )
            return

        ReportPhoto = apps.get_model("core", "ReportPhoto")
        fields_by_name = {
            field.name: field
            for field in ReportPhoto._meta.local_fields
        }
        for field_name in ("filename", "content_type", "image_data"):
            if field_name not in columns:
                schema_editor.add_field(ReportPhoto, fields_by_name[field_name])


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0018_reportphoto"),
    ]

    operations = [
        migrations.RunPython(
            ensure_report_photo_db_storage,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
