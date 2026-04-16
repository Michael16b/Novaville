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
        """Normalize exact addresses and reject malformed non-empty values."""
        if not value or not value.strip():
            return ""
        normalized_value = " ".join(value.strip().split())
        RegexValidator(
            regex=REPORT_ADDRESS_PATTERN,
            message=(
                "Enter an exact address like '12 rue de la Paix'. "
                "A street-type address must start with a number."
            ),
        )(normalized_value)
        return normalized_value

    def validate(self, attrs):
        """Require either an exact address or a neighborhood."""
        attrs = super().validate(attrs)

        instance = getattr(self, "instance", None)
        address = attrs.get("address")
        neighborhood = attrs.get("neighborhood")

        if address is None and instance is not None:
            address = instance.address
        if neighborhood is None and instance is not None:
            neighborhood = instance.neighborhood

        if not (address or neighborhood):
            raise serializers.ValidationError(
                {
                    "address": "Provide an exact address or select a neighborhood.",
                    "neighborhood": "Provide an exact address or select a neighborhood.",
                }
            )

        return attrs


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
            'address': {'required': False, 'allow_blank': True},
        }


class ReportCreateSerializer(_ReportValidationMixin, serializers.ModelSerializer):
    """Serializer for creating a report"""
    
    class Meta:
        model = Report
        fields = ['id', 'title', 'problem_type', 'description', 'address', 'neighborhood']
        read_only_fields = ['id']
        extra_kwargs = {
            'address': {'required': False, 'allow_blank': True},
        }
