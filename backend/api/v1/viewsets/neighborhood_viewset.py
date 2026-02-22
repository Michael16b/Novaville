from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from core.db.models import Neighborhood
from api.v1.serializers.neighborhood_serializer import NeighborhoodSerializer
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
    Write access for staff only.
    """
    queryset = Neighborhood.objects.all()
    serializer_class = NeighborhoodSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
