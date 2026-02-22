#!/usr/bin/env python
"""Create initial data for Novaville"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from core.models import User, RoleEnum, Neighborhood, ThemeEvent

# Create superuser
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(
        username='admin',
        email='admin@novaville.fr',
        password='Admin123Pass',
        first_name='Admin',
        last_name='Novaville',
        role=RoleEnum.GLOBAL_ADMIN
    )
    print('✓ Superuser created: admin / Admin123Pass')
else:
    print('✓ Superuser already exists')

# Create some neighborhoods
neighborhoods_data = [
    {'name': 'Centre-Ville', 'postal_code': '75001'},
    {'name': 'Quartier Nord', 'postal_code': '75002'},
    {'name': 'Quartier Sud', 'postal_code': '75003'},
    {'name': 'Zone Industrielle', 'postal_code': '75004'},
]

for data in neighborhoods_data:
    neighborhood, created = Neighborhood.objects.get_or_create(**data)
    if created:
        print(f'✓ Neighborhood created: {neighborhood.name}')

# Create event themes
themes_data = ['Sport', 'Culture', 'Citoyenneté', 'Environnement', 'Autre']

for title in themes_data:
    theme, created = ThemeEvent.objects.get_or_create(title=title)
    if created:
        print(f'✓ Theme created: {theme.title}')

print('\n✅ Initial data created successfully!')
