from rest_framework import serializers
from core.db.models import Neighborhood


class NeighborhoodSerializer(serializers.ModelSerializer):
    """Serializer for Neighborhood model"""
    
    class Meta:
        model = Neighborhood
        fields = ['id', 'name', 'postal_code']
        read_only_fields = ['id']
