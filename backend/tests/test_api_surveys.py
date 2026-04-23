"""Tests for Surveys API endpoints"""
import pytest
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.test import APIRequestFactory, force_authenticate
from datetime import timedelta
from django.utils import timezone
from api.v1.viewsets.vote_viewset import VoteViewSet
from api.v1.viewsets.survey_viewset import SurveyOptionViewSet
from api.v1.permissions import IsStaffOrReadOnly

pytestmark = pytest.mark.django_db


class TestSurveysAPI:
    """Tests for surveys endpoints"""
    
    def test_list_surveys(self, authenticated_client, survey):
        """Test listing surveys"""
        response = authenticated_client.get("/api/v1/surveys/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
    
    def test_create_survey_by_elected(self, elected_client):
        """Test elected official can create survey with options"""
        data = {
            "title": "New Survey",
            "description": "Survey description",
            "address": "12 Rue de la Paix, Novaville",
            "start_date": timezone.now().isoformat(),
            "end_date": (timezone.now() + timedelta(days=7)).isoformat(),
            "options": ["Option A", "Option B", "Option C"]
        }
        response = elected_client.post("/api/v1/surveys/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["title"] == "New Survey"
        assert response.data["address"] == "12 Rue de la Paix, Novaville"

        # Get the survey to check options
        survey_id = response.data["id"]
        survey_response = elected_client.get(f"/api/v1/surveys/{survey_id}/")
        assert len(survey_response.data["options"]) == 3
    
    def test_create_survey_without_options(self, elected_client):
        """Test creating a survey with no options returns validation error"""
        data = {
            "title": "Survey Without Options",
            "description": "Should fail",
            "address": "14 rue des Ecoles, Novaville",
            "start_date": timezone.now().isoformat(),
            "end_date": (timezone.now() + timedelta(days=7)).isoformat(),
            "options": []
        }
        response = elected_client.post("/api/v1/surveys/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "options" in response.data

    def test_create_survey_by_citizen_forbidden(self, authenticated_client):
        """Test citizen cannot create survey"""
        data = {
            "title": "Unauthorized Survey",
            "description": "Should fail",
            "address": "16 rue des Roses, Novaville",
            "start_date": timezone.now().isoformat(),
            "end_date": (timezone.now() + timedelta(days=7)).isoformat()
        }
        response = authenticated_client.post("/api/v1/surveys/", data, format="json")
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_retrieve_survey(self, authenticated_client, survey_with_options):
        """Test retrieving a survey with options"""
        response = authenticated_client.get(f"/api/v1/surveys/{survey_with_options.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == survey_with_options.id
        assert "options" in response.data
        assert len(response.data["options"]) == 2
    
    def test_update_survey(self, elected_client, survey):
        """Test updating a survey"""
        data = {"title": "Updated Title"}
        response = elected_client.patch(
            f"/api/v1/surveys/{survey.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["title"] == "Updated Title"
    
    def test_delete_survey(self, elected_client, survey):
        """Test deleting a survey"""
        response = elected_client.delete(f"/api/v1/surveys/{survey.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
    
    def test_active_surveys_endpoint(self, authenticated_client, elected_user):
        """Test /active/ endpoint returns only active surveys"""
        # Create active survey
        active_survey = elected_user.created_surveys.create(
            title="Active Survey",
            description="Active",
            address="2 place du Marche, Novaville",
            start_date=timezone.now() - timedelta(days=1),
            end_date=timezone.now() + timedelta(days=5)
        )
        
        # Create expired survey
        expired_survey = elected_user.created_surveys.create(
            title="Expired Survey",
            description="Expired",
            address="3 place du Marche, Novaville",
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=1)
        )
        
        response = authenticated_client.get("/api/v1/surveys/active/")
        assert response.status_code == status.HTTP_200_OK
        survey_ids = [s["id"] for s in response.data]
        assert active_survey.id in survey_ids
        assert expired_survey.id not in survey_ids
    
    def test_survey_results_endpoint(self, authenticated_client, survey_with_options, citizen_user):
        """Test /results/ endpoint shows vote counts"""
        # Create some votes
        from core.db.models import Vote
        option1 = survey_with_options.options.first()
        Vote.objects.create(
            user=citizen_user,
            survey=survey_with_options,
            option=option1
        )
        
        response = authenticated_client.get(f"/api/v1/surveys/{survey_with_options.id}/results/")
        assert response.status_code == status.HTTP_200_OK
        assert "total_votes" in response.data
        assert response.data["total_votes"] == 1
        assert "options" in response.data

    def test_filter_surveys_with_multiple_attributes(self, authenticated_client, elected_user):
        """Test combining multiple survey filters in one request"""
        matching_survey = elected_user.created_surveys.create(
            title="Multi Attr Survey",
            description="Should match",
            address="8 rue de la Liberte, Novaville",
            start_date=timezone.now() - timedelta(days=1),
            end_date=timezone.now() + timedelta(days=5),
        )
        elected_user.created_surveys.create(
            title="Multi Attr Survey",
            description="Wrong date range",
            address="9 rue de la Liberte, Novaville",
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=2),
        )

        response = authenticated_client.get(
            f"/api/v1/surveys/?title=Multi Attr Survey&created_by={elected_user.id}"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        result_ids = [s["id"] for s in results]

        assert matching_survey.id in result_ids
        for survey_data in results:
            assert survey_data["title"] == "Multi Attr Survey"
            assert survey_data["created_by"]["id"] == elected_user.id


class TestVotesAPI:
    """Tests for votes endpoints"""
    
    def test_create_vote(self, authenticated_client, survey_with_options):
        """Test creating a vote"""
        option = survey_with_options.options.first()
        data = {
            "survey": survey_with_options.id,
            "option": option.id
        }
        response = authenticated_client.post("/api/v1/votes/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["survey"] == survey_with_options.id
        assert response.data["option"] == option.id
    
    def test_second_vote_updates_existing_vote(self, authenticated_client, survey_with_options):
        """Test user can change vote on same survey by voting again"""
        option1 = survey_with_options.options.first()
        option2 = survey_with_options.options.last()
        
        # First vote succeeds
        response1 = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": survey_with_options.id, "option": option1.id},
            format="json"
        )
        assert response1.status_code == status.HTTP_201_CREATED
        
        # Second vote updates the existing vote
        response2 = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": survey_with_options.id, "option": option2.id},
            format="json"
        )
        assert response2.status_code == status.HTTP_200_OK
        assert response2.data["option"] == option2.id

        from core.db.models import Vote
        votes = Vote.objects.filter(survey=survey_with_options, user_id=response2.data["user"])
        assert votes.count() == 1

    def test_vote_option_mismatch(self, authenticated_client, survey_with_options, elected_user):
        """Test voting with option from different survey"""
        # Create another survey
        from core.db.models import Survey, SurveyOption
        other_survey = Survey.objects.create(
            title="Other Survey",
            description="Different",
            address="4 boulevard du Parc, Novaville",
            start_date="2026-01-01T00:00:00Z",
            end_date="2026-12-31T23:59:59Z",
            created_by=elected_user
        )
        other_option = SurveyOption.objects.create(
            survey=other_survey,
            text="Other Option"
        )
        
        # Try to vote on survey_with_options using option from other_survey
        response = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": survey_with_options.id, "option": other_option.id},
            format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "does not belong to this survey" in str(response.data)
    
    def test_list_user_votes(self, authenticated_client, survey_with_options):
        """Test listing user's own votes"""
        option = survey_with_options.options.first()
        authenticated_client.post(
            "/api/v1/votes/",
            {"survey": survey_with_options.id, "option": option.id},
            format="json"
        )
        
        response = authenticated_client.get("/api/v1/votes/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1

    def test_filter_votes_with_multiple_attributes(self, authenticated_client, survey_with_options, elected_user):
        """Test combining multiple vote filters in one request"""
        from core.db.models import Survey, SurveyOption

        option1 = survey_with_options.options.first()
        option2 = survey_with_options.options.last()

        other_survey = Survey.objects.create(
            title="Other Filter Survey",
            description="Different survey",
            address="6 avenue de la Gare, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            created_by=elected_user,
        )
        other_option = SurveyOption.objects.create(survey=other_survey, text="Other Option")

        response1 = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": survey_with_options.id, "option": option1.id},
            format="json"
        )
        assert response1.status_code == status.HTTP_201_CREATED

        response2 = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": other_survey.id, "option": other_option.id},
            format="json"
        )
        assert response2.status_code == status.HTTP_201_CREATED

        response = authenticated_client.get(
            f"/api/v1/votes/?survey={survey_with_options.id}&option={option1.id}"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)

        assert len(results) == 1
        assert results[0]["survey"] == survey_with_options.id
        assert results[0]["option"] == option1.id

    def test_vote_create_requires_valid_payload(self, citizen_user):
        """Test create vote returns validation error for invalid payload."""
        factory = APIRequestFactory()
        request = factory.post(
            "/api/v1/votes/",
            {"survey": 99999, "option": 99999},
            format="json"
        )
        force_authenticate(request, user=citizen_user)

        view = VoteViewSet.as_view({"post": "create"})
        response = view(request)
        assert response.status_code == status.HTTP_400_BAD_REQUEST


class TestSurveyOptionsAPI:
    """Tests for survey options endpoints"""

    def test_list_survey_options(self, authenticated_client, survey_with_options):
        """Test listing survey options"""
        response = authenticated_client.get("/api/v1/survey-options/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert len(results) >= 2

    def test_survey_option_permissions_list(self):
        """Test list uses authenticated permission"""
        view = SurveyOptionViewSet()
        view.action = "list"
        permissions = view.get_permissions()
        assert any(isinstance(p, IsAuthenticated) for p in permissions)

    def test_survey_option_permissions_write(self):
        """Test write uses staff-only permission"""
        view = SurveyOptionViewSet()
        view.action = "create"
        permissions = view.get_permissions()
        assert any(isinstance(p, IsStaffOrReadOnly) for p in permissions)

    def test_filter_survey_options_with_multiple_attributes(self, authenticated_client, survey_with_options):
        """Test combining multiple survey option filters in one request"""
        option = survey_with_options.options.first()

        response = authenticated_client.get(
            f"/api/v1/survey-options/?id={option.id}&text={option.text}"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)

        assert len(results) == 1
        assert results[0]["id"] == option.id
        assert results[0]["text"] == option.text
