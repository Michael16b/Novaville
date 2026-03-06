"""Custom filters for the API v1."""

import django_filters
from core.db.models import Report


class ReportFilter(django_filters.FilterSet):
    """FilterSet for the Report model with date range support."""

    created_after = django_filters.DateTimeFilter(
        field_name="created_at",
        lookup_expr="gte",
        label="Created after (ISO 8601, e.g. 2025-01-01T00:00:00Z)",
    )
    created_before = django_filters.DateTimeFilter(
        field_name="created_at",
        lookup_expr="lte",
        label="Created before (ISO 8601, e.g. 2025-12-31T23:59:59Z)",
    )
    created_date = django_filters.DateFilter(
        field_name="created_at",
        lookup_expr="date",
        label="Created on exact date (YYYY-MM-DD)",
    )

    class Meta:
        """Meta options for ReportFilter."""

        model = Report
        fields = ["status", "problem_type", "neighborhood", "created_after", "created_before", "created_date"]

