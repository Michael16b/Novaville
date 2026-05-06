import string
import secrets
import urllib.parse
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from core.db.models import User
from api.v1.filters import UserFilter
from api.v1.serializers.user_serializer import UserSerializer, UserPublicSerializer
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter
from rest_framework import serializers
from core.db.models.user import ApprovalStatus


@extend_schema_view(
    list=extend_schema(
        summary="List all users",
        description="Retrieve a list of users with optional filters, search, and ordering (admin can see all, regular users see public directory)",
        tags=["Users"],
        parameters=[
            OpenApiParameter(name='role', description='Filter by role (e.g. CITIZEN, ELECTED, AGENT, GLOBAL_ADMIN)', required=False, type=str),
            OpenApiParameter(name='approval_status', description='Filter by approval status (e.g. PENDING, APPROVED)', required=False, type=str),
            OpenApiParameter(name='address', description='Filter by address (partial match)', required=False, type=str),
            OpenApiParameter(name='neighborhood', description='Filter by neighborhood ID', required=False, type=int),
            OpenApiParameter(name='search', description='Search in username, first_name, last_name, email, address', required=False, type=str),
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
    filterset_class = UserFilter
    search_fields = ['username', 'first_name', 'last_name', 'email', 'address']
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
        elif self.action == 'reset_password':
            # Only admins can reset passwords
            permission_classes = [IsAdminUser]
        else:
            # Delete: admin only
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        """Filter queryset based on user role"""
        user = self.request.user
        query_params = getattr(self.request, 'query_params', self.request.GET)
        requested_status = query_params.get('approval_status')
        current_action = getattr(self, 'action', None)
        if user.is_staff or user.is_superuser:
            if current_action in ['approve', 'reject', 'pending'] or requested_status:
                return User.objects.select_related('neighborhood').all()
            return User.objects.select_related('neighborhood').filter(
                approval_status=ApprovalStatus.APPROVED,
                is_active=True,
            )
        elif user.is_authenticated:
            return User.objects.select_related('neighborhood').filter(
                approval_status=ApprovalStatus.APPROVED,
                is_active=True,
            )
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

    @action(detail=False, methods=['get'], permission_classes=[IsAdminUser])
    def pending(self, request):
        queryset = User.objects.select_related('neighborhood').filter(
            approval_status=ApprovalStatus.PENDING,
            is_active=False,
        ).order_by('-date_joined')
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def approve(self, request, pk=None):
        user = self.get_object()
        user.approval_status = ApprovalStatus.APPROVED
        user.is_active = True
        user.save(update_fields=['approval_status', 'is_active'])
        serializer = self.get_serializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def reject(self, request, pk=None):
        user = self.get_object()
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'], url_path='change_password', permission_classes=[IsAuthenticated])
    def change_password(self, request, pk=None):
        """Allow a user to change their password"""

        user = self.get_object()

        if user != request.user and not request.user.is_staff:
            return Response(
                {"code": "forbidden"},
                status=status.HTTP_403_FORBIDDEN
            )

        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')

        if not current_password or not new_password:
            return Response(
                {"code": "password_fields_required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not user.check_password(current_password):
            return Response(
                {"code": "incorrect_password"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            validate_password(new_password, user)
        except serializers.ValidationError:
            return Response(
                {"code": "password_invalid"},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(new_password)
        user.save()

        return Response(
            {"detail": "password_updated"},
            status=status.HTTP_200_OK
        )

    @extend_schema(
        summary="Reset user password",
        description="Reset a user's password automatically and send an email (admin only)",
        tags=["Users"],
        request=None,
        responses={200: None}
    )
    @action(detail=True, methods=['post'], url_path='reset_password', permission_classes=[IsAdminUser])
    def reset_password(self, request, pk=None):
        """Allow an admin to reset a user's password and send a magic link"""
        user = self.get_object()

        if not user.email:
            return Response(
                {"code": "email_required", "detail": "L'utilisateur n'a pas d'adresse e-mail."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 1. Génération du code d'activation (mot de passe temporaire)
        alphabet = string.ascii_letters + string.digits
        temp_password = ''.join(secrets.choice(alphabet) for i in range(8))

        user.set_password(temp_password)
        user.save()

        # 2. Création du lien magique
        frontend_url = getattr(settings, 'FRONTEND_URL', 'http://localhost:8080')
        query_params = urllib.parse.urlencode({
            'username': user.username,
            'temp_password': temp_password
        })
        magic_link = f"{frontend_url}/#/set-password?{query_params}"

        # 3. Envoi du mail
        try:
            send_mail(
                subject="Novaville - Réinitialisation de votre mot de passe",
                message=(
                    f"Bonjour {user.first_name or user.username},\n\n"
                    f"Votre mot de passe a été réinitialisé par un administrateur.\n\n"
                    f"Code d'activation (mot de passe temporaire) : {temp_password}\n\n"
                    f"Veuillez cliquer sur le lien ci-dessous pour configurer votre nouveau mot de passe :\n"
                    f"{magic_link}\n\n"
                    f"⚠️ Note : Ce message ayant été généré automatiquement, pensez à vérifier votre dossier Spam ou Courriers Indésirables si vous attendez d'autres e-mails de notre part.\n\n"
                    f"Si vous n'êtes pas à l'origine de cette action, veuillez nous contacter."
                ),
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@novaville.fr'),
                recipient_list=[user.email],
                fail_silently=False,
            )
            return Response({"detail": "password_reset_success"}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {"code": "email_failed", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @extend_schema(
        summary="Set initial password (first login)",
        description="Allows a newly created user to set their initial password without knowing the old one",
        tags=["Users"],
        request=serializers.Serializer,
        responses={200: None}
    )
    @action(detail=True, methods=['post'], url_path='set_initial_password', permission_classes=[IsAuthenticated])
    def set_initial_password(self, request, pk=None):
        """Allow a user to set their password on first login"""
        user = self.get_object()

        # Only allow users to set their own initial password
        if user != request.user:
            return Response(
                {"code": "forbidden"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Only allow if first login not yet completed
        if user.first_login_completed:
            return Response(
                {"code": "already_initialized"},
                status=status.HTTP_400_BAD_REQUEST
            )

        new_password = request.data.get('password')

        if not new_password:
            return Response(
                {"code": "password_required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            validate_password(new_password, user)
        except serializers.ValidationError as e:
            return Response(
                {"code": "password_invalid", "details": e.messages},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(new_password)
        user.first_login_completed = True
        user.save(update_fields=['password', 'first_login_completed'])

        return Response(
            {"detail": "initial_password_set_success"},
            status=status.HTTP_200_OK
        )
