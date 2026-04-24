"""Tests for Dashboard API endpoints."""
import pytest
from datetime import timedelta
from django.utils import timezone
from rest_framework import status

from core.db.models import RoleEnum

pytestmark = pytest.mark.django_db


def _create_active_survey(elected_user, title, citizen_target=None):
    return elected_user.created_surveys.create(
        title=title,
        description=f"{title} description",
        address=f"{title} address, Novaville",
        start_date=timezone.now() - timedelta(days=1),
        end_date=timezone.now() + timedelta(days=7),
        citizen_target=citizen_target,
    )


class TestDashboardAPI:
    """Tests for dashboard statistics."""

    def test_active_surveys_count_matches_citizen_visibility(
        self, authenticated_client, elected_user
    ):
        """Test citizen dashboard only counts visible active surveys."""
        all_citizens = _create_active_survey(elected_user, "All Citizens")
        citizen = _create_active_survey(
            elected_user,
            "Citizen",
            RoleEnum.CITIZEN,
        )
        elected = _create_active_survey(
            elected_user,
            "Elected",
            RoleEnum.ELECTED,
        )

        response = authenticated_client.get("/api/v1/dashboard/stats/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["active_surveys"] == 2
        assert all_citizens.id != elected.id
        assert citizen.id != elected.id

    def test_active_surveys_count_matches_agent_visibility(
        self, api_client, agent_user, elected_user
    ):
        """Test agent dashboard only counts all-citizens and agent surveys."""
        api_client.force_authenticate(user=agent_user)
        _create_active_survey(elected_user, "All Citizens")
        _create_active_survey(elected_user, "Agent", RoleEnum.AGENT)
        _create_active_survey(elected_user, "Elected", RoleEnum.ELECTED)
        _create_active_survey(elected_user, "Citizen", RoleEnum.CITIZEN)

        response = api_client.get("/api/v1/dashboard/stats/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["active_surveys"] == 2

    def test_active_surveys_count_matches_elected_visibility(
        self, elected_client, elected_user
    ):
        """Test elected dashboard counts every active survey."""
        _create_active_survey(elected_user, "All Citizens")
        _create_active_survey(elected_user, "Agent", RoleEnum.AGENT)
        _create_active_survey(elected_user, "Elected", RoleEnum.ELECTED)
        _create_active_survey(elected_user, "Citizen", RoleEnum.CITIZEN)

        response = elected_client.get("/api/v1/dashboard/stats/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["active_surveys"] == 4

    def test_active_surveys_count_matches_admin_visibility(
        self, admin_client, elected_user
    ):
        """Test admin dashboard counts every active survey."""
        _create_active_survey(elected_user, "All Citizens")
        _create_active_survey(elected_user, "Agent", RoleEnum.AGENT)
        _create_active_survey(elected_user, "Elected", RoleEnum.ELECTED)
        _create_active_survey(elected_user, "Citizen", RoleEnum.CITIZEN)

        response = admin_client.get("/api/v1/dashboard/stats/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["active_surveys"] == 4

    def test_poll_participation_rate_uses_visible_active_surveys(
        self, authenticated_client, elected_user, citizen_user
    ):
        """Test dashboard participation denominator uses profile-visible surveys."""
        from core.db.models import SurveyOption, Vote

        visible_voted = _create_active_survey(elected_user, "Visible Voted")
        visible_not_voted = _create_active_survey(
            elected_user,
            "Visible Not Voted",
            RoleEnum.CITIZEN,
        )
        hidden = _create_active_survey(elected_user, "Hidden", RoleEnum.ELECTED)
        option = SurveyOption.objects.create(survey=visible_voted, text="Yes")
        SurveyOption.objects.create(survey=visible_not_voted, text="Yes")
        SurveyOption.objects.create(survey=hidden, text="Yes")
        Vote.objects.create(
            user=citizen_user,
            survey=visible_voted,
            option=option,
        )

        response = authenticated_client.get("/api/v1/dashboard/stats/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["active_surveys"] == 2
        assert response.data["poll_participation_rate"] == 50
