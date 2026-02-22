from rest_framework import serializers
from core.db.models import Event, ThemeEvent
from api.v1.serializers.user_serializer import UserPublicSerializer


class ThemeEventSerializer(serializers.ModelSerializer):
    """Serializer for ThemeEvent model"""
    
    class Meta:
        model = ThemeEvent
        fields = ['id', 'title']
        read_only_fields = ['id']


class EventSerializer(serializers.ModelSerializer):
    """Serializer for Event model"""
    created_by = UserPublicSerializer(read_only=True)
    theme_detail = ThemeEventSerializer(source='theme', read_only=True)
    
    class Meta:
        model = Event
        fields = [
            'id', 'title', 'description', 'start_date', 'end_date',
            'created_by', 'theme', 'theme_detail'
        ]
        read_only_fields = ['id', 'created_by']


class EventCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating an event"""
    
    class Meta:
        model = Event
        fields = ['title', 'description', 'start_date', 'end_date', 'theme']
