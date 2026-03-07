from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from core.db.models import Neighborhood
from api.v1.serializers.neighborhood_serializer import NeighborhoodSerializer
from api.v1.permissions import IsAdminOrReadOnly
from drf_spectacular.utils import extend_schema, extend_schema_view


@extend_schema_view(
    list=extend_schema(
        summary="List all neighborhoods",
        description="Retrieve a list of all neighborhoods in the city",
        tags=["Neighborhoods"]
    ),
    retrieve=extend_schema(
        summary="Get neighborhood details",
        description="Retrieve details of a specific neighborhood",
        tags=["Neighborhoods"]
    ),
    create=extend_schema(
        summary="Create a neighborhood",
        description="Create a new neighborhood (admin only)",
        tags=["Neighborhoods"]
    ),
    update=extend_schema(
        summary="Update a neighborhood",
        description="Update neighborhood information (admin only)",
        tags=["Neighborhoods"]
    ),
    partial_update=extend_schema(
        summary="Partially update a neighborhood",
        description="Partially update neighborhood information (admin only)",
        tags=["Neighborhoods"]
    ),
    destroy=extend_schema(
        summary="Delete a neighborhood",
        description="Delete a neighborhood (admin only)",
        tags=["Neighborhoods"]
    ),
)
class NeighborhoodViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing neighborhoods.
    
    Read access for all authenticated users.
    Write access for admin only.
    Pagination is disabled because neighborhoods are reference data
    with a small, bounded count.
    """
    queryset = Neighborhood.objects.all().order_by('name')
    serializer_class = NeighborhoodSerializer
    pagination_class = None
    filterset_fields = '__all__'
    
    def get_permissions(self):
        """Allow read for authenticated, write for admin only"""
        if self.action in ['list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsAdminOrReadOnly]
        return [permission() for permission in permission_classes]
