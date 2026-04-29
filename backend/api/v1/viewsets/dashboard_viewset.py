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


def _elapsed_label(delta):
    """Return a compact French elapsed-time label."""
    seconds = int(delta.total_seconds())
    if seconds < 60:
        return "À l'instant"
    if seconds < 3600:
        minutes = seconds // 60
        return f"{minutes} min"
    if seconds < 86400:
        hours = seconds // 3600
        return f"{hours} h"
    days = seconds // 86400
    return f"{days} j"

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

        # --- Recent Activity (3 latest across reports/surveys/events) ---
        # Only expose recent activities to authenticated users to avoid
        # leaking report titles and addresses to anonymous visitors.
        if user.is_authenticated:
            report_activities = [
                {
                    'type': 'report',
                    'title': report.title or 'Nouveau signalement',
                    'subtitle': report.address or report.get_problem_type_display(),
                    'occurred_at': report.created_at,
                }
                for report in Report.objects.only(
                    'title',
                    'address',
                    'problem_type',
                    'created_at',
                ).order_by('-created_at')[:10]
            ]

            survey_activities = [
                {
                    'type': 'survey',
                    'title': survey.title,
                    'subtitle': 'Nouveau sondage',
                    'occurred_at': survey.created_at,
                }
                for survey in Survey.objects.only('title', 'created_at').order_by('-created_at')[:10]
            ]

            event_activities = [
                {
                    'type': 'event',
                    'title': event.title,
                    'subtitle': 'Agenda participatif',
                    'occurred_at': event.created_at,
                }
                for event in Event.objects.only('title', 'created_at').order_by('-created_at')[:10]
            ]

            merged_recent_activities = sorted(
                [*report_activities, *survey_activities, *event_activities],
                key=lambda item: item['occurred_at'],
                reverse=True,
            )[:3]

            recent_activities = [
                {
                    'type': item['type'],
                    'title': item['title'],
                    'subtitle': item['subtitle'],
                    'occurred_at': item['occurred_at'].isoformat(),
                    'elapsed_seconds': int((now - item['occurred_at']).total_seconds()),
                    'elapsed_label': _elapsed_label(now - item['occurred_at']),
                }
                for item in merged_recent_activities
            ]
        else:
            recent_activities = []


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
            # Recent activity
            'recent_activities': recent_activities,
        }
        
        return Response(data, status=status.HTTP_200_OK)
