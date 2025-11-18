from rest_framework.routers import DefaultRouter
from api.v1.viewsets.item_viewset import ItemViewSet

router = DefaultRouter()
router.register(r"items", ItemViewSet, basename="item")

urlpatterns = router.urls
