from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import IntegrityError
from core.db.models import Vote
from api.v1.serializers.vote_serializer import VoteSerializer, VoteCreateSerializer
from drf_spectacular.utils import extend_schema, extend_schema_view


@extend_schema_view(
    list=extend_schema(
        summary="List user's votes",
        description="Retrieve a list of votes from the current user",
        tags=["Votes"]
    ),
    retrieve=extend_schema(
        summary="Get vote details",
        description="Retrieve details of a specific vote",
        tags=["Votes"]
    ),
    create=extend_schema(
        summary="Cast a vote",
        description="Cast a vote on a survey",
        tags=["Votes"]
    ),
    destroy=extend_schema(
        summary="Delete a vote",
        description="Delete a vote (allows users to change their vote)",
        tags=["Votes"]
    ),
)
class VoteViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing votes.
    
    Users can only vote once per survey.
    Users can view and delete their own votes.
    """
    queryset = Vote.objects.select_related('user', 'survey', 'option').all()
    serializer_class = VoteSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = '__all__'
    http_method_names = ['get', 'post', 'delete']  # No PUT/PATCH
    
    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return VoteCreateSerializer
        return VoteSerializer
    
    def get_queryset(self):
        """Users can only see their own votes"""
        return self.queryset.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        """Set the current user as the voter"""
        serializer.save(user=self.request.user)
    
    def create(self, request, *args, **kwargs):
        """Create a vote with duplicate check"""
        try:
            return super().create(request, *args, **kwargs)
        except IntegrityError:
            return Response(
                {'error': 'You have already voted on this survey'},
                status=status.HTTP_400_BAD_REQUEST
            )
