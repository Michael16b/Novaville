from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0010_newsphoto_newsquestion_visibility"),
    ]

    operations = [
        migrations.AddField(
            model_name="survey",
            name="address",
            field=models.CharField(
                blank=True,
                default="",
                help_text="Exact address targeted by the survey",
                max_length=255,
            ),
        ),
    ]

