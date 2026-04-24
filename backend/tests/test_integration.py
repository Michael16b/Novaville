"""Simplified integration tests for Novaville API"""
import pytest
from rest_framework import status
from datetime import timedelta
from django.utils import timezone
from core.db.models import Report, ProblemTypeEnum, ReportStatusEnum

pytestmark = pytest.mark.django_db


class TestAuthenticationFlow:
    """Test authentication and basic flows"""
    
    def test_login_returns_tokens(self, api_client, citizen_user):
        """Test login returns access and refresh tokens"""
        response = api_client.post(
            "/api/v1/auth/token/",
            {"username": "testcitizen", "password": "TestPass123"},
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data
        assert "refresh" in response.data
    
    def test_me_endpoint_returns_user(self, authenticated_client, citizen_user):
        """Test /me/ returns current user"""
        response = authenticated_client.get("/api/v1/users/me/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["username"] == "testcitizen"


class TestReportsFlow:
    """Test reports CRUD operations"""
    
    def test_citizen_can_create_and_list_reports(self, authenticated_client, neighborhood):
        """Test complete report creation and listing flow"""
        # Create report
        create_response = authenticated_client.post(
            "/api/v1/reports/",
            {
                "title": "Pothole report",
                "problem_type": "ROADS",
                "description": "Pothole on main street",
                "address": "12 rue de la Paix",
                "neighborhood": neighborhood.id
            },
            format="json"
        )
        assert create_response.status_code == status.HTTP_201_CREATED
        report_id = create_response.data["id"]
        
        # List reports
        list_response = authenticated_client.get("/api/v1/reports/")
        assert list_response.status_code == status.HTTP_200_OK
        
        # Retrieve specific report
        detail_response = authenticated_client.get(f"/api/v1/reports/{report_id}/")
        assert detail_response.status_code == status.HTTP_200_OK
        assert detail_response.data["description"] == "Pothole on main street"
        assert detail_response.data["address"] == "12 rue de la Paix"
    
    def test_staff_can_update_report_status(self, elected_client, citizen_user, neighborhood):
        """Test staff can change report status"""
        # Create report as citizen
        report = Report.objects.create(
            user=citizen_user,
            title="Test report",
            problem_type=ProblemTypeEnum.ROADS,
            description="Test report",
            address="18 boulevard Saint-Germain",
            neighborhood=neighborhood
        )
        
        # Staff updates status
        response = elected_client.post(
            f"/api/v1/reports/{report.id}/update_status/",
            {"status": "IN_PROGRESS"},
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "IN_PROGRESS"


class TestSurveysFlow:
    """Test surveys and voting flow"""
    
    def test_complete_survey_voting_flow(self, api_client, elected_user, citizen_user):
        """Test complete survey creation and voting flow"""
        # Authenticate as elected to create survey
        api_client.force_authenticate(user=elected_user)
        
        # Create survey
        create_response = api_client.post(
            "/api/v1/surveys/",
            {
                "title": "Park Development",
                "description": "What should we build in the park?",
                "address": "25 rue des Lilas, Novaville",
                "start_date": timezone.now().isoformat(),
                "end_date": (timezone.now() + timedelta(days=7)).isoformat(),
                "options": ["Playground", "Sports field"]
            },
            format="json"
        )
        assert create_response.status_code == status.HTTP_201_CREATED
        survey_id = create_response.data["id"]
        
        # Get the survey to retrieve options
        survey_response = api_client.get(f"/api/v1/surveys/{survey_id}/")
        assert survey_response.status_code == status.HTTP_200_OK
        option_id = survey_response.data["options"][0]["id"]
        
        # Switch to citizen to vote
        api_client.force_authenticate(user=citizen_user)
        
        # Cast vote
        vote_response = api_client.post(
            "/api/v1/votes/",
            {"survey": survey_id, "option": option_id},
            format="json"
        )
        assert vote_response.status_code == status.HTTP_201_CREATED
        
        # Get survey results
        results_response = api_client.get(f"/api/v1/surveys/{survey_id}/results/")
        assert results_response.status_code == status.HTTP_200_OK
        assert results_response.data["total_votes"] == 1


class TestEventsFlow:
    """Test events operations"""
    
    def test_staff_can_create_events_citizens_can_view(self, api_client, elected_user, citizen_user, theme):
        """Test event creation by staff and viewing by citizens"""
        # Authenticate as elected  to create event
        api_client.force_authenticate(user=elected_user)
        
        # Create event
        create_response = api_client.post(
            "/api/v1/events/",
            {
                "title": "City Festival",
                "description": "Annual city festival",
                "start_date": (timezone.now() + timedelta(days=5)).isoformat(),
                "end_date": (timezone.now() + timedelta(days=5, hours=6)).isoformat(),
                "theme": theme.id
            },
            format="json"
        )
        assert create_response.status_code == status.HTTP_201_CREATED
        event_id = create_response.data["id"]
        
        # Switch to citizen to view
        api_client.force_authenticate(user=citizen_user)
        
        # View event
        view_response = api_client.get(f"/api/v1/events/{event_id}/")
        assert view_response.status_code == status.HTTP_200_OK
        assert view_response.data["title"] == "City Festival"
        
        # List upcoming events
        upcoming_response = api_client.get("/api/v1/events/upcoming/")
        assert upcoming_response.status_code == status.HTTP_200_OK


class TestPermissionsBasics:
    """Test basic permission rules"""
    
    def test_unauthenticated_can_access_public_neighborhoods_api(self, api_client):
        """Test unauthenticated requests can access the public neighborhoods list"""
        response = api_client.get("/api/v1/neighborhoods/")
        assert response.status_code == status.HTTP_200_OK
    
    def test_citizen_cannot_create_events(self, authenticated_client, theme):
        """Test citizens cannot create events"""
        response = authenticated_client.post(
            "/api/v1/events/",
            {
                "title": "Test",
                "start_date": timezone.now().isoformat(),
                "end_date": (timezone.now() + timedelta(hours=2)).isoformat(),
                "theme": theme.id
            },
            format="json"
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_citizen_cannot_create_neighborhoods(self, authenticated_client):
        """Test citizens cannot create neighborhoods"""
        response = authenticated_client.post(
            "/api/v1/neighborhoods/",
            {"name": "Test", "postal_code": "99999"},
            format="json"
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_admin_has_full_access(self, admin_client, neighborhood):
        """Test admin can perform admin operations"""
        # Can create neighborhood
        response = admin_client.post(
            "/api/v1/neighborhoods/",
            {"name": "Admin Neighborhood", "postal_code": "88888"},
            format="json"
        )
        assert response.status_code == status.HTTP_201_CREATED
        
        # Can create theme
        response = admin_client.post(
            "/api/v1/event-themes/",
            {"title": "NEW_THEME"},
            format="json"
        )
        assert response.status_code == status.HTTP_201_CREATED
