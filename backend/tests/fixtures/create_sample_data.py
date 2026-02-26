#!/usr/bin/env python
"""Create sample data for testing Novaville application"""
import os
import django
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.utils import timezone
from core.models import (
    User, RoleEnum, Neighborhood, ThemeEvent, Report, 
    ProblemTypeEnum, ReportStatusEnum, Survey, SurveyOption, 
    Event, Vote
)

print('🚀 Creating sample data for Novaville...\n')

RESET_PASSWORDS = os.getenv('RESET_FIXTURE_PASSWORDS', '1') == '1'
TARGET_COUNT = 25
RESET_FIXTURE_TABLES = os.getenv('RESET_FIXTURE_TABLES', '1') == '1'


def upsert_user(username, defaults, password, label):
    user, created = User.objects.update_or_create(
        username=username,
        defaults=defaults,
    )
    if RESET_PASSWORDS:
        user.set_password(password)
        user.save(update_fields=['password'])
    print(f"  ✓ {label}: {username} / {password} ({'created' if created else 'updated'})")
    return user


def ensure_survey_options(survey, options):
    ensured_options = []
    for text in options:
        option, _ = SurveyOption.objects.get_or_create(survey=survey, text=text)
        ensured_options.append(option)
    return ensured_options


if RESET_FIXTURE_TABLES:
    print('🧹 Resetting fixture tables before insert...')
    Vote.objects.all().delete()
    Report.objects.all().delete()
    SurveyOption.objects.all().delete()
    Survey.objects.all().delete()
    Event.objects.all().delete()
    ThemeEvent.objects.all().delete()
    Neighborhood.objects.all().delete()

# 1. Create neighborhoods
print('📍 Creating neighborhoods...')
neighborhoods_data = [
    {'name': f'Quartier {index:02d}', 'postal_code': f'75{index:03d}'}
    for index in range(1, TARGET_COUNT + 1)
]

neighborhoods = []
for data in neighborhoods_data:
    neighborhood, created = Neighborhood.objects.update_or_create(
        name=data['name'],
        defaults={'postal_code': data['postal_code']},
    )
    neighborhoods.append(neighborhood)
    print(f"  ✓ {neighborhood.name} ({'created' if created else 'updated'})")

# 2. Create event themes
print('\n🎨 Creating event themes...')
themes_data = [
    'Sport',
    'Culture',
    'Citoyenneté',
    'Environnement',
    'Autre',
] + [f'Thème {index:02d}' for index in range(6, TARGET_COUNT + 1)]

themes = []
for title in themes_data:
    theme, created = ThemeEvent.objects.get_or_create(title=title)
    themes.append(theme)
    print(f"  ✓ {theme.title} ({'created' if created else 'exists'})")

# 3. Create users
print('\n👥 Creating users...')

# Admin
admin = upsert_user(
    username='admin',
    defaults={
        'email': 'admin@novaville.fr',
        'first_name': 'Admin',
        'last_name': 'Novaville',
        'role': RoleEnum.GLOBAL_ADMIN,
        'is_staff': True,
        'is_superuser': True,
    },
    password='Admin123Pass',
    label='Admin user',
)

# Elected official
elected = upsert_user(
    username='maire',
    defaults={
        'email': 'maire@novaville.fr',
        'first_name': 'Jean',
        'last_name': 'Dupont',
        'role': RoleEnum.ELECTED,
        'is_staff': True,
        'is_superuser': False,
    },
    password='Maire123',
    label='Elected official',
)

# Municipal agent
agent = upsert_user(
    username='agent.services',
    defaults={
        'email': 'agent@novaville.fr',
        'first_name': 'Marie',
        'last_name': 'Martin',
        'role': RoleEnum.AGENT,
        'is_staff': True,
        'is_superuser': False,
    },
    password='Agent123',
    label='Municipal agent',
)

# Citizens
citizens = []
citizen_first_names = [
    'Pierre', 'Sophie', 'Lucas', 'Emma', 'Louis', 'Chloé', 'Hugo', 'Lina', 'Noah', 'Léa',
    'Jules', 'Inès', 'Paul', 'Sarah', 'Adam', 'Nina', 'Tom', 'Zoé', 'Léo', 'Mila',
    'Gabriel', 'Eva', 'Arthur', 'Manon', 'Nathan',
]
citizen_last_names = [
    'Durand', 'Bernard', 'Petit', 'Robert', 'Richard', 'Moreau', 'Simon', 'Laurent', 'Lefebvre', 'Michel',
    'Garcia', 'David', 'Bertrand', 'Roux', 'Vincent', 'Fournier', 'Morel', 'Girard', 'Andre', 'Lefevre',
    'Mercier', 'Dupuis', 'Lambert', 'Bonnet', 'Francois',
]
citizens_data = []
for index in range(1, TARGET_COUNT - 2):
    citizens_data.append(
        {
            'username': f'citoyen{index}',
            'first_name': citizen_first_names[(index - 1) % len(citizen_first_names)],
            'last_name': citizen_last_names[(index - 1) % len(citizen_last_names)],
            'neighborhood': neighborhoods[(index - 1) % len(neighborhoods)],
        }
    )

for data in citizens_data:
    citizen = upsert_user(
        username=data['username'],
        defaults={
            'email': f"{data['username']}@example.com",
            'first_name': data['first_name'],
            'last_name': data['last_name'],
            'role': RoleEnum.CITIZEN,
            'neighborhood': data['neighborhood'],
            'is_staff': False,
            'is_superuser': False,
        },
        password='Citoyen123',
        label='Citizen',
    )
    citizens.append(citizen)

# 4. Create reports
print('\n📋 Creating sample reports...')
problem_types = [
    ProblemTypeEnum.ROADS,
    ProblemTypeEnum.LIGHTING,
    ProblemTypeEnum.CLEANLINESS,
]
report_statuses = [
    ReportStatusEnum.RECORDED,
    ReportStatusEnum.IN_PROGRESS,
    ReportStatusEnum.RESOLVED,
]

reports_data = []
for index in range(1, TARGET_COUNT + 1):
    reporter = citizens[(index - 1) % len(citizens)] if citizens else admin
    problem_type = problem_types[(index - 1) % len(problem_types)]
    report_status = report_statuses[(index - 1) % len(report_statuses)]
    neighborhood = neighborhoods[(index - 1) % len(neighborhoods)]
    reports_data.append(
        {
            'user': reporter,
            'problem_type': problem_type,
            'description': f'Signalement #{index:02d} dans {neighborhood.name.lower()}',
            'status': report_status,
            'neighborhood': neighborhood,
        }
    )

for data in reports_data:
    report, created = Report.objects.update_or_create(
        user=data['user'],
        problem_type=data['problem_type'],
        description=data['description'],
        defaults={
            'status': data['status'],
            'neighborhood': data['neighborhood'],
        }
    )
    print(
        f"  ✓ Report: {report.get_problem_type_display()} - {report.get_status_display()} "
        f"({'created' if created else 'updated'})"
    )

# 5. Create surveys
print('\n📊 Creating sample surveys...')
now = timezone.now()
surveys = []
survey_options_map = {}
for index in range(1, TARGET_COUNT + 1):
    survey, created = Survey.objects.update_or_create(
        title=f'Consultation citoyenne #{index:02d}',
        defaults={
            'description': f'Question citoyenne #{index:02d} sur les priorités de la commune.',
            'created_by': elected,
            'start_date': now - timedelta(days=(index % 10)),
            'end_date': now + timedelta(days=30 + index),
        }
    )
    print(f"  ✓ Survey: {survey.title} ({'created' if created else 'updated'})")
    options = ensure_survey_options(
        survey,
        [
            f'Option A - Sondage {index:02d}',
            f'Option B - Sondage {index:02d}',
            f'Option C - Sondage {index:02d}',
        ],
    )
    survey_options_map[survey.id] = options
    surveys.append(survey)
    print('    ✓ Options ensured')

# 6. Create events
print('\n📅 Creating sample events...')
events_data = []
for index in range(1, TARGET_COUNT + 1):
    start_date = now + timedelta(days=index * 2)
    events_data.append(
        {
            'title': f'Événement municipal #{index:02d}',
            'description': f'Activité citoyenne planifiée pour la session #{index:02d}.',
            'start_date': start_date,
            'end_date': start_date + timedelta(hours=3),
            'theme': themes[(index - 1) % len(themes)],
            'created_by': elected if index % 3 else agent,
        }
    )

for data in events_data:
    event, created = Event.objects.update_or_create(
        title=data['title'],
        defaults=data
    )
    print(f"  ✓ Event: {event.title} ({'created' if created else 'updated'})")

# 7. Create votes
print('\n🗳️ Creating votes...')
for index in range(1, TARGET_COUNT + 1):
    survey = surveys[(index - 1) % len(surveys)]
    voter = citizens[(index - 1) % len(citizens)] if citizens else admin
    survey_options = survey_options_map[survey.id]
    option = survey_options[(index - 1) % len(survey_options)]
    vote, created = Vote.objects.update_or_create(
        user=voter,
        survey=survey,
        defaults={'option': option},
    )
    print(f"  ✓ Vote: {vote.user.username} -> {vote.survey.title} ({'created' if created else 'updated'})")

print('\n✅ Sample data created successfully!')
print('\n📖 Access the API documentation at: http://localhost:8000/api/docs/')
print('🔐 Login credentials:')
print('   - Admin: admin / Admin123Pass')
print('   - Elected: maire / Maire123')
print('   - Agent: agent.services / Agent123')
print('   - Citizen: citoyen1 / Citoyen123')
