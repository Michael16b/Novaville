"""Tests for Surveys API endpoints"""
import pytest
from rest_framework import status
from datetime import timedelta
from django.utils import timezone

pytestmark = pytest.mark.django_db


class TestSurveysAPI:
    """Tests for surveys endpoints"""
    
    def test_list_surveys(self, authenticated_client, survey):
        """Test listing surveys"""
        response = authenticated_client.get("/api/v1/surveys/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) >= 1
    
    def test_create_survey_by_elected(self, elected_client):
        """Test elected official can create survey with options"""
        data = {
            "title": "New Survey",
            "description": "Survey description",
            "start_date": timezone.now().isoformat(),
            "end_date": (timezone.now() + timedelta(days=7)).isoformat(),
            "options": [
                {"text": "Option A"},
                {"text": "Option B"},
                {"text": "Option C"}
            ]
        }
        response = elected_client.post("/api/v1/surveys/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["title"] == "New Survey"
        assert len(response.data["options"]) == 3
    
    def test_create_survey_by_citizen_forbidden(self, authenticated_client):
        """Test citizen cannot create survey"""
        data = {
            "title": "Unauthorized Survey",
            "description": "Should fail",
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
            start_date=timezone.now() - timedelta(days=1),
            end_date=timezone.now() + timedelta(days=5)
        )
        
        # Create expired survey
        expired_survey = elected_user.created_surveys.create(
            title="Expired Survey",
            description="Expired",
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
    
    def test_cannot_vote_twice(self, authenticated_client, survey_with_options):
        """Test user cannot vote twice on same survey"""
        option1 = survey_with_options.options.first()
        option2 = survey_with_options.options.last()
        
        # First vote succeeds
        response1 = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": survey_with_options.id, "option": option1.id},
            format="json"
        )
        assert response1.status_code == status.HTTP_201_CREATED
        
        # Second vote fails
        response2 = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": survey_with_options.id, "option": option2.id},
            format="json"
        )
        assert response2.status_code == status.HTTP_400_BAD_REQUEST
    
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
        assert len(response.data) >= 1
