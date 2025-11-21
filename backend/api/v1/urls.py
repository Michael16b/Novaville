from rest_framework.routers import DefaultRouter
from django.urls import path
from api.v1.viewsets.item_viewset import ItemViewSet
from api.v1.auth import LoginView
from rest_framework_simplejwt.views import TokenRefreshView

router = DefaultRouter()
router.register(r"items", ItemViewSet, basename="item")

# router.urls is a list; we extend it with auth endpoints
urlpatterns = router.urls + [
	path("auth/token/", LoginView.as_view(), name="token_obtain_pair"),
	path("auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
]
