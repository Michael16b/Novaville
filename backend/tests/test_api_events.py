"""Tests for Events API endpoints"""
import pytest
from rest_framework import status
from datetime import timedelta
from django.utils import timezone

pytestmark = pytest.mark.django_db


class TestEventsAPI:
    """Tests for events endpoints"""
    
    def test_list_events(self, authenticated_client, event):
        """Test listing events"""
        response = authenticated_client.get("/api/v1/events/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
    
    def test_create_event(self, elected_client, theme):
        """Test creating an event"""
        data = {
            "title": "New Event",
            "description": "Event description",
            "start_date": (timezone.now() + timedelta(days=1)).isoformat(),
            "end_date": (timezone.now() + timedelta(days=1, hours=3)).isoformat(),
            "theme": theme.id
        }
        response = elected_client.post("/api/v1/events/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["title"] == "New Event"
    
    def test_create_event_by_citizen_forbidden(self, authenticated_client, theme):
        """Test citizen cannot create events"""
        data = {
            "title": "Unauthorized Event",
            "description": "Should fail",
            "start_date": timezone.now().isoformat(),
            "end_date": (timezone.now() + timedelta(hours=2)).isoformat(),
            "theme": theme.id
        }
        response = authenticated_client.post("/api/v1/events/", data, format="json")
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_retrieve_event(self, authenticated_client, event):
        """Test retrieving a specific event"""
        response = authenticated_client.get(f"/api/v1/events/{event.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == event.id
    
    def test_update_event(self, elected_client, event):
        """Test updating an event"""
        data = {"title": "Updated Event Title"}
        response = elected_client.patch(
            f"/api/v1/events/{event.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["title"] == "Updated Event Title"
    
    def test_delete_event(self, elected_client, event):
        """Test deleting an event"""
        response = elected_client.delete(f"/api/v1/events/{event.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
    
    def test_upcoming_events_endpoint(self, authenticated_client, elected_user, theme):
        """Test /upcoming/ endpoint returns only future events"""
        # Create past event
        past_event = elected_user.created_events.create(
            title="Past Event",
            description="Past",
            start_date=timezone.now() - timedelta(days=5),
            end_date=timezone.now() - timedelta(days=5, hours=-2),
            theme=theme
        )
        
        # Create future event
        future_event = elected_user.created_events.create(
            title="Future Event",
            description="Future",
            start_date=timezone.now() + timedelta(days=5),
            end_date=timezone.now() + timedelta(days=5, hours=2),
            theme=theme
        )
        
        response = authenticated_client.get("/api/v1/events/upcoming/")
        assert response.status_code == status.HTTP_200_OK
        event_ids = [e["id"] for e in response.data]
        assert future_event.id in event_ids
        assert past_event.id not in event_ids
    
    def test_filter_events_by_theme(self, authenticated_client, elected_user, theme):
        """Test filtering events by theme"""
        from core.db.models import ThemeEvent, ThemeEnum
        
        other_theme = ThemeEvent.objects.create(title=ThemeEnum.CULTURE)
        
        event1 = elected_user.created_events.create(
            title="Sport Event",
            start_date=timezone.now() + timedelta(days=1),
            end_date=timezone.now() + timedelta(days=1, hours=2),
            theme=theme
        )
        event2 = elected_user.created_events.create(
            title="Culture Event",
            start_date=timezone.now() + timedelta(days=2),
            end_date=timezone.now() + timedelta(days=2, hours=2),
            theme=other_theme
        )
        
        response = authenticated_client.get(f"/api/v1/events/?theme={theme.id}")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        event_ids = [e["id"] for e in results]
        assert event1.id in event_ids
        assert event2.id not in event_ids


class TestEventThemesAPI:
    """Tests for event themes endpoints"""
    
    def test_list_themes(self, authenticated_client, theme):
        """Test listing event themes"""
        response = authenticated_client.get("/api/v1/event-themes/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
    
    def test_create_theme(self, admin_client):
        """Test admin can create theme"""
        response = admin_client.post(
            "/api/v1/event-themes/",
            {"title": "NEW_THEME"},
            format="json"
        )
        assert response.status_code == status.HTTP_201_CREATED
    
    def test_citizen_cannot_create_theme(self, authenticated_client):
        """Test citizen cannot create theme"""
        response = authenticated_client.post(
            "/api/v1/event-themes/",
            {"title": "FORBIDDEN_THEME"},
            format="json"
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
