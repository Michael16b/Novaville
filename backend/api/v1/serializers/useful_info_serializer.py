from rest_framework import serializers

from core.db.models import UsefulInfo


class UsefulInfoSerializer(serializers.ModelSerializer):
    """Serializer for the single UsefulInfo record."""

    class Meta:
        model = UsefulInfo
        fields = ["info"]
