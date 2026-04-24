"""Tests for Surveys API endpoints"""
import pytest
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.test import APIRequestFactory, force_authenticate
from datetime import timedelta
from django.utils import timezone
from api.v1.viewsets.vote_viewset import VoteViewSet
from api.v1.viewsets.survey_viewset import SurveyOptionViewSet
from api.v1.permissions import IsSurveyManagerOrReadOnly
from core.db.models import RoleEnum

pytestmark = pytest.mark.django_db


class TestSurveysAPI:
    """Tests for surveys endpoints"""
    
    def test_list_surveys(self, authenticated_client, survey):
        """Test listing surveys"""
        response = authenticated_client.get("/api/v1/surveys/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1

    def test_citizen_lists_all_citizens_and_citizen_surveys(
        self, authenticated_client, elected_user
    ):
        """Test citizens see all-citizens surveys and citizen-targeted surveys."""
        all_citizens_survey = elected_user.created_surveys.create(
            title="All Citizens Survey",
            description="For every profile",
            address="9 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
        )
        citizen_survey = elected_user.created_surveys.create(
            title="Citizen Survey",
            description="For citizens",
            address="10 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.CITIZEN,
        )
        elected_survey = elected_user.created_surveys.create(
            title="Elected Survey",
            description="For elected users",
            address="11 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.ELECTED,
        )

        response = authenticated_client.get("/api/v1/surveys/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        result_ids = [survey["id"] for survey in results]
        assert all_citizens_survey.id in result_ids
        assert citizen_survey.id in result_ids
        assert elected_survey.id not in result_ids

    def test_elected_lists_all_surveys(self, elected_client, elected_user):
        """Test elected users can see every survey target."""
        all_citizens_survey = elected_user.created_surveys.create(
            title="All Citizens Survey",
            description="For every profile",
            address="10 rue de Paris, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
        )
        agent_survey = elected_user.created_surveys.create(
            title="Agent Survey",
            description="For agents",
            address="11 rue de Paris, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.AGENT,
        )
        citizen_survey = elected_user.created_surveys.create(
            title="Citizen Survey",
            description="For citizens",
            address="12 rue de Paris, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.CITIZEN,
        )

        response = elected_client.get("/api/v1/surveys/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        result_ids = [survey["id"] for survey in results]
        assert all_citizens_survey.id in result_ids
        assert agent_survey.id in result_ids
        assert citizen_survey.id in result_ids

    def test_agent_lists_all_citizens_and_agent_surveys(
        self, api_client, agent_user, elected_user
    ):
        """Test agents see all-citizens surveys and agent-targeted surveys."""
        api_client.force_authenticate(user=agent_user)
        all_citizens_survey = elected_user.created_surveys.create(
            title="All Citizens Survey",
            description="For every profile",
            address="13 rue de Paris, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
        )
        agent_survey = elected_user.created_surveys.create(
            title="Agent Survey",
            description="For agents",
            address="14 rue de Paris, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.AGENT,
        )
        elected_survey = elected_user.created_surveys.create(
            title="Elected Survey",
            description="For elected users",
            address="15 rue de Paris, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.ELECTED,
        )

        response = api_client.get("/api/v1/surveys/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        result_ids = [survey["id"] for survey in results]
        assert all_citizens_survey.id in result_ids
        assert agent_survey.id in result_ids
        assert elected_survey.id not in result_ids

    def test_admin_lists_all_surveys(self, admin_client, elected_user):
        """Test global admins can see every survey target."""
        citizen_survey = elected_user.created_surveys.create(
            title="Citizen Survey",
            description="For citizens",
            address="12 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.CITIZEN,
        )
        elected_survey = elected_user.created_surveys.create(
            title="Elected Survey",
            description="For elected users",
            address="13 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.ELECTED,
        )

        response = admin_client.get("/api/v1/surveys/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        result_ids = [survey["id"] for survey in results]
        assert citizen_survey.id in result_ids
        assert elected_survey.id in result_ids

    def test_citizen_cannot_retrieve_survey_for_another_role(
        self, authenticated_client, elected_user
    ):
        """Test direct detail access also respects survey target."""
        elected_survey = elected_user.created_surveys.create(
            title="Elected Survey",
            description="For elected users",
            address="14 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.ELECTED,
        )

        response = authenticated_client.get(f"/api/v1/surveys/{elected_survey.id}/")

        assert response.status_code == status.HTTP_404_NOT_FOUND
    
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
        assert response.data["citizen_target"] is None

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

    def test_create_survey_by_agent_forbidden(self, api_client, agent_user):
        """Test agents cannot create surveys."""
        api_client.force_authenticate(user=agent_user)
        data = {
            "title": "Agent Survey Creation",
            "description": "Should fail",
            "address": "17 rue des Roses, Novaville",
            "start_date": timezone.now().isoformat(),
            "end_date": (timezone.now() + timedelta(days=7)).isoformat(),
            "options": ["Option A", "Option B"],
        }

        response = api_client.post("/api/v1/surveys/", data, format="json")

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

    def test_update_survey_by_agent_forbidden(self, api_client, agent_user, survey):
        """Test agents cannot update surveys."""
        api_client.force_authenticate(user=agent_user)

        response = api_client.patch(
            f"/api/v1/surveys/{survey.id}/",
            {"title": "Agent Updated Title"},
            format="json"
        )

        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_delete_survey(self, elected_client, survey):
        """Test deleting a survey"""
        response = elected_client.delete(f"/api/v1/surveys/{survey.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT

    def test_delete_survey_by_agent_forbidden(self, api_client, agent_user, survey):
        """Test agents cannot delete surveys."""
        api_client.force_authenticate(user=agent_user)

        response = api_client.delete(f"/api/v1/surveys/{survey.id}/")

        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_active_surveys_endpoint(self, authenticated_client, elected_user):
        """Test /active/ endpoint returns only active surveys"""
        # Create active survey
        active_survey = elected_user.created_surveys.create(
            title="Active Survey",
            description="Active",
            address="2 place du Marche, Novaville",
            start_date=timezone.now() - timedelta(days=1),
            end_date=timezone.now() + timedelta(days=5),
            citizen_target=RoleEnum.CITIZEN,
        )
        
        # Create expired survey
        expired_survey = elected_user.created_surveys.create(
            title="Expired Survey",
            description="Expired",
            address="3 place du Marche, Novaville",
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=1),
            citizen_target=RoleEnum.CITIZEN,
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
            citizen_target=RoleEnum.CITIZEN,
        )
        elected_user.created_surveys.create(
            title="Multi Attr Survey",
            description="Wrong date range",
            address="9 rue de la Liberte, Novaville",
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=2),
            citizen_target=RoleEnum.CITIZEN,
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

    def test_citizen_cannot_vote_on_survey_for_another_role(
        self, authenticated_client, elected_user
    ):
        """Test vote creation respects survey target."""
        from core.db.models import SurveyOption

        elected_survey = elected_user.created_surveys.create(
            title="Elected Vote Survey",
            description="For elected users",
            address="15 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.ELECTED,
        )
        option = SurveyOption.objects.create(survey=elected_survey, text="Yes")

        response = authenticated_client.post(
            "/api/v1/votes/",
            {"survey": elected_survey.id, "option": option.id},
            format="json"
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_elected_can_vote_on_all_citizens_and_elected_surveys(
        self, elected_client, elected_user
    ):
        """Test elected users can vote on all-citizens and elected-targeted surveys."""
        from core.db.models import SurveyOption

        all_citizens_survey = elected_user.created_surveys.create(
            title="All Citizens Vote Survey",
            description="For every profile",
            address="16 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
        )
        elected_survey = elected_user.created_surveys.create(
            title="Elected Vote Survey",
            description="For elected users",
            address="17 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.ELECTED,
        )
        all_option = SurveyOption.objects.create(
            survey=all_citizens_survey,
            text="Yes"
        )
        elected_option = SurveyOption.objects.create(survey=elected_survey, text="Yes")

        all_response = elected_client.post(
            "/api/v1/votes/",
            {"survey": all_citizens_survey.id, "option": all_option.id},
            format="json"
        )
        elected_response = elected_client.post(
            "/api/v1/votes/",
            {"survey": elected_survey.id, "option": elected_option.id},
            format="json"
        )

        assert all_response.status_code == status.HTTP_201_CREATED
        assert elected_response.status_code == status.HTTP_201_CREATED

    def test_elected_cannot_vote_on_agent_survey(self, elected_client, elected_user):
        """Test elected users can see but not vote on agent-targeted surveys."""
        from core.db.models import SurveyOption

        agent_survey = elected_user.created_surveys.create(
            title="Agent Vote Survey",
            description="For agents",
            address="18 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.AGENT,
        )
        option = SurveyOption.objects.create(survey=agent_survey, text="Yes")

        response = elected_client.post(
            "/api/v1/votes/",
            {"survey": agent_survey.id, "option": option.id},
            format="json"
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_agent_can_vote_on_all_citizens_and_agent_surveys(
        self, api_client, agent_user, elected_user
    ):
        """Test agents can vote on all-citizens and agent-targeted surveys."""
        from core.db.models import SurveyOption

        api_client.force_authenticate(user=agent_user)
        all_citizens_survey = elected_user.created_surveys.create(
            title="All Citizens Agent Vote Survey",
            description="For every profile",
            address="19 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
        )
        agent_survey = elected_user.created_surveys.create(
            title="Agent Vote Survey",
            description="For agents",
            address="20 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.AGENT,
        )
        all_option = SurveyOption.objects.create(
            survey=all_citizens_survey,
            text="Yes"
        )
        agent_option = SurveyOption.objects.create(survey=agent_survey, text="Yes")

        all_response = api_client.post(
            "/api/v1/votes/",
            {"survey": all_citizens_survey.id, "option": all_option.id},
            format="json"
        )
        agent_response = api_client.post(
            "/api/v1/votes/",
            {"survey": agent_survey.id, "option": agent_option.id},
            format="json"
        )

        assert all_response.status_code == status.HTTP_201_CREATED
        assert agent_response.status_code == status.HTTP_201_CREATED

    def test_admin_can_vote_on_any_survey(self, admin_client, elected_user):
        """Test global admins can vote on every survey target."""
        from core.db.models import SurveyOption

        agent_survey = elected_user.created_surveys.create(
            title="Agent Admin Vote Survey",
            description="For agents",
            address="21 rue des Fleurs, Novaville",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7),
            citizen_target=RoleEnum.AGENT,
        )
        option = SurveyOption.objects.create(survey=agent_survey, text="Yes")

        response = admin_client.post(
            "/api/v1/votes/",
            {"survey": agent_survey.id, "option": option.id},
            format="json"
        )

        assert response.status_code == status.HTTP_201_CREATED
    
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
            created_by=elected_user,
            citizen_target=RoleEnum.CITIZEN,
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
            citizen_target=RoleEnum.CITIZEN,
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
        assert any(isinstance(p, IsSurveyManagerOrReadOnly) for p in permissions)

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
