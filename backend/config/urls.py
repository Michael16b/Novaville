import os
from django.contrib import admin
from django.urls import path, include
from django.conf import settings

urlpatterns = [
    path("api/v1/", include("api.v1.urls")),
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
