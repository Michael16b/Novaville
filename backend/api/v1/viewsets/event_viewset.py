from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.db.models import Event, ThemeEvent, RoleEnum
from api.v1.serializers.event_serializer import (
    EventSerializer,
    EventCreateSerializer,
    ThemeEventSerializer
)
from api.v1.permissions import IsStaffOrReadOnly, IsAdminOrReadOnly
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import OrderingFilter
from django.utils import timezone


@extend_schema_view(
    list=extend_schema(
        summary="List all events",
        description="Retrieve a list of all city and association events",
        tags=["Events"],
        parameters=[
            OpenApiParameter(name='theme', description='Filter by theme ID', required=False, type=int),
            OpenApiParameter(name='start_date__gte', description='Filter events starting after this date', required=False, type=str),
        ]
    ),
    retrieve=extend_schema(
        summary="Get event details",
        description="Retrieve details of a specific event",
        tags=["Events"]
    ),
    create=extend_schema(
        summary="Create an event",
        description="Create a new event (authenticated users)",
        tags=["Events"]
    ),
    update=extend_schema(
        summary="Update an event",
        description="Update event information (creator or staff only)",
        tags=["Events"]
    ),
    partial_update=extend_schema(
        summary="Partially update an event",
        description="Partially update event information (creator or staff only)",
        tags=["Events"]
    ),
    destroy=extend_schema(
        summary="Delete an event",
        description="Delete an event (creator or staff only)",
        tags=["Events"]
    ),
)
class EventViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing events.
    
    All authenticated users can view events.
    Only staff can create events.
    Only creator or staff can update/delete events.
    """
    queryset = Event.objects.select_related('created_by', 'theme').all()
    serializer_class = EventSerializer
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['theme']
    ordering_fields = ['start_date', 'end_date']
    ordering = ['start_date']
    
    def get_permissions(self):
        """Allow read for authenticated, write for staff only"""
        if self.action in ['list', 'retrieve', 'upcoming']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsStaffOrReadOnly]
        return [permission() for permission in permission_classes]
    
    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return EventCreateSerializer
        return EventSerializer
    
    def perform_create(self, serializer):
        """Set the current user as the event creator"""
        serializer.save(created_by=self.request.user)
    
    @extend_schema(
        summary="Get upcoming events",
        description="Retrieve only upcoming events",
        tags=["Events"]
    )
    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """Get upcoming events"""
        now = timezone.now()
        upcoming_events = self.queryset.filter(start_date__gte=now)
        serializer = self.get_serializer(upcoming_events, many=True)
        return Response(serializer.data)


@extend_schema_view(
    list=extend_schema(
        summary="List all event themes",
        description="Retrieve a list of all event themes/categories",
        tags=["Events"]
    ),
    retrieve=extend_schema(
        summary="Get theme details",
        description="Retrieve details of a specific event theme",
        tags=["Events"]
    ),
    create=extend_schema(
        summary="Create an event theme",
        description="Create a new event theme (staff only)",
        tags=["Events"]
    ),
    update=extend_schema(
        summary="Update an event theme",
        description="Update event theme (staff only)",
        tags=["Events"]
    ),
    destroy=extend_schema(
        summary="Delete an event theme",
        description="Delete an event theme (staff only)",
        tags=["Events"]
    ),
)
class ThemeEventViewSet(viewsets.ModelViewSet):
    """ViewSet for managing event themes"""
    queryset = ThemeEvent.objects.all()
    serializer_class = ThemeEventSerializer
    
    def get_permissions(self):
        """Allow read for authenticated, write for admin only"""
        if self.action in ['list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsAdminOrReadOnly]
        return [permission() for permission in permission_classes]
