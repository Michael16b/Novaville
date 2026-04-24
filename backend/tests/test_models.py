"""Tests for Novaville database models"""
import pytest
from django.db import IntegrityError
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from datetime import timedelta
from django.utils import timezone
from core.db.models import (
    Neighborhood, Report, Survey, SurveyOption, Event, 
    ThemeEvent, Vote, UsefulInfo, RoleEnum, ProblemTypeEnum, 
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
            title="Report 1",
            problem_type=ProblemTypeEnum.ROADS,
            description="Report 1",
            neighborhood=neighborhood
        )
        Report.objects.create(
            user=citizen_user,
            title="Report 2",
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Report 2",
            neighborhood=neighborhood
        )
        assert neighborhood.reports.count() == 2


class TestReportModel:
    """Tests for Report model"""
    
    def test_report_creation(self, citizen_user, neighborhood):
        """Test creating a report"""
        report = Report.objects.create(
            user=citizen_user,
            title="Road pothole",
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
            title="First report",
            problem_type=ProblemTypeEnum.ROADS,
            description="First",
            neighborhood=neighborhood
        )
        report2 = Report.objects.create(
            user=citizen_user,
            title="Second report",
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
            address="5 rue de la Republique, Novaville",
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
            address="7 rue Pasteur, Novaville",
            created_by=elected_user,
            start_date=timezone.now() - timedelta(days=1),
            end_date=timezone.now() + timedelta(days=1)
        )
        assert active.is_active is True
        
        # Expired survey
        expired = Survey.objects.create(
            title="Expired",
            address="11 rue Pasteur, Novaville",
            created_by=elected_user,
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=1)
        )
        assert expired.is_active is False




class TestUsefulInfoModel:
    """Tests to ensure UsefulInfo behaves as a singleton"""

    def test_save_enforces_singleton(self):
        # creating first instance sets pk=1
        info1 = UsefulInfo.objects.create(
            city_hall_name="A",
            address_line1="Addr A",
            postal_code="00000",
            city="Novaville",
            phone="000",
            email="a@novaville",
            website="http://example.com",
        )
        assert info1.pk == 1
        # creating a second object should not create a new row but overwrite
        info2 = UsefulInfo.objects.create(
            city_hall_name="B",
            address_line1="Addr B",
            postal_code="11111",
            city="Other",
            phone="111",
            email="b@novaville",
            website="http://example.org",
        )
        assert info2.pk == 1
        assert UsefulInfo.objects.count() == 1
        # latest values have replaced previous
        obj = UsefulInfo.objects.first()
        assert obj.city_hall_name == "B"
        assert obj.city == "Other"

    def test_delete_noop(self):
        info = UsefulInfo.objects.create(
            city_hall_name="C",
            address_line1="Addr C",
            postal_code="22222",
            city="CityC",
            phone="222",
            email="c@novaville",
            website="http://example.net",
        )
        info.delete()
        # record should still exist
        assert UsefulInfo.objects.count() == 1

    def test_opening_hours_validation_correct_format(self):
        """Test that valid opening_hours passes validation."""
        valid_hours = {
            "Monday": ["09:00-12:00", "13:00-17:00"],
            "Tuesday": ["09:00-17:00"],
            "Saturday": [],
        }
        info = UsefulInfo(
            city_hall_name="Test",
            address_line1="Addr",
            postal_code="00000",
            city="City",
            phone="111",
            email="test@example.com",
            website="http://example.com",
            opening_hours=valid_hours,
        )
        info.full_clean()  # Should not raise
        info.save()
        assert info.pk == 1

    def test_opening_hours_validation_rejects_string(self):
        """Test that a simple string for opening_hours is rejected."""
        info = UsefulInfo(
            city_hall_name="Test",
            address_line1="Addr",
            postal_code="00000",
            city="City",
            phone="111",
            email="test@example.com",
            website="http://example.com",
            opening_hours="09:00-16:00",  # Wrong: string instead of dict
        )
        with pytest.raises(ValidationError):
            info.full_clean()

    def test_opening_hours_validation_rejects_list_values(self):
        """Test that non-list values in opening_hours are rejected."""
        info = UsefulInfo(
            city_hall_name="Test",
            address_line1="Addr",
            postal_code="00000",
            city="City",
            phone="111",
            email="test@example.com",
            website="http://example.com",
            opening_hours={"Monday": "09:00-16:00"},  # Wrong: string value instead of list
        )
        with pytest.raises(ValidationError):
            info.full_clean()


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


class TestModelStrMethods:
    """Test string representations for all models"""
    
    def test_user_str(self, citizen_user):
        """Test User __str__ method"""
        expected = f"{citizen_user.get_full_name() or citizen_user.username} ({citizen_user.get_role_display()})"
        assert str(citizen_user) == expected
    
    def test_neighborhood_str(self, neighborhood):
        """Test Neighborhood __str__ method"""
        expected = f"{neighborhood.name} ({neighborhood.postal_code})"
        assert str(neighborhood) == expected
    
    def test_report_str(self, citizen_user, neighborhood):
        """Test Report __str__ method"""
        report = Report.objects.create(
            user=citizen_user,
            title="Road pothole issue",
            problem_type='ROADS',
            status='RECORDED',
            description='Test',
            neighborhood=neighborhood
        )
        expected = f"Report #{report.id} - Road pothole issue ({report.get_status_display()})"
        assert str(report) == expected
    
    def test_survey_str(self, survey_with_options):
        """Test Survey __str__ method"""
        assert str(survey_with_options) == survey_with_options.title
    
    def test_survey_option_str(self, survey_with_options):
        """Test SurveyOption __str__ method"""
        option = survey_with_options.options.first()
        expected = f"{survey_with_options.title} - {option.text}"
        assert str(option) == expected
    
    def test_vote_str(self, citizen_user, survey_with_options):
        """Test Vote __str__ method"""
        option = survey_with_options.options.first()
        vote = Vote.objects.create(
            user=citizen_user,
            survey=survey_with_options,
            option=option
        )
        expected = f"{citizen_user.username} voted on {survey_with_options.title}"
        assert str(vote) == expected
    
    def test_theme_event_str(self, theme):
        """Test ThemeEvent __str__ method"""
        assert str(theme) == theme.title
    
    def test_event_str(self, elected_user, theme):
        """Test Event __str__ method"""
        event = Event.objects.create(
            title="Test Event",
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(hours=2),
            theme=theme,
            created_by=elected_user
        )
        expected = f"{event.title} ({event.start_date.strftime('%Y-%m-%d')})"
        assert str(event) == expected
