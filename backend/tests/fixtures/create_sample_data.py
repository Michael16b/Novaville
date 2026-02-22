#!/usr/bin/env python
"""Create sample data for testing Novaville application"""
import os
import django
from datetime import datetime, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.utils import timezone
from core.models import (
    User, RoleEnum, Neighborhood, ThemeEvent, Report, 
    ProblemTypeEnum, ReportStatusEnum, Survey, SurveyOption, 
    Event, Vote
)

print('🚀 Creating sample data for Novaville...\n')

# 1. Create neighborhoods
print('📍 Creating neighborhoods...')
neighborhoods_data = [
    {'name': 'Centre-Ville', 'postal_code': '75001'},
    {'name': 'Quartier Nord', 'postal_code': '75002'},
    {'name': 'Quartier Sud', 'postal_code': '75003'},
    {'name': 'Zone Industrielle', 'postal_code': '75004'},
]

neighborhoods = []
for data in neighborhoods_data:
    neighborhood, created = Neighborhood.objects.get_or_create(**data)
    neighborhoods.append(neighborhood)
    if created:
        print(f'  ✓ {neighborhood.name}')

# 2. Create event themes
print('\n🎨 Creating event themes...')
themes_data = ['Sport', 'Culture', 'Citoyenneté', 'Environnement', 'Autre']

themes = []
for title in themes_data:
    theme, created = ThemeEvent.objects.get_or_create(title=title)
    themes.append(theme)
    if created:
        print(f'  ✓ {theme.title}')

# 3. Create users
print('\n👥 Creating users...')

# Admin
admin, created = User.objects.get_or_create(
    username='admin',
    defaults={
        'email': 'admin@novaville.fr',
        'first_name': 'Admin',
        'last_name': 'Novaville',
        'role': RoleEnum.GLOBAL_ADMIN,
        'is_staff': True,
        'is_superuser': True,
    }
)
if created:
    admin.set_password('Admin123Pass')
    admin.save()
    print(f'  ✓ Admin user: admin / Admin123Pass')

# Elected official
elected, created = User.objects.get_or_create(
    username='maire',
    defaults={
        'email': 'maire@novaville.fr',
        'first_name': 'Jean',
        'last_name': 'Dupont',
        'role': RoleEnum.ELECTED,
        'is_staff': True,
    }
)
if created:
    elected.set_password('Maire123')
    elected.save()
    print(f'  ✓ Elected official: maire / Maire123')

# Municipal agent
agent, created = User.objects.get_or_create(
    username='agent.services',
    defaults={
        'email': 'agent@novaville.fr',
        'first_name': 'Marie',
        'last_name': 'Martin',
        'role': RoleEnum.AGENT,
        'is_staff': True,
    }
)
if created:
    agent.set_password('Agent123')
    agent.save()
    print(f'  ✓ Municipal agent: agent.services / Agent123')

# Citizens
citizens = []
citizens_data = [
    {'username': 'citoyen1', 'first_name': 'Pierre', 'last_name': 'Durand', 'neighborhood': neighborhoods[0]},
    {'username': 'citoyen2', 'first_name': 'Sophie', 'last_name': 'Bernard', 'neighborhood': neighborhoods[1]},
    {'username': 'citoyen3', 'first_name': 'Lucas', 'last_name': 'Petit', 'neighborhood': neighborhoods[2]},
]

for data in citizens_data:
    citizen, created = User.objects.get_or_create(
        username=data['username'],
        defaults={
            'email': f"{data['username']}@example.com",
            'first_name': data['first_name'],
            'last_name': data['last_name'],
            'role': RoleEnum.CITIZEN,
            'neighborhood': data['neighborhood'],
        }
    )
    if created:
        citizen.set_password('Citoyen123')
        citizen.save()
        citizens.append(citizen)
        print(f"  ✓ Citizen: {data['username']} / Citoyen123")
    else:
        citizens.append(citizen)

# 4. Create reports
print('\n📋 Creating sample reports...')
reports_data = [
    {
        'user': citizens[0] if citizens else admin,
        'problem_type': ProblemTypeEnum.ROADS,
        'description': 'Nid de poule avenue de la République',
        'status': ReportStatusEnum.RECORDED,
        'neighborhood': neighborhoods[0],
    },
    {
        'user': citizens[1] if len(citizens) > 1 else admin,
        'problem_type': ProblemTypeEnum.LIGHTING,
        'description': 'Lampadaire défectueux rue Victor Hugo',
        'status': ReportStatusEnum.IN_PROGRESS,
        'neighborhood': neighborhoods[1],
    },
    {
        'user': citizens[2] if len(citizens) > 2 else admin,
        'problem_type': ProblemTypeEnum.CLEANLINESS,
        'description': 'Dépôt sauvage de déchets parc municipal',
        'status': ReportStatusEnum.RESOLVED,
        'neighborhood': neighborhoods[2],
    },
]

for data in reports_data:
    report, created = Report.objects.get_or_create(
        user=data['user'],
        problem_type=data['problem_type'],
        description=data['description'],
        defaults={
            'status': data['status'],
            'neighborhood': data['neighborhood'],
        }
    )
    if created:
        print(f'  ✓ Report: {report.get_problem_type_display()} - {report.get_status_display()}')

# 5. Create surveys
print('\n📊 Creating sample surveys...')
now = timezone.now()

survey1, created = Survey.objects.get_or_create(
    title='Aménagement de la place centrale',
    defaults={
        'description': 'Quel aménagement préférez-vous pour la place centrale ?',
        'created_by': elected,
        'start_date': now - timedelta(days=5),
        'end_date': now + timedelta(days=25),
    }
)
if created:
    print(f'  ✓ Survey: {survey1.title}')
    SurveyOption.objects.create(survey=survey1, text='Plus d\'espaces verts')
    SurveyOption.objects.create(survey=survey1, text='Aire de jeux pour enfants')
    SurveyOption.objects.create(survey=survey1, text='Parking souterrain')
    print('    ✓ Options created')

survey2, created = Survey.objects.get_or_create(
    title='Horaires de la bibliothèque municipale',
    defaults={
        'description': 'Souhaitez-vous des horaires élargis le samedi ?',
        'created_by': elected,
        'start_date': now,
        'end_date': now + timedelta(days=15),
    }
)
if created:
    print(f'  ✓ Survey: {survey2.title}')
    SurveyOption.objects.create(survey=survey2, text='Oui, fermeture à 18h')
    SurveyOption.objects.create(survey=survey2, text='Oui, fermeture à 20h')
    SurveyOption.objects.create(survey=survey2, text='Non, horaires actuels suffisants')
    print('    ✓ Options created')

# 6. Create events
print('\n📅 Creating sample events...')
events_data = [
    {
        'title': 'Tournoi de football inter-quartiers',
        'description': 'Venez encourager votre quartier lors du tournoi annuel !',
        'start_date': now + timedelta(days=7),
        'end_date': now + timedelta(days=7, hours=5),
        'theme': themes[0],  # Sport
        'created_by': elected,
    },
    {
        'title': 'Festival de musique d\'été',
        'description': 'Trois jours de concerts gratuits au parc municipal',
        'start_date': now + timedelta(days=30),
        'end_date': now + timedelta(days=32),
        'theme': themes[1],  # Culture
        'created_by': elected,
    },
    {
        'title': 'Conseil municipal public',
        'description': 'Séance publique du conseil municipal - Tout public bienvenu',
        'start_date': now + timedelta(days=14),
        'end_date': now + timedelta(days=14, hours=3),
        'theme': themes[2],  # Citoyenneté
        'created_by': elected,
    },
    {
        'title': 'Journée nettoyage citoyen',
        'description': 'Participez au grand nettoyage de printemps de la ville',
        'start_date': now + timedelta(days=21),
        'end_date': now + timedelta(days=21, hours=4),
        'theme': themes[3],  # Environnement
        'created_by': agent,
    },
]

for data in events_data:
    event, created = Event.objects.get_or_create(
        title=data['title'],
        defaults=data
    )
    if created:
        print(f'  ✓ Event: {event.title}')

print('\n✅ Sample data created successfully!')
print('\n📖 Access the API documentation at: http://localhost:8000/api/docs/')
print('🔐 Login credentials:')
print('   - Admin: admin / Admin123Pass')
print('   - Elected: maire / Maire123')
print('   - Agent: agent.services / Agent123')
print('   - Citizen: citoyen1 / Citoyen123')
