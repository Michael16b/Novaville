from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.db.models import Survey, SurveyOption, RoleEnum
from api.v1.survey_access import visible_survey_filter
from api.v1.serializers.survey_serializer import (
    SurveySerializer,
    SurveyCreateSerializer,
    SurveyOptionSerializer
)
from api.v1.permissions import IsSurveyManagerOrReadOnly
from drf_spectacular.utils import extend_schema, extend_schema_view
from django.utils import timezone


@extend_schema_view(
    list=extend_schema(
        summary="List all surveys",
        description="Retrieve a list of all surveys and public consultations",
        tags=["Surveys"]
    ),
    retrieve=extend_schema(
        summary="Get survey details",
        description="Retrieve details of a specific survey including options and vote counts",
        tags=["Surveys"]
    ),
    create=extend_schema(
        summary="Create a survey",
        description="Create a new survey with options (staff only)",
        tags=["Surveys"]
    ),
    update=extend_schema(
        summary="Update a survey",
        description="Update survey information (staff only)",
        tags=["Surveys"]
    ),
    partial_update=extend_schema(
        summary="Partially update a survey",
        description="Partially update survey information (staff only)",
        tags=["Surveys"]
    ),
    destroy=extend_schema(
        summary="Delete a survey",
        description="Delete a survey (admin only)",
        tags=["Surveys"]
    ),
)
class SurveyViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing surveys and public consultations.
    
    All authenticated users can view surveys.
    Only elected users and global admins can create/update/delete surveys.
    """
    queryset = Survey.objects.prefetch_related('options', 'votes').all()
    serializer_class = SurveySerializer
    permission_classes = [IsSurveyManagerOrReadOnly]
    filterset_fields = '__all__'
    search_fields = ['title', 'description', 'address']
    ordering_fields = ['created_at', 'start_date', 'end_date', 'title']

    def get_queryset(self):
        """Limit surveys to the current user's audience, except for global admins."""
        queryset = self.queryset
        user = self.request.user

        if user.role in [RoleEnum.GLOBAL_ADMIN, RoleEnum.ELECTED]:
            return queryset

        return queryset.filter(visible_survey_filter(user))

    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return SurveyCreateSerializer
        return SurveySerializer
    
    def perform_create(self, serializer):
        """Set the current user as the survey creator"""
        serializer.save(created_by=self.request.user)
    
    @extend_schema(
        summary="Get active surveys",
        description="Retrieve only currently active surveys",
        tags=["Surveys"]
    )
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get only active surveys"""
        now = timezone.now()
        active_surveys = self.get_queryset().filter(
            start_date__lte=now,
            end_date__gte=now
        )
        serializer = self.get_serializer(active_surveys, many=True)
        return Response(serializer.data)
    
    @extend_schema(
        summary="Get survey results",
        description="Get aggregated results for a survey",
        tags=["Surveys"]
    )
    @action(detail=True, methods=['get'])
    def results(self, request, pk=None):
        """Get survey results with vote counts"""
        survey = self.get_object()
        serializer = self.get_serializer(survey)
        return Response(serializer.data)


@extend_schema_view(
    list=extend_schema(
        summary="List survey options",
        description="Retrieve all options for surveys",
        tags=["Surveys"]
    ),
    retrieve=extend_schema(
        summary="Get survey option details",
        description="Retrieve details of a specific survey option",
        tags=["Surveys"]
    ),
    create=extend_schema(
        summary="Add a survey option",
        description="Add a new option to a survey (staff only)",
        tags=["Surveys"]
    ),
    update=extend_schema(
        summary="Update a survey option",
        description="Update a survey option (staff only)",
        tags=["Surveys"]
    ),
    destroy=extend_schema(
        summary="Delete a survey option",
        description="Delete a survey option (staff only)",
        tags=["Surveys"]
    ),
)
class SurveyOptionViewSet(viewsets.ModelViewSet):
    """ViewSet for managing survey options"""
    queryset = SurveyOption.objects.all()
    serializer_class = SurveyOptionSerializer
    filterset_fields = '__all__'

    def get_queryset(self):
        """Limit options to surveys visible to the current user."""
        queryset = self.queryset
        user = self.request.user

        if user.role in [RoleEnum.GLOBAL_ADMIN, RoleEnum.ELECTED]:
            return queryset

        return queryset.filter(visible_survey_filter(user, 'survey__citizen_target'))
    
    def get_permissions(self):
        """Allow read for authenticated, write for staff only"""
        if self.action in ['list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsSurveyManagerOrReadOnly]
        return [permission() for permission in permission_classes]
