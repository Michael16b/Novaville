"""
Database models for the Novaville application.

This package contains all database models organized by domain:
- user: User model with role-based access
- neighborhood: Neighborhood/District model
- report: Citizen report model
- survey: Survey, SurveyOption, and Vote models
- event: Event and ThemeEvent models
"""

# Import enums
from core.db.enums import (
    RoleEnum,
    ProblemTypeEnum,
    ReportStatusEnum,
    ThemeEnum,
)

# Import models
from .user import User
from .neighborhood import Neighborhood
from .report import Report
from .survey import Survey, SurveyOption, Vote
from .event import Event, ThemeEvent
from .useful_info import UsefulInfo

__all__ = [
    # Enums
    'RoleEnum',
    'ProblemTypeEnum',
    'ReportStatusEnum',
    'ThemeEnum',
    # Models
    'User',
    'Neighborhood',
    'Report',
    'Survey',
    'SurveyOption',
    'Vote',
    'Event',
    'ThemeEvent',
    'UsefulInfo',
]
