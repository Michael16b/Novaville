from rest_framework import serializers
from core.db.models import Event, ThemeEvent
from api.v1.serializers.user_serializer import UserPublicSerializer


CANONICAL_EVENT_THEMES = {
    "SPORT": "Sport",
    "CULTURE": "Culture",
    "CITIZENSHIP": "Citoyenneté",
    "ENVIRONMENT": "Environnement",
    "OTHER": "Autre",
}

EVENT_THEME_ALIASES = {
    "sport": "SPORT",
    "culture": "CULTURE",
    "citizenship": "CITIZENSHIP",
    "citoyennete": "CITIZENSHIP",
    "citoyenneté": "CITIZENSHIP",
    "environment": "ENVIRONMENT",
    "environnement": "ENVIRONMENT",
    "other": "OTHER",
    "autre": "OTHER",
}


def ensure_canonical_event_themes():
    """Create expected event themes when a database was not seeded."""
    for title in CANONICAL_EVENT_THEMES.values():
        ThemeEvent.objects.get_or_create(title=title)


def _normalize_theme_key(value):
    return str(value).strip().lower()


def get_or_create_event_theme(value):
    """Resolve a stable theme key or label to a ThemeEvent instance."""
    normalized = _normalize_theme_key(value)
    key = EVENT_THEME_ALIASES.get(normalized)
    if key is None:
        key = normalized.upper()
    title = CANONICAL_EVENT_THEMES.get(key)
    if title is None:
        raise serializers.ValidationError("Unknown event theme.")
    theme, _ = ThemeEvent.objects.get_or_create(title=title)
    return theme


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
    theme_key = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
    )
    
    class Meta:
        model = Event
        fields = [
            'id', 'title', 'description', 'start_date', 'end_date',
            'created_by', 'theme', 'theme_detail', 'theme_key'
        ]
        read_only_fields = ['id', 'created_by']

    def validate(self, attrs):
        theme_key = attrs.pop('theme_key', None)
        if theme_key:
            attrs['theme'] = get_or_create_event_theme(theme_key)
        return super().validate(attrs)


class EventCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating an event"""
    theme_detail = ThemeEventSerializer(source='theme', read_only=True)
    theme_key = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
    )
    
    class Meta:
        model = Event
        fields = [
            'id', 'title', 'description', 'start_date', 'end_date',
            'theme', 'theme_detail', 'theme_key'
        ]
        read_only_fields = ['id']

    def validate(self, attrs):
        theme_key = attrs.pop('theme_key', None)
        if theme_key:
            attrs['theme'] = get_or_create_event_theme(theme_key)
        return super().validate(attrs)
