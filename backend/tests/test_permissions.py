"""Comprehensive tests for custom permission classes"""
import pytest
from rest_framework.test import APIRequestFactory
from api.v1.permissions import (
    IsOwnerOrStaff, IsStaffOrReadOnly, IsAdminOrReadOnly,
    IsElectedOrAgentOrAdmin, IsOwnerOrReadOnly
)
from core.db.models import Report, Survey
from unittest.mock import Mock
from types import SimpleNamespace
from datetime import timedelta
from django.utils import timezone

pytestmark = pytest.mark.django_db


class TestIsOwnerOrStaff:
    """Test IsOwnerOrStaff permission class"""
    
    def test_read_allowed_for_authenticated(self, citizen_user):
        """Test SAFE_METHODS allowed for authenticated users"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = citizen_user
        
        permission = IsOwnerOrStaff()
        mock_obj = Mock()
        mock_view = Mock()
        
        assert permission.has_object_permission(request, mock_view, mock_obj) is True
    
    def test_write_allowed_for_staff(self, elected_user, report):
        """Test write methods allowed for staff"""
        factory = APIRequestFactory()
        request = factory.post('/api/test/')
        request.user = elected_user
        
        permission = IsOwnerOrStaff()
        mock_view = Mock()
        
        assert permission.has_object_permission(request, mock_view, report) is True
    
    def test_write_allowed_for_owner_with_user_attr(self, citizen_user, neighborhood):
        """Test write allowed for owner (object.user)"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = citizen_user
        
        # Create report owned by citizen_user
        report = Report.objects.create(
            user=citizen_user,
            problem_type='ROADS',
            description='Test',
            neighborhood=neighborhood
        )
        
        permission = IsOwnerOrStaff()
        mock_view = Mock()
        
        assert permission.has_object_permission(request, mock_view, report) is True
    
    def test_write_denied_for_non_owner(self, citizen_user, elected_user, neighborhood):
        """Test write denied for non-owner non-staff"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = citizen_user
        
        # Create report owned by different user
        report = Report.objects.create(
            user=elected_user,
            problem_type='ROADS',
            description='Test',
            neighborhood=neighborhood
        )
        
        permission = IsOwnerOrStaff()
        mock_view = Mock()
        
        assert permission.has_object_permission(request, mock_view, report) is False

    def test_write_allowed_for_owner_with_created_by(self, citizen_user):
        """Test write allowed for owner via created_by"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = citizen_user

        survey = Survey.objects.create(
            title='Owner Survey',
            description='Test',
            address='1 rue des Tests, Novaville',
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=1),
            created_by=citizen_user
        )

        permission = IsOwnerOrStaff()
        mock_view = Mock()

        assert permission.has_object_permission(request, mock_view, survey) is True

    def test_write_denied_without_owner_fields(self, citizen_user):
        """Test write denied when object has no owner fields"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = citizen_user

        permission = IsOwnerOrStaff()
        mock_view = Mock()
        obj = SimpleNamespace()

        assert permission.has_object_permission(request, mock_view, obj) is False


class TestIsStaffOrReadOnly:
    """Test IsStaffOrReadOnly permission"""
    
    def test_unauthenticated_denied(self):
        """Test unauthenticated requests denied"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = Mock(is_authenticated=False)
        
        permission = IsStaffOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is False
    
    def test_read_allowed_for_authenticated(self, citizen_user):
        """Test read allowed for authenticated non-staff"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = citizen_user
        
        permission = IsStaffOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is True
    
    def test_write_denied_for_non_staff(self, citizen_user):
        """Test write denied for non-staff"""
        factory = APIRequestFactory()
        request = factory.post('/api/test/')
        request.user = citizen_user
        
        permission = IsStaffOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is False
    
    def test_write_allowed_for_staff(self, elected_user):
        """Test write allowed for staff"""
        factory = APIRequestFactory()
        request = factory.post('/api/test/')
        request.user = elected_user
        
        permission = IsStaffOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is True


class TestIsAdminOrReadOnly:
    """Test IsAdminOrReadOnly permission"""
    
    def test_unauthenticated_denied(self):
        """Test unauthenticated requests denied"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = Mock(is_authenticated=False)
        
        permission = IsAdminOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is False
    
    def test_read_allowed_for_any_authenticated(self, citizen_user):
        """Test read allowed for any authenticated user"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = citizen_user
        
        permission = IsAdminOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is True
    
    def test_write_denied_for_non_admin(self, elected_user):
        """Test write denied for non-admin staff"""
        factory = APIRequestFactory()
        request = factory.post('/api/test/')
        request.user = elected_user
        
        permission = IsAdminOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is False
    
    def test_write_allowed_for_admin(self, admin_user):
        """Test write allowed for admin"""
        factory = APIRequestFactory()
        request = factory.post('/api/test/')
        request.user = admin_user
        
        permission = IsAdminOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is True


class TestIsElectedOrAgentOrAdmin:
    """Test IsElectedOrAgentOrAdmin permission"""
    
    def test_unauthenticated_denied(self):
        """Test unauthenticated requests denied"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = Mock(is_authenticated=False)
        
        permission = IsElectedOrAgentOrAdmin()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is False
    
    def test_citizen_denied(self, citizen_user):
        """Test citizen denied"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = citizen_user
        
        permission = IsElectedOrAgentOrAdmin()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is False
    
    def test_elected_allowed(self, elected_user):
        """Test elected official allowed"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = elected_user
        
        permission = IsElectedOrAgentOrAdmin()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is True
    
    def test_agent_allowed(self, agent_user):
        """Test agent allowed"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = agent_user
        
        permission = IsElectedOrAgentOrAdmin()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is True
    
    def test_admin_allowed(self, admin_user):
        """Test admin allowed"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        request.user = admin_user
        
        permission = IsElectedOrAgentOrAdmin()
        mock_view = Mock()
        
        assert permission.has_permission(request, mock_view) is True


class TestIsOwnerOrReadOnly:
    """Test IsOwnerOrReadOnly permission"""
    
    def test_read_always_allowed(self):
        """Test read operations always allowed"""
        factory = APIRequestFactory()
        request = factory.get('/api/test/')
        
        permission = IsOwnerOrReadOnly()
        mock_view = Mock()
        mock_obj = Mock()
        
        assert permission.has_object_permission(request, mock_view, mock_obj) is True
    
    def test_write_allowed_for_owner_via_user(self, citizen_user, neighborhood):
        """Test write allowed for owner via user attribute"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = citizen_user
        
        report = Report.objects.create(
            user=citizen_user,
            problem_type='ROADS',
            description='Test',
            neighborhood=neighborhood
        )
        
        permission = IsOwnerOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_object_permission(request, mock_view, report) is True
    
    def test_write_allowed_for_owner_via_created_by(self, elected_user):
        """Test write allowed for owner via created_by attribute"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = elected_user
        
        survey = Survey.objects.create(
            title='Test',
            description='Test',
            address='2 rue des Tests, Novaville',
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=1),
            created_by=elected_user
        )
        
        permission = IsOwnerOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_object_permission(request, mock_view, survey) is True
    
    def test_write_denied_for_non_owner_non_staff(self, citizen_user, elected_user):
        """Test write denied for non-owner non-staff"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = citizen_user
        
        survey = Survey.objects.create(
            title='Test',
            description='Test',
            address='3 rue des Tests, Novaville',
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=1),
            created_by=elected_user
        )
        
        permission = IsOwnerOrReadOnly()
        mock_view = Mock()
        
        assert permission.has_object_permission(request, mock_view, survey) is False
    
    def test_write_allowed_for_staff_without_owner_fields(self):
        """Test write allowed for staff when object has no owner fields"""
        factory = APIRequestFactory()
        request = factory.put('/api/test/')
        request.user = SimpleNamespace(is_staff=True)

        permission = IsOwnerOrReadOnly()
        mock_view = Mock()
        obj = SimpleNamespace()

        assert permission.has_object_permission(request, mock_view, obj) is True
