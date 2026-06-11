from django.db import transaction
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.serializers import ValidationError
from core.db.models import (
    Report,
    ReportPhoto,
    User,
    Neighborhood,
    RoleEnum,
    ReportStatusEnum,
)
from api.v1.serializers.report_serializer import ReportSerializer, ReportCreateSerializer
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
            OpenApiParameter(name='address', description='Filter by address (partial match)', required=False, type=str),
            OpenApiParameter(name='neighborhood', description='Filter by neighborhood ID', required=False, type=int),
            OpenApiParameter(name='search', description='Search in title, description, address, and reporter first/last name', required=False, type=str),
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
    queryset = Report.objects.select_related('user', 'neighborhood').prefetch_related('photos').all()
    serializer_class = ReportSerializer
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = ReportFilter
    search_fields = ['title', 'description', 'address', 'user__first_name', 'user__last_name']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def get_permissions(self):
        """Allow public read access and authenticated writes only."""
        if self.action in ['list', 'retrieve', 'photo_image']:
            permission_classes = [AllowAny]
        else:
            permission_classes = [IsAuthenticated]
        return [permission() for permission in permission_classes]

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

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        """Create a report and attach any uploaded photos."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        report = serializer.save(user=request.user)

        self._attach_uploaded_photos(report, request.FILES.getlist("photos"))
        report = self._get_report_with_fresh_photos(report.id)

        output_serializer = ReportSerializer(
            report,
            context=self.get_serializer_context(),
        )
        return Response(output_serializer.data, status=status.HTTP_201_CREATED)
    
    def update(self, request, *args, **kwargs):
        """Only the owner or staff can update a report"""
        instance = self.get_object()
        if not self._is_owner_or_staff(request.user, instance):
            return Response(
                {'error': 'Only the report owner or staff can update this report'},
                status=status.HTTP_403_FORBIDDEN
            )
        return self._update_report_with_photos(request, instance, partial=False)

    def partial_update(self, request, *args, **kwargs):
        """Only the owner or staff can partially update a report"""
        instance = self.get_object()
        if not self._is_owner_or_staff(request.user, instance):
            return Response(
                {'error': 'Only the report owner or staff can update this report'},
                status=status.HTTP_403_FORBIDDEN
            )
        return self._update_report_with_photos(request, instance, partial=True)

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

    @transaction.atomic
    def _update_report_with_photos(self, request, instance, partial):
        """Update report fields, delete selected photos, and attach new photos."""
        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=partial,
        )
        serializer.is_valid(raise_exception=True)
        report = serializer.save()

        deleted_photo_ids = self._get_deleted_photo_ids(request)
        if deleted_photo_ids:
            report.photos.filter(id__in=deleted_photo_ids).delete()

        self._attach_uploaded_photos(report, request.FILES.getlist("photos"))
        report = self._get_report_with_fresh_photos(report.id)

        output_serializer = ReportSerializer(
            report,
            context=self.get_serializer_context(),
        )
        return Response(output_serializer.data)

    def _get_report_with_fresh_photos(self, report_id):
        """Reload a report so serialized photos reflect recent changes."""
        return Report.objects.select_related(
            'user',
            'neighborhood',
        ).prefetch_related('photos').get(id=report_id)

    def _attach_uploaded_photos(self, report, photos):
        """Validate and persist uploaded photos in the database."""
        for photo in photos:
            self._validate_photo_upload(photo)
            ReportPhoto.objects.create(
                report=report,
                filename=getattr(photo, "name", ""),
                content_type=getattr(photo, "content_type", "")
                or "application/octet-stream",
                image_data=photo.read(),
            )

    def _get_deleted_photo_ids(self, request):
        """Read photo IDs to delete from JSON or multipart requests."""
        values = []
        if hasattr(request.data, "getlist"):
            values = request.data.getlist("deleted_photo_ids")
        elif "deleted_photo_ids" in request.data:
            raw_value = request.data.get("deleted_photo_ids")
            values = raw_value if isinstance(raw_value, list) else [raw_value]

        photo_ids = []
        for value in values:
            if value in (None, ""):
                continue
            for item in str(value).split(","):
                item = item.strip()
                if item:
                    try:
                        photo_ids.append(int(item))
                    except ValueError as exc:
                        raise ValidationError(
                            {"deleted_photo_ids": "Photo IDs must be integers."}
                        ) from exc
        return photo_ids

    def _validate_photo_upload(self, photo):
        """Validate an uploaded report photo before saving it."""
        allowed_extensions = (".heic", ".heif", ".jpg", ".jpeg", ".png", ".webp")
        content_type = (getattr(photo, "content_type", "") or "").lower()
        filename = getattr(photo, "name", "").lower()

        has_image_extension = filename.endswith(allowed_extensions)
        has_image_content_type = content_type.startswith("image/")
        if not (has_image_extension or has_image_content_type):
            raise ValidationError(
                {"photos": "Only JPG, PNG, WEBP, HEIC, and HEIF photos are allowed."}
            )

    @extend_schema(
        summary="Get report photo image",
        description="Retrieve the binary image file attached to a report.",
        tags=["Reports"],
    )
    @action(
        detail=False,
        methods=["get"],
        url_path=r"photos/(?P<photo_id>[^/.]+)/image",
        permission_classes=[AllowAny],
    )
    def photo_image(self, request, photo_id=None):
        """Serve a report photo through the API proxy."""
        photo = get_object_or_404(ReportPhoto, pk=photo_id)
        response = HttpResponse(
            bytes(photo.image_data),
            content_type=photo.content_type or "application/octet-stream",
        )
        if photo.filename:
            response["Content-Disposition"] = f'inline; filename="{photo.filename}"'
        return response

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
