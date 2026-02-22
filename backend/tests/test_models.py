"""Tests for Novaville database models"""
import pytest
from django.db import IntegrityError
from django.contrib.auth import get_user_model
from datetime import timedelta
from django.utils import timezone
from core.db.models import (
    Neighborhood, Report, Survey, SurveyOption, Event, 
    ThemeEvent, Vote, RoleEnum, ProblemTypeEnum, 
    ReportStatusEnum, ThemeEnum
)

User = get_user_model()

pytestmark = pytest.mark.django_db


class TestUserModel:
    """Tests for User model"""
    
    def test_user_creation(self, neighborhood):
        """Test creating a user with all fields"""
        user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
            first_name="Test",
            last_name="User",
            role=RoleEnum.CITIZEN,
            neighborhood=neighborhood
        )
        assert user.username == "testuser"
        assert user.email == "test@example.com"
        assert user.first_name == "Test"
        assert user.last_name == "User"
        assert user.role == RoleEnum.CITIZEN
        assert user.neighborhood == neighborhood
        assert user.is_active is True
        assert user.check_password("testpass123")
    
    def test_user_default_role(self):
        """Test that default role is CITIZEN"""
        user = User.objects.create_user(
            username="defaultuser",
            email="default@example.com",
            password="pass123"
        )
        assert user.role == RoleEnum.CITIZEN
    
    def test_user_is_citizen_property(self, citizen_user):
        """Test is_citizen property"""
        assert citizen_user.is_citizen is True
    
    def test_user_is_staff_member_property(self, elected_user, agent_user, admin_user, citizen_user):
        """Test is_staff_member property"""
        assert elected_user.is_staff_member is True
        assert agent_user.is_staff_member is True
        assert admin_user.is_staff_member is True
        assert citizen_user.is_staff_member is False
    
    def test_user_str_representation(self, citizen_user):
        """Test string representation"""
        assert "Test Citizen" in str(citizen_user)
        assert "Citizen" in str(citizen_user)


class TestNeighborhoodModel:
    """Tests for Neighborhood model"""
    
    def test_neighborhood_creation(self):
        """Test creating a neighborhood"""
        neighborhood = Neighborhood.objects.create(
            name="Downtown",
            postal_code="75001"
        )
        assert neighborhood.name == "Downtown"
        assert neighborhood.postal_code == "75001"
    
    def test_neighborhood_residents_relation(self, neighborhood):
        """Test residents relationship"""
        user1 = User.objects.create_user(
            username="resident1",
            email="r1@test.com",
            password="pass",
            neighborhood=neighborhood
        )
        user2 = User.objects.create_user(
            username="resident2",
            email="r2@test.com",
            password="pass",
            neighborhood=neighborhood
        )
        assert neighborhood.residents.count() == 2
        assert user1 in neighborhood.residents.all()
        assert user2 in neighborhood.residents.all()
    
    def test_neighborhood_reports_count(self, neighborhood, citizen_user):
        """Test reports relationship and count"""
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Report 1",
            neighborhood=neighborhood
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Report 2",
            neighborhood=neighborhood
        )
        assert neighborhood.reports.count() == 2
        assert neighborhood.total_reports == 2


class TestReportModel:
    """Tests for Report model"""
    
    def test_report_creation(self, citizen_user, neighborhood):
        """Test creating a report"""
        report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Pothole on main street",
            neighborhood=neighborhood
        )
        assert report.user == citizen_user
        assert report.problem_type == ProblemTypeEnum.ROADS
        assert report.status == ReportStatusEnum.RECORDED
        assert report.neighborhood == neighborhood
    
    def test_report_status_change(self, report):
        """Test changing report status"""
        report.status = ReportStatusEnum.IN_PROGRESS
        report.save()
        report.refresh_from_db()
        assert report.status == ReportStatusEnum.IN_PROGRESS
    
    def test_report_ordering(self, citizen_user, neighborhood):
        """Test reports are ordered by creation date descending"""
        report1 = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="First",
            neighborhood=neighborhood
        )
        report2 = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Second",
            neighborhood=neighborhood
        )
        reports = Report.objects.all()
        assert reports[0] == report2
        assert reports[1] == report1


class TestSurveyModel:
    """Tests for Survey and SurveyOption models"""
    
    def test_survey_creation(self, elected_user):
        """Test creating a survey"""
        survey = Survey.objects.create(
            title="Test Survey",
            description="Survey description",
            created_by=elected_user,
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=7)
        )
        assert survey.title == "Test Survey"
        assert survey.created_by == elected_user
        assert survey.is_active is True
    
    def test_survey_with_options(self, survey_with_options):
        """Test survey with options"""
        assert survey_with_options.options.count() == 2
        option = survey_with_options.options.first()
        assert option.survey == survey_with_options
    
    def test_survey_is_active_property(self, elected_user):
        """Test is_active property"""
        # Active survey
        active = Survey.objects.create(
            title="Active",
            created_by=elected_user,
            start_date=timezone.now() - timedelta(days=1),
            end_date=timezone.now() + timedelta(days=1)
        )
        assert active.is_active is True
        
        # Expired survey
        expired = Survey.objects.create(
            title="Expired",
            created_by=elected_user,
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=1)
        )
        assert expired.is_active is False


class TestVoteModel:
    """Tests for Vote model"""
    
    def test_vote_creation(self, citizen_user, survey_with_options):
        """Test creating a vote"""
        option = survey_with_options.options.first()
        vote = Vote.objects.create(
            user=citizen_user,
            survey=survey_with_options,
            option=option
        )
        assert vote.user == citizen_user
        assert vote.survey == survey_with_options
        assert vote.option == option
    
    def test_vote_uniqueness_constraint(self, citizen_user, survey_with_options):
        """Test user can only vote once per survey"""
        option1 = survey_with_options.options.first()
        option2 = survey_with_options.options.last()
        
        # First vote should work
        Vote.objects.create(
            user=citizen_user,
            survey=survey_with_options,
            option=option1
        )
        
        # Second vote on same survey should fail
        with pytest.raises(IntegrityError):
            Vote.objects.create(
                user=citizen_user,
                survey=survey_with_options,
                option=option2
            )


class TestEventModel:
    """Tests for Event model"""
    
    def test_event_creation(self, elected_user, theme):
        """Test creating an event"""
        start = timezone.now() + timedelta(days=1)
        end = start + timedelta(hours=2)
        
        event = Event.objects.create(
            title="Test Event",
            description="Event description",
            start_date=start,
            end_date=end,
            theme=theme,
            created_by=elected_user
        )
        assert event.title == "Test Event"
        assert event.theme == theme
        assert event.created_by == elected_user
    
    def test_event_ordering(self, elected_user, theme):
        """Test events are ordered by start_date"""
        event1 = Event.objects.create(
            title="Later Event",
            start_date=timezone.now() + timedelta(days=5),
            end_date=timezone.now() + timedelta(days=5, hours=2),
            theme=theme,
            created_by=elected_user
        )
        event2 = Event.objects.create(
            title="Sooner Event",
            start_date=timezone.now() + timedelta(days=2),
            end_date=timezone.now() + timedelta(days=2, hours=2),
            theme=theme,
            created_by=elected_user
        )
        events = Event.objects.all()
        assert events[0] == event2
        assert events[1] == event1
