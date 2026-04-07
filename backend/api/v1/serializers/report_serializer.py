from django.core.validators import RegexValidator
from rest_framework import serializers
from core.db.models import Report
from api.v1.patterns import REPORT_ADDRESS_PATTERN
from api.v1.serializers.user_serializer import UserPublicSerializer
from api.v1.serializers.neighborhood_serializer import NeighborhoodSerializer


class _ReportValidationMixin:
    """Common validation helpers for report serializers."""

    def validate_title(self, value):
        """Reject blank titles."""
        if not value or not value.strip():
            raise serializers.ValidationError("Title is required and cannot be blank.")
        return value.strip()

    def validate_address(self, value):
        """Reject blank or malformed exact addresses."""
        if not value or not value.strip():
            raise serializers.ValidationError("Address is required and cannot be blank.")
        normalized_value = " ".join(value.strip().split())
        RegexValidator(
            regex=REPORT_ADDRESS_PATTERN,
            message=(
                "Enter an exact address like '12 rue de la Paix'. "
                "A street-type address must start with a number."
            ),
        )(normalized_value)
        return normalized_value


class ReportSerializer(_ReportValidationMixin, serializers.ModelSerializer):
    """Serializer for Report model"""
    user = UserPublicSerializer(read_only=True)
    neighborhood_detail = NeighborhoodSerializer(source='neighborhood', read_only=True)
    
    class Meta:
        model = Report
        fields = [
            'id', 'title', 'problem_type', 'description', 'created_at',
            'status', 'user', 'address', 'neighborhood', 'neighborhood_detail'
        ]
        read_only_fields = ['id', 'created_at', 'user']
        extra_kwargs = {
            'address': {'required': False, 'allow_blank': False},
        }


class ReportCreateSerializer(_ReportValidationMixin, serializers.ModelSerializer):
    """Serializer for creating a report"""
    
    class Meta:
        model = Report
        fields = ['id', 'title', 'problem_type', 'description', 'address', 'neighborhood']
        read_only_fields = ['id']
        extra_kwargs = {
            'address': {'required': True, 'allow_blank': False},
        }
