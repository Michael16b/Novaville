from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.v1.serializers.news_photo_serializer import NewsPhotoSerializer
from core.db.models import NewsPhoto, RoleEnum


@extend_schema_view(
    list=extend_schema(
        summary="List news photos",
        description="Retrieve photos displayed on the news page.",
        tags=["News"],
    ),
    create=extend_schema(
        summary="Create a news photo",
        description="Create a new photo for the news page (admin or elected only).",
        tags=["News"],
    ),
    destroy=extend_schema(
        summary="Delete a news photo",
        description="Delete a photo from the news page (admin or elected only).",
        tags=["News"],
    ),
)
class NewsPhotoViewSet(viewsets.ModelViewSet):
    """ViewSet for managing photos displayed on the news page."""

    queryset = NewsPhoto.objects.select_related("created_by").all()
    serializer_class = NewsPhotoSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ["get", "post", "delete", "head", "options"]

    def _can_manage_photos(self, user):
        return getattr(user, "role", None) in [RoleEnum.ELECTED, RoleEnum.GLOBAL_ADMIN]

    def create(self, request, *args, **kwargs):
        if not self._can_manage_photos(request.user):
            return Response(
                {"error": "Only elected officials and admins can add photos."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().create(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if not self._can_manage_photos(request.user):
            return Response(
                {"error": "Only elected officials and admins can delete photos."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
