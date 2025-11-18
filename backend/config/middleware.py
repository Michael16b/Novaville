from django.conf import settings
from django.http import HttpResponseForbidden


class AdminIPRestrictionMiddleware:
    """Restrict access to /admin/ by IP address when ADMIN_ALLOWED_IPS is configured.

    - If ADMIN_ALLOWED_IPS is empty, the middleware does nothing.
    - If ENABLE_ADMIN is False, the admin URLs should not be included (see config.urls).
    """

    def __init__(self, get_response):
        self.get_response = get_response
        self.allowed = getattr(settings, "ADMIN_ALLOWED_IPS", []) or []

    def __call__(self, request):
        # Only perform check for admin paths
        if request.path.startswith("/admin/") and self.allowed:
            # REMOTE_ADDR may be the proxy IP if you're behind a reverse proxy
            # In production behind a reverse proxy you may want to trust X-Forwarded-For
            ip = request.META.get("REMOTE_ADDR")
            if ip not in self.allowed:
                return HttpResponseForbidden("Forbidden")
        return self.get_response(request)
