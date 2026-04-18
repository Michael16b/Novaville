"""Tests for dashboard API endpoint."""

from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework import status

from core.db.models import Event, Report, Survey

pytestmark = pytest.mark.django_db


class TestDashboardStatsRecentActivities:
    """Tests for recent activities aggregation in dashboard stats."""

    def test_recent_activities_returns_latest_three_mixed_types(
        self,
        api_client,
        citizen_user,
        elected_user,
        neighborhood,
        theme,
    ):
        """Dashboard returns the 3 latest creations across report/survey/event."""
        now = timezone.now()

        old_report = Report.objects.create(
            user=citizen_user,
            title="Ancien signalement",
            description="desc",
            problem_type="ROADS",
            address="Rue A",
            neighborhood=neighborhood,
        )
        newest_report = Report.objects.create(
            user=citizen_user,
            title="Signalement recent",
            description="desc",
            problem_type="LIGHTING",
            address="Rue B",
            neighborhood=neighborhood,
        )

        old_survey = Survey.objects.create(
            title="Ancien sondage",
            description="desc",
            created_by=elected_user,
            start_date=now,
            end_date=now + timedelta(days=7),
        )
        newest_survey = Survey.objects.create(
            title="Sondage recent",
            description="desc",
            created_by=elected_user,
            start_date=now,
            end_date=now + timedelta(days=7),
        )

        old_event = Event.objects.create(
            title="Ancien evenement",
            description="desc",
            created_by=elected_user,
            theme=theme,
            start_date=now + timedelta(days=1),
            end_date=now + timedelta(days=1, hours=2),
        )
        newest_event = Event.objects.create(
            title="Evenement recent",
            description="desc",
            created_by=elected_user,
            theme=theme,
            start_date=now + timedelta(days=2),
            end_date=now + timedelta(days=2, hours=2),
        )

        Report.objects.filter(pk=old_report.pk).update(created_at=now - timedelta(hours=10))
        Report.objects.filter(pk=newest_report.pk).update(created_at=now - timedelta(minutes=50))
        Survey.objects.filter(pk=old_survey.pk).update(created_at=now - timedelta(hours=8))
        Survey.objects.filter(pk=newest_survey.pk).update(created_at=now - timedelta(minutes=10))
        Event.objects.filter(pk=old_event.pk).update(created_at=now - timedelta(hours=6))
        Event.objects.filter(pk=newest_event.pk).update(created_at=now - timedelta(minutes=30))

        response = api_client.get('/api/v1/dashboard/stats/')

        assert response.status_code == status.HTTP_200_OK
        assert 'recent_activities' in response.data

        recent_activities = response.data['recent_activities']
        assert len(recent_activities) == 3

        # Expected order: newest survey (10m), newest event (30m), newest report (50m)
        assert recent_activities[0]['type'] == 'survey'
        assert recent_activities[0]['title'] == 'Sondage recent'
        assert recent_activities[1]['type'] == 'event'
        assert recent_activities[1]['title'] == 'Evenement recent'
        assert recent_activities[2]['type'] == 'report'
        assert recent_activities[2]['title'] == 'Signalement recent'

        for activity in recent_activities:
            assert 'elapsed_seconds' in activity
            assert 'elapsed_label' in activity
            assert isinstance(activity['elapsed_seconds'], int)
            assert isinstance(activity['elapsed_label'], str)

