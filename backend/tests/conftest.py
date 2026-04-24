"""Pytest configuration and fixtures for Novaville tests"""
import pytest
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from core.db.models import (
    Neighborhood, ThemeEvent, Report, Survey, 
    SurveyOption, Event, Vote,
    RoleEnum, ProblemTypeEnum, ReportStatusEnum, ThemeEnum
)
from datetime import timedelta
from django.utils import timezone

User = get_user_model()


@pytest.fixture
def api_client():
    """DRF API client"""
    return APIClient()


@pytest.fixture
def neighborhood():
    """Create a test neighborhood"""
    return Neighborhood.objects.create(
        name="Test Neighborhood",
        postal_code="75001"
    )


@pytest.fixture
def theme():
    """Create a test event theme"""
    return ThemeEvent.objects.create(title=ThemeEnum.SPORT)


@pytest.fixture
def citizen_user(neighborhood):
    """Create a test citizen user"""
    user = User.objects.create_user(
        username="testcitizen",
        email="citizen@test.com",
        password="TestPass123",
        first_name="Test",
        last_name="Citizen",
        role=RoleEnum.CITIZEN,
        neighborhood=neighborhood
    )
    return user


@pytest.fixture
def elected_user():
    """Create a test elected official user"""
    user = User.objects.create_user(
        username="testelected",
        email="elected@test.com",
        password="TestPass123",
        first_name="Test",
        last_name="Elected",
        role=RoleEnum.ELECTED,
        is_staff=True
    )
    return user


@pytest.fixture
def agent_user():
    """Create a test municipal agent user"""
    user = User.objects.create_user(
        username="testagent",
        email="agent@test.com",
        password="TestPass123",
        first_name="Test",
        last_name="Agent",
        role=RoleEnum.AGENT,
        is_staff=True
    )
    return user


@pytest.fixture
def admin_user():
    """Create a test global admin user"""
    user = User.objects.create_superuser(
        username="testadmin",
        email="admin@test.com",
        password="TestPass123",
        first_name="Test",
        last_name="Admin",
        role=RoleEnum.GLOBAL_ADMIN
    )
    return user


@pytest.fixture
def report(citizen_user, neighborhood):
    """Create a test report"""
    return Report.objects.create(
        user=citizen_user,
        title="Test report",
        problem_type=ProblemTypeEnum.ROADS,
        description="Test report description",
        address="12 rue de la Paix",
        status=ReportStatusEnum.RECORDED,
        neighborhood=neighborhood
    )


@pytest.fixture
def other_citizen_client(neighborhood):
    """API client authenticated as a second citizen who does not own any reports"""
    api_client = APIClient()
    other_citizen = User.objects.create_user(
        username="othercitizen",
        email="othercitizen@test.com",
        password="TestPass123",
        role=RoleEnum.CITIZEN,
        neighborhood=neighborhood,
    )
    api_client.force_authenticate(user=other_citizen)
    return api_client


@pytest.fixture
def survey(elected_user):
    """Create a test survey"""
    return Survey.objects.create(
        title="Test Survey",
        description="Test survey description",
        address="1 place de la Mairie, Novaville",
        created_by=elected_user,
        start_date=timezone.now(),
        end_date=timezone.now() + timedelta(days=7)
    )


@pytest.fixture
def survey_with_options(survey):
    """Create a survey with options"""
    option1 = SurveyOption.objects.create(survey=survey, text="Option 1")
    option2 = SurveyOption.objects.create(survey=survey, text="Option 2")
    return survey


@pytest.fixture
def event(elected_user, theme):
    """Create a test event"""
    return Event.objects.create(
        title="Test Event",
        description="Test event description",
        start_date=timezone.now() + timedelta(days=1),
        end_date=timezone.now() + timedelta(days=1, hours=2),
        theme=theme,
        created_by=elected_user
    )


@pytest.fixture
def authenticated_client(api_client, citizen_user):
    """API client authenticated as citizen"""
    api_client.force_authenticate(user=citizen_user)
    return api_client


@pytest.fixture
def admin_client(api_client, admin_user):
    """API client authenticated as admin"""
    api_client.force_authenticate(user=admin_user)
    return api_client


@pytest.fixture
def elected_client(api_client, elected_user):
    """API client authenticated as elected official"""
    api_client.force_authenticate(user=elected_user)
    return api_client


def get_response_data(response):
    """Helper to extract data from paginated or non-paginated response"""
    if isinstance(response.data, dict) and 'results' in response.data:
        return response.data['results']
    return response.data
