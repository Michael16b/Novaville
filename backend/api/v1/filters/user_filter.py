"""Custom filters for the user API v1."""

import django_filters

from core.db.models import User


class UserFilter(django_filters.FilterSet):
    """FilterSet for the User model."""

    address = django_filters.CharFilter(
        field_name="address",
        lookup_expr="icontains",
        label="Filter by address (case-insensitive partial match)",
    )

    class Meta:
        """Meta options for UserFilter."""

        model = User
        fields = ["role", "approval_status", "neighborhood", "address"]
