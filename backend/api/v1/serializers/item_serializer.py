from rest_framework import serializers
from core.db.models import Item

class ItemSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source="owner.username")

    class Meta:
        model = Item
        fields = ["id", "name", "description", "owner", "is_active", "created_at", "updated_at"]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]
