from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from core.db.models import Report, User, Neighborhood, RoleEnum, ReportStatusEnum
from api.v1.serializers.report_serializer import ReportSerializer, ReportCreateSerializer
from api.v1.serializers.media_serializer import MediaSerializer as MediaUploadSerializer
from api.v1.filters import ReportFilter
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import OrderingFilter, SearchFilter


@extend_schema_view(
    list=extend_schema(
        summary="List all reports",
        description="Retrieve a list of citizen reports. All authenticated users can see all reports.",
        tags=["Reports"],
        parameters=[
            OpenApiParameter(name='status', description='Filter by status', required=False, type=str),
            OpenApiParameter(name='problem_type', description='Filter by problem type', required=False, type=str),
            OpenApiParameter(name='neighborhood', description='Filter by neighborhood ID', required=False, type=int),
            OpenApiParameter(name='search', description='Search in title, description, and reporter first/last name', required=False, type=str),
            OpenApiParameter(name='created_after', description='Filter reports created after this datetime (ISO 8601, e.g. 2025-01-01T00:00:00Z)', required=False, type=str),
            OpenApiParameter(name='created_before', description='Filter reports created before this datetime (ISO 8601, e.g. 2025-12-31T23:59:59Z)', required=False, type=str),
            OpenApiParameter(name='created_date', description='Filter reports created on this exact date (YYYY-MM-DD)', required=False, type=str),
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
        description="Update report information (owner or staff only)",
        tags=["Reports"]
    ),
    partial_update=extend_schema(
        summary="Partially update a report",
        description="Partially update report information (owner or staff only)",
        tags=["Reports"]
    ),
    destroy=extend_schema(
        summary="Delete a report",
        description="Delete a report (owner or staff only)",
        tags=["Reports"]
    ),
)
class ReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing citizen reports.
    
    All authenticated users can view all reports.
    Citizens can only modify/delete their own reports.
    Staff can modify/delete any report and update status.
    """
    queryset = Report.objects.select_related('user', 'neighborhood').prefetch_related('media').all()
    serializer_class = ReportSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = ReportFilter
    search_fields = ['title', 'description', 'user__first_name', 'user__last_name']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return ReportCreateSerializer
        return ReportSerializer
    
    def get_queryset(self):
        """All authenticated users can see all reports"""
        return self.queryset

    def perform_create(self, serializer):
        """Set the current user as the report creator"""
        serializer.save(user=self.request.user)
    
    def update(self, request, *args, **kwargs):
        """Only the owner or staff can update a report"""
        instance = self.get_object()
        if not self._is_owner_or_staff(request.user, instance):
            return Response(
                {'error': 'Only the report owner or staff can update this report'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        """Only the owner or staff can partially update a report"""
        instance = self.get_object()
        if not self._is_owner_or_staff(request.user, instance):
            return Response(
                {'error': 'Only the report owner or staff can update this report'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        """Only the owner or staff can delete a report"""
        instance = self.get_object()
        if not self._is_owner_or_staff(request.user, instance):
            return Response(
                {'error': 'Only the report owner or staff can delete this report'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().destroy(request, *args, **kwargs)

    def _is_owner_or_staff(self, user, report):
        """Check if user is the report owner or a staff member"""
        if user == report.user:
            return True
        if user.is_staff:
            return True
        if hasattr(user, 'role') and user.role in [RoleEnum.ELECTED, RoleEnum.AGENT, RoleEnum.GLOBAL_ADMIN]:
            return True
        return False

    @extend_schema(
        summary="Update report status",
        description="Update the status of a report (owner or staff only)",
        tags=["Reports"],
        request={"application/json": {"example": {"status": "IN_PROGRESS"}}}
    )
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def update_status(self, request, pk=None):
        """Update report status (owner or staff only)"""
        report = self.get_object()
        # Check if user is owner or staff
        if not self._is_owner_or_staff(request.user, report):
            return Response(
                {'error': 'Only the report owner or staff can update report status'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        new_status = request.data.get('status')
        
        if not new_status:
            return Response(
                {'error': 'Status is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if new_status not in ReportStatusEnum.values:
            return Response(
                {'error': f'Invalid status. Valid choices: {list(ReportStatusEnum.values)}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        report.status = new_status
        report.save()
        
        serializer = self.get_serializer(report)
        return Response(serializer.data)

    @extend_schema(
        summary="Upload media to report",
        description="Upload a file (image, video, etc.) to a report",
        tags=["Reports"],
        request={
            "multipart/form-data": {
                "type": "object",
                "properties": {
                    "file": {"type": "string", "format": "binary"}
                }
            }
        }
    )
    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def upload_media(self, request, pk=None):
        report = self.get_object()
        # Check permissions (owner or staff)
        if not self._is_owner_or_staff(request.user, report):
             return Response(
                {'error': 'Only the report owner or staff can upload media'},
                status=status.HTTP_403_FORBIDDEN
            )
            
        # We need to pass the report ID to the serializer, or save it manually
        # Since MediaUploadSerializer expects 'report' field, we can add it to data
        data = request.data.copy()
        data['report'] = report.id
        
        file_serializer = MediaUploadSerializer(data=data)
        if file_serializer.is_valid():
            file_serializer.save()
            return Response(file_serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(file_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
