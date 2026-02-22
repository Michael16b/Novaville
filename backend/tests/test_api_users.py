"""Tests for Users and Neighborhoods API endpoints"""
import pytest
from rest_framework import status

pytestmark = pytest.mark.django_db


class TestUsersAPI:
    """Tests for users endpoints"""
    
    def test_list_users(self, authenticated_client, citizen_user):
        """Test listing users"""
        response = authenticated_client.get("/api/v1/users/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
    
    def test_create_user(self, api_client, neighborhood):
        """Test creating a new user (registration)"""
        data = {
            "username": "newuser",
            "email": "newuser@test.com",
            "password": "NewPass123",
            "first_name": "New",
            "last_name": "User",
            "neighborhood": neighborhood.id
        }
        response = api_client.post("/api/v1/users/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["username"] == "newuser"
        assert "password" not in response.data  # Password should not be returned
    
    def test_retrieve_user(self, authenticated_client, citizen_user):
        """Test retrieving a user"""
        response = authenticated_client.get(f"/api/v1/users/{citizen_user.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == citizen_user.id
    
    def test_me_endpoint(self, authenticated_client, citizen_user):
        """Test /me/ endpoint returns current user"""
        response = authenticated_client.get("/api/v1/users/me/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["username"] == citizen_user.username
        assert response.data["email"] == citizen_user.email
    
    def test_update_own_profile(self, authenticated_client, citizen_user):
        """Test user can update their own profile"""
        data = {"first_name": "Updated"}
        response = authenticated_client.patch(
            f"/api/v1/users/{citizen_user.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["first_name"] == "Updated"
    
    def test_cannot_update_other_user(self, authenticated_client, elected_user):
        """Test user cannot update another user's profile"""
        data = {"first_name": "Hacked"}
        response = authenticated_client.patch(
            f"/api/v1/users/{elected_user.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_admin_can_update_any_user(self, admin_client, citizen_user):
        """Test admin can update any user"""
        data = {"first_name": "AdminUpdated"}
        response = admin_client.patch(
            f"/api/v1/users/{citizen_user.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["first_name"] == "AdminUpdated"


class TestNeighborhoodsAPI:
    """Tests for neighborhoods endpoints"""
    
    def test_list_neighborhoods(self, authenticated_client, neighborhood):
        """Test listing neighborhoods"""
        response = authenticated_client.get("/api/v1/neighborhoods/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
    
    def test_create_neighborhood(self, admin_client):
        """Test admin can create neighborhood"""
        data = {
            "name": "New Neighborhood",
            "postal_code": "75010"
        }
        response = admin_client.post("/api/v1/neighborhoods/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["name"] == "New Neighborhood"
    
    def test_citizen_cannot_create_neighborhood(self, authenticated_client):
        """Test citizen cannot create neighborhood"""
        data = {
            "name": "Unauthorized",
            "postal_code": "75020"
        }
        response = authenticated_client.post("/api/v1/neighborhoods/", data, format="json")
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_retrieve_neighborhood(self, authenticated_client, neighborhood):
        """Test retrieving a neighborhood"""
        response = authenticated_client.get(f"/api/v1/neighborhoods/{neighborhood.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == neighborhood.id
    
    def test_update_neighborhood(self, admin_client, neighborhood):
        """Test updating a neighborhood"""
        data = {"name": "Updated Name"}
        response = admin_client.patch(
            f"/api/v1/neighborhoods/{neighborhood.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "Updated Name"
    
    def test_delete_neighborhood(self, admin_client):
        """Test deleting a neighborhood"""
        from core.db.models import Neighborhood
        neighborhood = Neighborhood.objects.create(
            name="To Delete",
            postal_code="99999"
        )
        response = admin_client.delete(f"/api/v1/neighborhoods/{neighborhood.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
