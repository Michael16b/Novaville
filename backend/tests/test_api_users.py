"""Tests for Users and Neighborhoods API endpoints"""
import pytest
from rest_framework import status
from rest_framework.test import APIRequestFactory
from unittest.mock import Mock
from api.v1.viewsets.user_viewset import UserViewSet

pytestmark = pytest.mark.django_db


class TestUsersAPI:
    """Tests for users endpoints"""
    
    def test_list_users(self, authenticated_client, citizen_user):
        """Test listing users"""
        response = authenticated_client.get("/api/v1/users/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1

    def test_filter_users_by_role(self, authenticated_client, elected_user):
        """Test filtering users by role"""
        response = authenticated_client.get("/api/v1/users/?role=ELECTED")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
        assert all(user["role"] == "ELECTED" for user in results)


    def test_search_users(self, authenticated_client):
        """Test searching users by text fields"""
        from django.contrib.auth import get_user_model
        User = get_user_model()
        User.objects.create_user(
            username="dupont_user",
            email="dupont@example.com",
            password="TestPass123",
            first_name="Jean",
            last_name="Dupont",
        )

        response = authenticated_client.get("/api/v1/users/?search=dupont")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
        usernames = [user["username"] for user in results]
        assert "dupont_user" in usernames

    def test_order_users(self, authenticated_client):
        """Test ordering users by username"""
        from django.contrib.auth import get_user_model
        User = get_user_model()
        User.objects.create_user(username="aaa_user", email="aaa@test.com", password="TestPass123")
        User.objects.create_user(username="zzz_user", email="zzz@test.com", password="TestPass123")

        response = authenticated_client.get("/api/v1/users/?ordering=username")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        usernames = [user["username"] for user in results]
        assert usernames == sorted(usernames)

    def test_filter_users_with_multiple_attributes(self, authenticated_client, neighborhood):
        """Test combining role, neighborhood and search filters"""
        from django.contrib.auth import get_user_model
        from core.db.models import Neighborhood, RoleEnum

        User = get_user_model()

        other_neighborhood = Neighborhood.objects.create(
            name="Other Neighborhood",
            postal_code="75099"
        )

        matching_user = User.objects.create_user(
            username="multi_match_user",
            email="multi.match@test.com",
            password="TestPass123",
            first_name="Multi",
            last_name="MultiAttrToken",
            role=RoleEnum.CITIZEN,
            neighborhood=neighborhood,
        )

        User.objects.create_user(
            username="multi_wrong_neigh",
            email="multi.neigh@test.com",
            password="TestPass123",
            first_name="Multi",
            last_name="MultiAttrToken",
            role=RoleEnum.CITIZEN,
            neighborhood=other_neighborhood,
        )

        response = authenticated_client.get(
            f"/api/v1/users/?role=CITIZEN&neighborhood={neighborhood.id}&search=multiattrtoken"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)

        returned_ids = [user["id"] for user in results]
        assert matching_user.id in returned_ids

        for user in results:
            assert user["role"] == "CITIZEN"
            assert user["neighborhood"] == neighborhood.id
    
    def test_create_user(self, api_client, neighborhood):
        """Test creating a new user (registration)"""
        from django.contrib.auth import get_user_model
        from core.db.models.user import ApprovalStatus

        data = {
            "username": "newuser",
            "email": "newuser@test.com",
            "password": "NewPass123",
            "first_name": "New",
            "last_name": "User",
            "neighborhood": neighborhood.id,
            "address": "12 rue des Lilas",
        }
        response = api_client.post("/api/v1/users/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["username"] == "newuser"
        created_user = get_user_model().objects.get(username="newuser")
        assert created_user.approval_status == ApprovalStatus.PENDING
        assert created_user.is_active is False
        assert "password" not in response.data  # Password should not be returned

    def test_non_admin_only_sees_approved_users(self, authenticated_client, neighborhood):
        from django.contrib.auth import get_user_model
        from core.db.models.user import ApprovalStatus

        get_user_model().objects.create_user(
            username="pendinghidden",
            email="hidden@test.com",
            password="TestPass123",
            first_name="Hidden",
            last_name="Pending",
            neighborhood=neighborhood,
            approval_status=ApprovalStatus.PENDING,
            is_active=False,
        )

        response = authenticated_client.get("/api/v1/users/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        usernames = [user["username"] for user in results]
        assert "pendinghidden" not in usernames

    def test_admin_can_list_pending_users(self, admin_client, neighborhood):
        from django.contrib.auth import get_user_model
        from core.db.models.user import ApprovalStatus

        pending = get_user_model().objects.create_user(
            username="pendingreview",
            email="pendingreview@test.com",
            password="TestPass123",
            first_name="Pending",
            last_name="Review",
            neighborhood=neighborhood,
            approval_status=ApprovalStatus.PENDING,
            is_active=False,
        )

        response = admin_client.get("/api/v1/users/pending/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        returned_ids = [user["id"] for user in results]
        assert pending.id in returned_ids

    def test_admin_can_approve_pending_user(self, admin_client, neighborhood):
        from django.contrib.auth import get_user_model
        from core.db.models.user import ApprovalStatus

        pending = get_user_model().objects.create_user(
            username="pendingapprove",
            email="pendingapprove@test.com",
            password="TestPass123",
            first_name="Pending",
            last_name="Approve",
            neighborhood=neighborhood,
            approval_status=ApprovalStatus.PENDING,
            is_active=False,
        )

        response = admin_client.post(f"/api/v1/users/{pending.id}/approve/", {}, format="json")
        assert response.status_code == status.HTTP_200_OK
        pending.refresh_from_db()
        assert pending.approval_status == ApprovalStatus.APPROVED
        assert pending.is_active is True

    def test_admin_can_reject_pending_user(self, admin_client, neighborhood):
        from django.contrib.auth import get_user_model
        from core.db.models.user import ApprovalStatus

        pending = get_user_model().objects.create_user(
            username="pendingreject",
            email="pendingreject@test.com",
            password="TestPass123",
            first_name="Pending",
            last_name="Reject",
            neighborhood=neighborhood,
            approval_status=ApprovalStatus.PENDING,
            is_active=False,
        )

        response = admin_client.post(f"/api/v1/users/{pending.id}/reject/", {}, format="json")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert get_user_model().objects.filter(id=pending.id).exists() is False
    
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
    
    def test_update_password(self, authenticated_client, citizen_user):
        """Test user can update their password"""
        data = {"password": "newpassword123"}
        response = authenticated_client.patch(
            f"/api/v1/users/{citizen_user.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        # Refresh from DB to get updated password
        citizen_user.refresh_from_db()
        assert citizen_user.check_password("newpassword123")
    
    def test_cannot_update_other_user(self, authenticated_client, elected_user):
        """Test user cannot update another user's profile"""
        data = {"first_name": "Hacked"}
        response = authenticated_client.patch(
            f"/api/v1/users/{elected_user.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_cannot_update_other_user_put(self, authenticated_client, elected_user):
        """Test user cannot update another user's profile via PUT"""
        data = {"first_name": "Hacked"}
        response = authenticated_client.put(
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

    def test_citizen_cannot_escalate_own_role(self, authenticated_client, citizen_user):
        """Test citizen cannot change their own role to a privileged role"""
        from core.db.models import RoleEnum
        data = {"role": RoleEnum.GLOBAL_ADMIN}
        response = authenticated_client.patch(
            f"/api/v1/users/{citizen_user.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        citizen_user.refresh_from_db()
        assert citizen_user.role == RoleEnum.CITIZEN

    def test_admin_can_change_user_role(self, admin_client, citizen_user):
        """Test admin can change a user's role"""
        from core.db.models import RoleEnum
        data = {"role": RoleEnum.AGENT}
        response = admin_client.patch(
            f"/api/v1/users/{citizen_user.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        citizen_user.refresh_from_db()
        assert citizen_user.role == RoleEnum.AGENT


class TestUserViewSetQueryset:
    """Tests for UserViewSet.get_queryset branches"""

    def test_get_queryset_for_staff(self, admin_user):
        """Test staff can see all users"""
        factory = APIRequestFactory()
        request = factory.get("/api/v1/users/")
        request.user = admin_user

        view = UserViewSet()
        view.request = request

        queryset = view.get_queryset()
        assert queryset.count() >= 1

    def test_get_queryset_for_unauthenticated(self):
        """Test unauthenticated user gets empty queryset"""
        factory = APIRequestFactory()
        request = factory.get("/api/v1/users/")
        request.user = Mock(is_authenticated=False, is_staff=False, is_superuser=False)

        view = UserViewSet()
        view.request = request

        queryset = view.get_queryset()
        assert queryset.count() == 0


class TestNeighborhoodsAPI:
    """Tests for neighborhoods endpoints"""
    
    def test_list_neighborhoods(self, authenticated_client, neighborhood):
        """Test listing neighborhoods"""
        response = authenticated_client.get("/api/v1/neighborhoods/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data
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

    def test_filter_neighborhoods_with_multiple_attributes(self, authenticated_client, neighborhood):
        """Test combining multiple neighborhood filters in one request"""
        response = authenticated_client.get(
            f"/api/v1/neighborhoods/?id={neighborhood.id}&postal_code={neighborhood.postal_code}"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.data

        assert len(results) >= 1
        for neighborhood_data in results:
            assert neighborhood_data["id"] == neighborhood.id
            assert neighborhood_data["postal_code"] == neighborhood.postal_code
    
    def test_delete_neighborhood(self, admin_client):
        """Test deleting a neighborhood"""
        from core.db.models import Neighborhood
        neighborhood = Neighborhood.objects.create(
            name="To Delete",
            postal_code="99999"
        )
        response = admin_client.delete(f"/api/v1/neighborhoods/{neighborhood.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
