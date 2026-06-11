from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0015_user_first_login_completed"),
    ]

    operations = [
        migrations.AlterField(
            model_name="survey",
            name="address",
            field=models.CharField(
                blank=True,
                default="",
                help_text="Legacy exact address targeted by the survey",
                max_length=255,
            ),
        ),
        migrations.AddField(
            model_name="survey",
            name="neighborhood",
            field=models.ForeignKey(
                blank=True,
                help_text="Neighborhood targeted by the survey. Empty means all neighborhoods.",
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="surveys",
                to="core.neighborhood",
            ),
        ),
    ]
