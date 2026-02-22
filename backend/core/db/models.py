from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models


# ============================================================================
# ENUMS
# ============================================================================

class RoleEnum(models.TextChoices):
    """User roles in the system"""
    CITIZEN = 'CITIZEN', 'Citizen'
    ELECTED = 'ELECTED', 'Elected Official'
    AGENT = 'AGENT', 'Municipal Agent'
    GLOBAL_ADMIN = 'GLOBAL_ADMIN', 'Global Administrator'


class ProblemTypeEnum(models.TextChoices):
    """Types of problems that can be reported"""
    ROADS = 'ROADS', 'Roads'
    LIGHTING = 'LIGHTING', 'Lighting'
    CLEANLINESS = 'CLEANLINESS', 'Cleanliness'


class ReportStatusEnum(models.TextChoices):
    """Status of a citizen report"""
    RECORDED = 'RECORDED', 'Recorded'
    IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
    RESOLVED = 'RESOLVED', 'Resolved'


class ThemeEnum(models.TextChoices):
    """Event themes"""
    SPORT = 'SPORT', 'Sport'
    CULTURE = 'CULTURE', 'Culture'
    CITIZENSHIP = 'CITIZENSHIP', 'Citizenship'
    ENVIRONMENT = 'ENVIRONMENT', 'Environment'
    OTHER = 'OTHER', 'Other'


# ============================================================================
# CUSTOM USER MODEL
# ============================================================================

class User(AbstractUser):
    """Custom user model with role-based access"""
    role = models.CharField(
        max_length=20,
        choices=RoleEnum.choices,
        default=RoleEnum.CITIZEN,
        help_text="User role in the system"
    )
    neighborhood = models.ForeignKey(
        'Neighborhood',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='residents',
        help_text="User's neighborhood"
    )
    
    class Meta:
        db_table = 'users'
        ordering = ['-date_joined']
    
    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.get_role_display()})"
    
    @property
    def is_citizen(self):
        return self.role == RoleEnum.CITIZEN
    
    @property
    def is_staff_member(self):
        return self.role in [RoleEnum.ELECTED, RoleEnum.AGENT, RoleEnum.GLOBAL_ADMIN]


# ============================================================================
# MODELS
# ============================================================================

class Neighborhood(models.Model):
    """Neighborhood/District within the city"""
    name = models.CharField(max_length=255, help_text="Neighborhood name")
    postal_code = models.CharField(max_length=10, help_text="Postal code")
    
    class Meta:
        db_table = 'neighborhoods'
        ordering = ['name']
        verbose_name = 'Neighborhood'
        verbose_name_plural = 'Neighborhoods'
    
    def __str__(self):
        return f"{self.name} ({self.postal_code})"


class Report(models.Model):
    """Citizen report about city issues"""
    problem_type = models.CharField(
        max_length=20,
        choices=ProblemTypeEnum.choices,
        help_text="Type of problem reported"
    )
    description = models.TextField(help_text="Detailed description of the issue")
    created_at = models.DateTimeField(auto_now_add=True, help_text="Report creation date")
    status = models.CharField(
        max_length=20,
        choices=ReportStatusEnum.choices,
        default=ReportStatusEnum.RECORDED,
        help_text="Current status of the report"
    )
    citizen_target = models.CharField(
        max_length=20,
        choices=RoleEnum.choices,
        blank=True,
        null=True,
        help_text="Target role for this report"
    )
    # Foreign keys
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports',
        help_text="User who created the report"
    )
    neighborhood = models.ForeignKey(
        'Neighborhood',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reports',
        help_text="Neighborhood where the issue was reported"
    )
    
    class Meta:
        db_table = 'reports'
        ordering = ['-created_at']
        verbose_name = 'Report'
        verbose_name_plural = 'Reports'
    
    def __str__(self):
        return f"Report #{self.id} - {self.get_problem_type_display()} ({self.get_status_display()})"


class Survey(models.Model):
    """Public survey/consultation"""
    title = models.CharField(max_length=255, help_text="Survey title")
    description = models.TextField(help_text="Survey description")
    created_at = models.DateTimeField(auto_now_add=True, help_text="Survey creation date")
    start_date = models.DateTimeField(help_text="Survey start date")
    end_date = models.DateTimeField(help_text="Survey end date")
    # Foreign keys
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_surveys',
        help_text="User who created the survey"
    )
    
    class Meta:
        db_table = 'surveys'
        ordering = ['-created_at']
        verbose_name = 'Survey'
        verbose_name_plural = 'Surveys'
    
    def __str__(self):
        return f"{self.title}"
    
    @property
    def is_active(self):
        from django.utils import timezone
        now = timezone.now()
        return self.start_date <= now <= self.end_date


class SurveyOption(models.Model):
    """Option/choice for a survey"""
    survey = models.ForeignKey(
        'Survey',
        on_delete=models.CASCADE,
        related_name='options',
        help_text="Survey this option belongs to"
    )
    text = models.CharField(max_length=255, help_text="Option text")
    
    class Meta:
        db_table = 'survey_options'
        ordering = ['id']
        verbose_name = 'Survey Option'
        verbose_name_plural = 'Survey Options'
    
    def __str__(self):
        return f"{self.survey.title} - {self.text}"


class Vote(models.Model):
    """User vote on a survey"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="User who voted"
    )
    survey = models.ForeignKey(
        'Survey',
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="Survey being voted on"
    )
    option = models.ForeignKey(
        'SurveyOption',
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="Selected option"
    )
    created_at = models.DateTimeField(auto_now_add=True, help_text="Vote timestamp")
    
    class Meta:
        db_table = 'votes'
        ordering = ['-created_at']
        verbose_name = 'Vote'
        verbose_name_plural = 'Votes'
        # Ensure a user can only vote once per survey
        unique_together = [['user', 'survey']]
    
    def __str__(self):
        return f"{self.user.username} voted on {self.survey.title}"


class ThemeEvent(models.Model):
    """Event theme/category"""
    title = models.CharField(max_length=100, unique=True, help_text="Theme title")
    
    class Meta:
        db_table = 'theme_events'
        ordering = ['title']
        verbose_name = 'Event Theme'
        verbose_name_plural = 'Event Themes'
    
    def __str__(self):
        return self.title


class Event(models.Model):
    """City or association event"""
    title = models.CharField(max_length=255, help_text="Event title")
    description = models.TextField(help_text="Event description")
    start_date = models.DateTimeField(help_text="Event start date and time")
    end_date = models.DateTimeField(help_text="Event end date and time")
    # Foreign keys
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_events',
        help_text="User who created the event"
    )
    theme = models.ForeignKey(
        'ThemeEvent',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='events',
        help_text="Event theme/category"
    )
    
    class Meta:
        db_table = 'events'
        ordering = ['start_date']
        verbose_name = 'Event'
        verbose_name_plural = 'Events'
    
    def __str__(self):
        return f"{self.title} ({self.start_date.strftime('%Y-%m-%d')})"
