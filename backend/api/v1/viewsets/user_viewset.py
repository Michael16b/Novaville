from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from core.db.models import User
from api.v1.serializers.user_serializer import UserSerializer, UserPublicSerializer
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter


@extend_schema_view(
    list=extend_schema(
        summary="List all users",
        description="Retrieve a list of all users (admin only)",
        tags=["Users"]
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
    
    list: Admin only
    retrieve: Authenticated users can view their own profile, admins can view all
    create: Anyone can register (returns minimal info)
    update/destroy: Admin only
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    
    def get_permissions(self):
        """Set permissions based on action"""
        if self.action == 'create':
            # Anyone can register
            permission_classes = [AllowAny]
        elif self.action in ['retrieve']:
            # Authenticated users can view their own profile
            permission_classes = [IsAuthenticated]
        else:
            # List, update, delete: admin only
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        """Filter queryset based on user role"""
        user = self.request.user
        if user.is_staff or user.is_superuser:
            return User.objects.all()
        elif user.is_authenticated:
            # Regular users can only see their own profile
            return User.objects.filter(id=user.id)
        return User.objects.none()
    
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
