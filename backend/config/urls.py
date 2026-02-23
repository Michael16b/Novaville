import os
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
try:
    from drf_spectacular.views import (
        SpectacularAPIView,
        SpectacularSwaggerView,
        SpectacularRedocView,
    )
except Exception:
    SpectacularAPIView = None
    SpectacularSwaggerView = None
    SpectacularRedocView = None

urlpatterns = [
    path("api/v1/", include("api.v1.urls")),
    # also expose the same routes without the version prefix for convenience
    path("api/", include("api.v1.urls")),
]

# Include grappelli (admin theme) if installed
try:
    import grappelli  # noqa: F401
    urlpatterns = [path("grappelli/", include("grappelli.urls"))] + urlpatterns
except Exception:
    # grappelli not installed
    pass

# Only expose admin if DEBUG is True or ENABLE_ADMIN env var is enabled
ENABLE_ADMIN = os.environ.get("ENABLE_ADMIN", "1").lower() in ("1", "true", "yes")
if settings.DEBUG or ENABLE_ADMIN:
    urlpatterns = [path("admin/", admin.site.urls)] + urlpatterns

# OpenAPI / Swagger (drf-spectacular) - expose schema and Swagger UI when available
if SpectacularAPIView is not None:
    # Only expose API docs when enabled (useful to disable in production)
    ENABLE_API_DOCS = getattr(settings, "ENABLE_API_DOCS", True)
    if ENABLE_API_DOCS:
        urlpatterns += [
            path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
        ]
        # Provide a Swagger UI at /api/docs/
        if SpectacularSwaggerView is not None:
            urlpatterns += [
                path(
                    "api/docs/",
                    SpectacularSwaggerView.as_view(url_name="schema"),
                    name="swagger-ui",
                ),
            ]
        # Provide ReDoc UI at /api/redoc/
        if SpectacularRedocView is not None:
            urlpatterns += [
                path(
                    "api/redoc/",
                    SpectacularRedocView.as_view(url_name="schema"),
                    name="redoc",
                ),
            ]
