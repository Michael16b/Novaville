from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
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
        """Create or replace the current user's vote for a survey atomically."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        survey = serializer.validated_data['survey']
        option = serializer.validated_data['option']

        with transaction.atomic():
            vote, created = Vote.objects.update_or_create(
                user=request.user,
                survey=survey,
                defaults={'option': option},
            )

        response_serializer = VoteSerializer(vote)
        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        headers = self.get_success_headers(response_serializer.data) if created else {}
        return Response(response_serializer.data, status=response_status, headers=headers)
