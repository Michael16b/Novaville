from rest_framework import serializers
from core.db.models import Media


class MediaSerializer(serializers.ModelSerializer):
    """Serializer for Media model"""
    
    class Meta:
        model = Media
        fields = ['id', 'file', 'created_at', 'report']
        read_only_fields = ['id', 'created_at']
