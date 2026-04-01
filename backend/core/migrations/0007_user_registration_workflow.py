from django.db import migrations, models


def initialize_user_approval_status(apps, schema_editor):
    User = apps.get_model("core", "User")
    User.objects.filter(is_superuser=True).update(
        approval_status="APPROVED",
        is_active=True,
    )
    User.objects.filter(is_superuser=False).update(
        approval_status="APPROVED",
    )


class Migration(migrations.Migration):
    dependencies = [
        ("core", "0006_alter_usefulinfo_facebook_alter_usefulinfo_instagram_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="address",
            field=models.CharField(
                blank=True,
                default="",
                help_text="User's postal address",
                max_length=255,
            ),
        ),
        migrations.AddField(
            model_name="user",
            name="approval_status",
            field=models.CharField(
                choices=[("PENDING", "Pending"), ("APPROVED", "Approved")],
                default="APPROVED",
                help_text="Approval workflow status for user registrations",
                max_length=20,
            ),
        ),
        migrations.RunPython(
            initialize_user_approval_status,
            migrations.RunPython.noop,
        ),
    ]
