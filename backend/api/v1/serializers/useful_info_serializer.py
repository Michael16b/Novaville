from rest_framework import serializers
from core.db.models import UsefulInfo


class OpeningHoursField(serializers.JSONField):
    """Custom field for opening_hours validation."""

    def to_representation(self, value):
        # Ensure we always return a properly formatted dict
        if not isinstance(value, dict):
            return {}
        return value

    def to_internal_value(self, data):
        # Validate format during deserialization
        if not isinstance(data, dict):
            raise serializers.ValidationError(
                "opening_hours must be a dictionary"
            )
        
        for day, hours in data.items():
            if not isinstance(day, str):
                raise serializers.ValidationError(
                    f"Day key must be a string, got {type(day).__name__}"
                )
            if not isinstance(hours, list):
                raise serializers.ValidationError(
                    f"Hours for '{day}' must be a list of strings"
                )
            for hour_range in hours:
                if not isinstance(hour_range, str):
                    raise serializers.ValidationError(
                        f"Each hour range must be a string"
                    )
        
        return data


class UsefulInfoSerializer(serializers.ModelSerializer):
    opening_hours = OpeningHoursField()

    class Meta:
        model = UsefulInfo
        fields = "__all__"