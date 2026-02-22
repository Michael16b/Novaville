from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.db.models import Report, User, Neighborhood, RoleEnum
from api.v1.serializers.report_serializer import ReportSerializer, ReportCreateSerializer
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import OrderingFilter


@extend_schema_view(
    list=extend_schema(
        summary="List all reports",
        description="Retrieve a list of citizen reports. Citizens see only their own reports, staff see all.",
        tags=["Reports"],
        parameters=[
            OpenApiParameter(name='status', description='Filter by status', required=False, type=str),
            OpenApiParameter(name='problem_type', description='Filter by problem type', required=False, type=str),
            OpenApiParameter(name='neighborhood', description='Filter by neighborhood ID', required=False, type=int),
        ]
    ),
    retrieve=extend_schema(
        summary="Get report details",
        description="Retrieve details of a specific report",
        tags=["Reports"]
    ),
    create=extend_schema(
        summary="Create a report",
        description="Create a new citizen report",
        tags=["Reports"]
    ),
    update=extend_schema(
        summary="Update a report",
        description="Update report information (staff only)",
        tags=["Reports"]
    ),
    partial_update=extend_schema(
        summary="Partially update a report",
        description="Partially update report information (staff only for status changes)",
        tags=["Reports"]
    ),
    destroy=extend_schema(
        summary="Delete a report",
        description="Delete a report (admin only)",
        tags=["Reports"]
    ),
)
class ReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing citizen reports.
    
    Citizens can create and view their own reports.
    Staff can view all reports and update status.
    """
    queryset = Report.objects.select_related('user', 'neighborhood').all()
    serializer_class = ReportSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['status', 'problem_type', 'neighborhood']
    ordering_fields = ['created_at', 'status']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return ReportCreateSerializer
        return ReportSerializer
    
    def get_queryset(self):
        """Filter queryset based on user role"""
        user = self.request.user
        if user.is_staff or user.role in [RoleEnum.ELECTED, RoleEnum.AGENT, RoleEnum.GLOBAL_ADMIN]:
            # Staff can see all reports
            return self.queryset
        # Citizens only see their own reports
        return self.queryset.filter(user=user)
    
    def perform_create(self, serializer):
        """Set the current user as the report creator"""
        serializer.save(user=self.request.user)
    
    @extend_schema(
        summary="Update report status",
        description="Update the status of a report (staff only)",
        tags=["Reports"],
        request={"application/json": {"example": {"status": "IN_PROGRESS"}}}
    )
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """Update report status (staff only)"""
        report = self.get_object()
        new_status = request.data.get('status')
        
        if not new_status:
            return Response(
                {'error': 'Status is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        report.status = new_status
        report.save()
        
        serializer = self.get_serializer(report)
        return Response(serializer.data)
