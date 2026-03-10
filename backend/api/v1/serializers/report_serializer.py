from rest_framework import serializers
from core.db.models import Report, Media
from api.v1.serializers.user_serializer import UserPublicSerializer
from api.v1.serializers.neighborhood_serializer import NeighborhoodSerializer


class MediaSerializer(serializers.ModelSerializer):
    """Serializer for Media model"""
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Media
        fields = ['id', 'file', 'file_url', 'created_at']
        read_only_fields = ['id', 'created_at']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file and hasattr(obj.file, 'url'):
            return request.build_absolute_uri(obj.file.url)
        return None


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
    media = MediaSerializer(many=True, read_only=True)

    class Meta:
        model = Report
        fields = [
            'id', 'title', 'problem_type', 'description', 'created_at',
            'status', 'user', 'neighborhood', 'neighborhood_detail',
            'latitude', 'longitude', 'address', 'media'
        ]
        read_only_fields = ['id', 'created_at', 'user']


class ReportCreateSerializer(_TitleValidationMixin, serializers.ModelSerializer):
    """Serializer for creating a report"""
    
    class Meta:
        model = Report
        fields = [
            'id', 'title', 'problem_type', 'description', 'neighborhood',
            'latitude', 'longitude', 'address'
        ]
        read_only_fields = ['id']
