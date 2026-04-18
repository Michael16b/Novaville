from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0011_survey_address"),
    ]

    operations = [
        migrations.AlterField(
            model_name="survey",
            name="address",
            field=models.CharField(
                help_text="Exact address targeted by the survey",
                max_length=255,
            ),
        ),
    ]
