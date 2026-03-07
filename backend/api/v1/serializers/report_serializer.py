from rest_framework import serializers
from core.db.models import Report
from api.v1.serializers.user_serializer import UserPublicSerializer
from api.v1.serializers.neighborhood_serializer import NeighborhoodSerializer


class _TitleValidationMixin:
    """Mixin that rejects blank or missing report titles."""

    def validate_title(self, value):
        """Reject blank titles."""
        if not value or not value.strip():
            raise serializers.ValidationError("Title is required and cannot be blank.")
        return value


class ReportSerializer(_TitleValidationMixin, serializers.ModelSerializer):
    """Serializer for Report model"""
    user = UserPublicSerializer(read_only=True)
    neighborhood_detail = NeighborhoodSerializer(source='neighborhood', read_only=True)
    
    class Meta:
        model = Report
        fields = [
            'id', 'title', 'problem_type', 'description', 'created_at',
            'status', 'user', 'neighborhood', 'neighborhood_detail'
        ]
        read_only_fields = ['id', 'created_at', 'user']


class ReportCreateSerializer(_TitleValidationMixin, serializers.ModelSerializer):
    """Serializer for creating a report"""
    
    class Meta:
        model = Report
        fields = ['id', 'title', 'problem_type', 'description', 'neighborhood']
        read_only_fields = ['id']
