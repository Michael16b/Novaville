from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from core.db.models import Report, Survey, Event, User, Vote, ReportStatusEnum, ProblemTypeEnum, RoleEnum
from api.v1.survey_access import all_citizens_target_filter, visible_survey_filter
from django.utils import timezone
from datetime import timedelta
from rest_framework.decorators import action
from drf_spectacular.utils import extend_schema, extend_schema_view
from django.db.models import Count, Q, Exists, OuterRef

@extend_schema_view(
    stats=extend_schema(
        summary="Get dashboard statistics",
        description="Retrieve key statistics for the dashboard homepage, including user-specific data.",
        tags=["Dashboard"],
    )
)
class DashboardViewSet(viewsets.ViewSet):
    """
    A simple ViewSet for providing dashboard statistics.
    """
    permission_classes = [AllowAny]

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Returns a summary of key metrics:
        - Pending reports count
        - Active surveys count
        - Events this week count (Monday to Sunday)
        - Unresolved reports by category (Roads, Lighting, Cleanliness)
        - Total citizen count
        - Reports created this month
        - User's participation rate in active surveys
        """
        now = timezone.now()
        user = request.user

        # --- Top Stats ---
        pending_reports_count = Report.objects.filter(status=ReportStatusEnum.RECORDED).count()
        active_surveys = Survey.objects.filter(start_date__lte=now, end_date__gte=now)
        if user.is_authenticated:
            active_surveys = active_surveys.filter(visible_survey_filter(user))
        else:
            active_surveys = active_surveys.filter(all_citizens_target_filter())
        active_surveys_count = active_surveys.count()
        
        # Calculate start of the week (Monday at 00:00)
        # weekday() returns 0 for Monday, 6 for Sunday
        start_of_week = now - timedelta(days=now.weekday())
        start_of_week = start_of_week.replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Calculate start of next week (Next Monday at 00:00)
        end_of_week = start_of_week + timedelta(days=7)
        
        events_this_week_count = Event.objects.filter(
            start_date__gte=start_of_week,
            start_date__lt=end_of_week
        ).count()

        # --- Useful Info Panel Stats ---
        unresolved_reports_roads = Report.objects.filter(
            problem_type=ProblemTypeEnum.ROADS
        ).exclude(status=ReportStatusEnum.RESOLVED).count()
        
        unresolved_reports_lighting = Report.objects.filter(
            problem_type=ProblemTypeEnum.LIGHTING
        ).exclude(status=ReportStatusEnum.RESOLVED).count()

        unresolved_reports_cleanliness = Report.objects.filter(
            problem_type=ProblemTypeEnum.CLEANLINESS
        ).exclude(status=ReportStatusEnum.RESOLVED).count()

        # --- Bottom Stats Bar ---
        total_citizens = User.objects.filter(role=RoleEnum.CITIZEN).count()
        
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        reports_this_month = Report.objects.filter(created_at__gte=start_of_month).count()

        # --- User-specific Poll Participation ---
        active_surveys_total = active_surveys.count()
        
        if active_surveys_total > 0 and user.is_authenticated:
            # Subquery to check if the user has voted on a survey
            user_voted_subquery = Vote.objects.filter(
                survey=OuterRef('pk'),
                user=user
            )
            # Count active surveys where the user has voted
            surveys_voted_by_user = active_surveys.annotate(
                user_voted=Exists(user_voted_subquery)
            ).filter(user_voted=True).count()
            
            poll_participation_rate = (surveys_voted_by_user / active_surveys_total) * 100
        else:
            poll_participation_rate = 0


        data = {
            # Top stats
            'pending_reports': pending_reports_count,
            'active_surveys': active_surveys_count,
            'events_this_week': events_this_week_count,
            # Useful info stats
            'unresolved_reports_roads': unresolved_reports_roads,
            'unresolved_reports_lighting': unresolved_reports_lighting,
            'unresolved_reports_cleanliness': unresolved_reports_cleanliness,
            # Bottom bar stats
            'total_citizens': total_citizens,
            'reports_this_month': reports_this_month,
            'poll_participation_rate': round(poll_participation_rate),
        }
        
        return Response(data, status=status.HTTP_200_OK)
