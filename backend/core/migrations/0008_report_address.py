from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0007_user_registration_workflow"),
    ]

    operations = [
        migrations.AddField(
            model_name="report",
            name="address",
            field=models.CharField(
                blank=True,
                default="",
                help_text="Exact address where the issue was reported",
                max_length=255,
            ),
        ),
    ]
