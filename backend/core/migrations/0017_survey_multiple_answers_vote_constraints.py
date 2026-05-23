from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0016_survey_neighborhood"),
    ]

    operations = [
        migrations.AddField(
            model_name="survey",
            name="multiple_answers",
            field=models.BooleanField(
                default=False,
                help_text="Whether users can select several options for this survey",
            ),
        ),
        migrations.AlterUniqueTogether(
            name="vote",
            unique_together=set(),
        ),
        migrations.AddConstraint(
            model_name="vote",
            constraint=models.UniqueConstraint(
                fields=("user", "survey", "option"),
                name="unique_vote_per_user_survey_option",
            ),
        ),
    ]
