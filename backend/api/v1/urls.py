from rest_framework.routers import DefaultRouter
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

# Import viewsets
from api.v1.viewsets.user_viewset import UserViewSet
from api.v1.viewsets.neighborhood_viewset import NeighborhoodViewSet
from api.v1.viewsets.report_viewset import ReportViewSet
from api.v1.viewsets.survey_viewset import SurveyViewSet, SurveyOptionViewSet
from api.v1.viewsets.vote_viewset import VoteViewSet
from api.v1.viewsets.event_viewset import EventViewSet, ThemeEventViewSet
from api.v1.viewsets.dashboard_viewset import DashboardViewSet

# Import auth views
from api.v1.auth import LoginView

# Create router and register viewsets
router = DefaultRouter()

# Core models
router.register(r"users", UserViewSet, basename="user")
router.register(r"neighborhoods", NeighborhoodViewSet, basename="neighborhood")
router.register(r"reports", ReportViewSet, basename="report")
router.register(r"surveys", SurveyViewSet, basename="survey")
router.register(r"survey-options", SurveyOptionViewSet, basename="survey-option")
router.register(r"votes", VoteViewSet, basename="vote")
router.register(r"events", EventViewSet, basename="event")
router.register(r"event-themes", ThemeEventViewSet, basename="event-theme")
router.register(r"dashboard", DashboardViewSet, basename="dashboard")

# custom endpoints (not part of router)
from api.v1.viewsets.useful_info_view import UsefulInfoView

# URL patterns: router URLs + authentication endpoints
urlpatterns = router.urls + [
    path("useful-info/", UsefulInfoView.as_view(), name="useful_info"),
    path("auth/token/", LoginView.as_view(), name="token_obtain_pair"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
]
