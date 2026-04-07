from rest_framework import serializers

from api.v1.serializers.user_serializer import UserPublicSerializer
from core.db.models import NewsPhoto


class NewsPhotoSerializer(serializers.ModelSerializer):
    """Serializer for news page photos."""

    created_by = UserPublicSerializer(read_only=True)

    class Meta:
        model = NewsPhoto
        fields = ["id", "title", "subtitle", "image_url", "created_at", "created_by"]
        read_only_fields = ["id", "created_at", "created_by"]
