# Generated manually to add UsefulInfo model
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='UsefulInfo',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('city_hall_name', models.CharField(max_length=255)),
                ('address_line1', models.CharField(max_length=255)),
                ('address_line2', models.CharField(blank=True, default='', max_length=255)),
                ('postal_code', models.CharField(max_length=10)),
                ('city', models.CharField(max_length=100)),
                ('phone', models.CharField(max_length=30)),
                ('email', models.EmailField(max_length=254)),
                ('website', models.URLField()),
                ('opening_hours', models.JSONField(default=dict, blank=True)),
            ],
            options={
                'db_table': 'useful_info',
            },
        ),
    ]
