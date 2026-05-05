import pytest
from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from core.models import User

User = get_user_model()


@pytest.mark.django_db
class TestSetInitialPasswordEndpoint:
    """Tests for the set_initial_password endpoint"""

    def setup_method(self):
        """Set up test client and test user"""
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='InitialPassword123!',
            first_login_completed=False
        )

    def test_set_initial_password_success(self):
        """Test successful password change on first login"""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.post(
            f'/api/v1/users/{self.user.id}/set_initial_password/',
            {'password': 'NewPassword123!'},
            format='json'
        )
        
        assert response.status_code == status.HTTP_200_OK
        
        # Refresh from DB and verify
        self.user.refresh_from_db()
        assert self.user.first_login_completed is True
        assert self.user.check_password('NewPassword123!')

    def test_set_initial_password_already_completed(self):
        """Test that endpoint rejects if first login already completed"""
        self.user.first_login_completed = True
        self.user.save()
        
        self.client.force_authenticate(user=self.user)
        
        response = self.client.post(
            f'/api/v1/users/{self.user.id}/set_initial_password/',
            {'password': 'NewPassword123!'},
            format='json'
        )
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_set_initial_password_other_user_forbidden(self):
        """Test that user cannot set password for another user"""
        other_user = User.objects.create_user(
            username='otheruser',
            email='other@example.com',
            password='OtherPassword123!',
            first_login_completed=False
        )
        
        self.client.force_authenticate(user=self.user)
        
        response = self.client.post(
            f'/api/v1/users/{other_user.id}/set_initial_password/',
            {'password': 'NewPassword123!'},
            format='json'
        )
        
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_set_initial_password_weak_password(self):
        """Test that weak passwords are rejected"""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.post(
            f'/api/v1/users/{self.user.id}/set_initial_password/',
            {'password': '123'},  # Too weak
            format='json'
        )
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        
        # Verify password was not changed
        self.user.refresh_from_db()
        assert self.user.first_login_completed is False

    def test_set_initial_password_missing_password(self):
        """Test that endpoint rejects missing password"""
        self.client.force_authenticate(user=self.user)
        
        response = self.client.post(
            f'/api/v1/users/{self.user.id}/set_initial_password/',
            {},
            format='json'
        )
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_set_initial_password_unauthenticated(self):
        """Test that unauthenticated users cannot call endpoint"""
        response = self.client.post(
            f'/api/v1/users/{self.user.id}/set_initial_password/',
            {'password': 'NewPassword123!'},
            format='json'
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestUserSerializerIncludesFirstLogin:
    """Tests to verify first_login_completed is included in serializer"""

    def test_user_detail_includes_first_login_completed(self):
        """Test that GET /users/{id}/ includes first_login_completed"""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='TestPassword123!',
            first_login_completed=False
        )
        
        client = APIClient()
        client.force_authenticate(user=user)
        
        response = client.get(f'/api/v1/users/{user.id}/')
        
        assert response.status_code == status.HTTP_200_OK
        assert 'first_login_completed' in response.data
        assert response.data['first_login_completed'] is False

    def test_user_list_includes_first_login_completed(self):
        """Test that GET /users/ includes first_login_completed for all users"""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='TestPassword123!',
            first_login_completed=False
        )
        
        admin = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='AdminPassword123!',
            first_login_completed=True,
            is_staff=True
        )
        
        client = APIClient()
        client.force_authenticate(user=admin)
        
        response = client.get('/api/v1/users/')
        
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) >= 1
        assert all('first_login_completed' in item for item in response.data)
