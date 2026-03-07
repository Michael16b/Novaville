# Migration: move citizen_target from Report to Survey, add title to Report,
# remove is_active from User serializer (no model change needed — is_active
# is inherited from AbstractUser and stays in DB, just hidden from API).

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0003_alter_usefulinfo_opening_hours'),
    ]

    operations = [
        # 1. Add title field to Report
        migrations.AddField(
            model_name='report',
            name='title',
            field=models.CharField(
                default='',
                help_text='Title of the report',
                max_length=255,
            ),
        ),
        # 2. Add citizen_target field to Survey
        migrations.AddField(
            model_name='survey',
            name='citizen_target',
            field=models.CharField(
                blank=True,
                choices=[
                    ('CITIZEN', 'Citizen'),
                    ('ELECTED', 'Elected Official'),
                    ('AGENT', 'Municipal Agent'),
                    ('GLOBAL_ADMIN', 'Global Administrator'),
                ],
                help_text='Target role for this survey',
                max_length=20,
                null=True,
            ),
        ),
        # 3. Remove citizen_target field from Report
        migrations.RemoveField(
            model_name='report',
            name='citizen_target',
        ),
    ]

