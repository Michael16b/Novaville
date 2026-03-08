from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from core.db.models import User
from api.v1.serializers.user_serializer import UserSerializer, UserPublicSerializer
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter


@extend_schema_view(
    list=extend_schema(
        summary="List all users",
        description="Retrieve a list of users with optional filters, search, and ordering (admin can see all, regular users see public directory)",
        tags=["Users"],
        parameters=[
            OpenApiParameter(name='role', description='Filter by role (e.g. CITIZEN, ELECTED, AGENT, GLOBAL_ADMIN)', required=False, type=str),
            OpenApiParameter(name='neighborhood', description='Filter by neighborhood ID', required=False, type=int),
            OpenApiParameter(name='search', description='Search in username, first_name, last_name, email', required=False, type=str),
            OpenApiParameter(name='ordering', description='Order by first_name, username, email, role, date_joined', required=False, type=str),
        ]
    ),
    retrieve=extend_schema(
        summary="Get user details",
        description="Retrieve details of a specific user",
        tags=["Users"]
    ),
    create=extend_schema(
        summary="Create a new user",
        description="Create a new user account",
        tags=["Users"]
    ),
    update=extend_schema(
        summary="Update a user",
        description="Update user information (admin only)",
        tags=["Users"]
    ),
    partial_update=extend_schema(
        summary="Partially update a user",
        description="Partially update user information (admin only)",
        tags=["Users"]
    ),
    destroy=extend_schema(
        summary="Delete a user",
        description="Delete a user account (admin only)",
        tags=["Users"]
    ),
)
class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing users.
    
    list: Authenticated users (public directory)
    retrieve: Authenticated users can view their own profile, admins can view all
    create: Anyone can register (returns minimal info)
    update/destroy: Admin only
    """
    queryset = User.objects.select_related('neighborhood').all()
    serializer_class = UserSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = '__all__'
    search_fields = ['username', 'first_name', 'last_name', 'email']
    ordering_fields = ['first_name', 'username', 'email', 'role', 'date_joined']
    ordering = ['-date_joined']
    
    def get_permissions(self):
        """Set permissions based on action"""
        if self.action == 'create':
            # Anyone can register
            permission_classes = [AllowAny]
        elif self.action in ['list', 'retrieve', 'me']:
            # Authenticated users can view users
            permission_classes = [IsAuthenticated]
        elif self.action in ['update', 'partial_update']:
            # Users can update their own profile, admins can update anyone
            permission_classes = [IsAuthenticated]
        else:
            # Delete: admin only
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        """Filter queryset based on user role"""
        user = self.request.user
        if user.is_staff or user.is_superuser:
            return User.objects.all()
        elif user.is_authenticated:
            # Regular users can see all users (public directory)
            return User.objects.all()
        return User.objects.none()
    
    def update(self, request, *args, **kwargs):
        """Allow users to update their own profile, admins can update anyone"""
        instance = self.get_object()
        if not request.user.is_staff and instance != request.user:
            return Response(
                {'error': 'You can only update your own profile'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().update(request, *args, **kwargs)
    
    def partial_update(self, request, *args, **kwargs):
        """Allow users to update their own profile, admins can update anyone"""
        instance = self.get_object()
        if not request.user.is_staff and instance != request.user:
            return Response(
                {'error': 'You can only update your own profile'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().partial_update(request, *args, **kwargs)
    
    @extend_schema(
        summary="Get current user profile",
        description="Retrieve the profile of the currently authenticated user",
        tags=["Users"]
    )
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def me(self, request):
        """Get current user's profile"""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)
