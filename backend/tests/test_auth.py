"""Tests for JWT authentication"""
import pytest
from rest_framework import status
from datetime import timedelta
from django.utils import timezone

pytestmark = pytest.mark.django_db


class TestAuthentication:
    """Tests for JWT authentication endpoints"""
    
    def test_login_success(self, api_client, citizen_user):
        """Test successful login returns access and refresh tokens"""
        response = api_client.post(
            "/api/v1/auth/token/",
            {
                "username": "testcitizen",
                "password": "TestPass123"
            },
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data
        assert "refresh" in response.data
        assert "user" in response.data
        assert response.data["user"]["username"] == "testcitizen"
        assert response.data["user"]["role"] == "CITIZEN"
    
    def test_login_invalid_credentials(self, api_client, citizen_user):
        """Test login with invalid credentials fails"""
        response = api_client.post(
            "/api/v1/auth/token/",
            {
                "username": "testcitizen",
                "password": "wrongpassword"
            },
            format="json"
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_login_pending_account_rejected(self, api_client, neighborhood):
        from django.contrib.auth import get_user_model
        from core.db.models.user import ApprovalStatus

        user = get_user_model().objects.create_user(
            username="pendinguser",
            email="pending@test.com",
            password="TestPass123",
            first_name="Pending",
            last_name="User",
            neighborhood=neighborhood,
            approval_status=ApprovalStatus.PENDING,
            is_active=False,
        )

        response = api_client.post(
            "/api/v1/auth/token/",
            {
                "username": user.username,
                "password": "TestPass123"
            },
            format="json"
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_login_missing_fields(self, api_client):
        """Test login with missing fields fails"""
        response = api_client.post(
            "/api/v1/auth/token/",
            {"username": "testcitizen"},
            format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    def test_token_refresh(self, api_client, citizen_user):
        """Test token refresh endpoint"""
        # Get initial tokens
        login_response = api_client.post(
            "/api/v1/auth/token/",
            {
                "username": "testcitizen",
                "password": "TestPass123"
            },
            format="json"
        )
        refresh_token = login_response.data["refresh"]
        
        # Refresh the token
        refresh_response = api_client.post(
            "/api/v1/auth/token/refresh/",
            {"refresh": refresh_token},
            format="json"
        )
        assert refresh_response.status_code == status.HTTP_200_OK
        assert "access" in refresh_response.data
    
    def test_authenticated_request(self, authenticated_client):
        """Test that authenticated requests work"""
        response = authenticated_client.get("/api/v1/users/me/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["username"] == "testcitizen"
    
    def test_unauthenticated_request(self, api_client):
        """Test that unauthenticated requests are rejected"""
        response = api_client.get("/api/v1/users/me/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


class TestPermissions:
    """Tests for role-based permissions"""
    
    def test_citizen_can_create_report(self, authenticated_client, neighborhood):
        """Test citizen can create reports"""
        response = authenticated_client.post(
            "/api/v1/reports/",
            {
                "title": "Road issue",
                "problem_type": "ROADS",
                "description": "Test report",
                "address": "10 avenue Victor Hugo",
                "neighborhood": neighborhood.id
            },
            format="json"
        )
        assert response.status_code == status.HTTP_201_CREATED
    
    def test_citizen_cannot_create_survey(self, authenticated_client):
        """Test citizen cannot create surveys"""
        response = authenticated_client.post(
            "/api/v1/surveys/",
            {
                "title": "Test Survey",
                "description": "Test",
                "address": "10 avenue Victor Hugo, Novaville",
                "start_date": timezone.now().isoformat(),
                "end_date": (timezone.now() + timedelta(days=7)).isoformat()
            },
            format="json"
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_elected_can_create_survey(self, elected_client):
        """Test elected official can create surveys"""
        response = elected_client.post(
            "/api/v1/surveys/",
            {
                "title": "Test Survey",
                "description": "Test description",
                "address": "10 avenue Victor Hugo, Novaville",
                "start_date": timezone.now().isoformat(),
                "end_date": (timezone.now() + timedelta(days=7)).isoformat(),
                "options": ["Option 1", "Option 2"]
            },
            format="json"
        )
        assert response.status_code == status.HTTP_201_CREATED
    
    def test_admin_can_delete_users(self, admin_client, citizen_user):
        """Test admin can delete users"""
        response = admin_client.delete(f"/api/v1/users/{citizen_user.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
    
    def test_citizen_cannot_delete_other_users(self, authenticated_client, elected_user):
        """Test citizen cannot delete other users"""
        response = authenticated_client.delete(f"/api/v1/users/{elected_user.id}/")
        assert response.status_code == status.HTTP_403_FORBIDDEN
