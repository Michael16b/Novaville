from rest_framework import status, permissions
from rest_framework.viewsets import GenericViewSet
from rest_framework.response import Response
from rest_framework.exceptions import NotFound, PermissionDenied
from rest_framework.filters import OrderingFilter, SearchFilter
from django_filters.rest_framework import DjangoFilterBackend

from api.v1.serializers.item_serializer import ItemSerializer
from infrastructure.repositories.item_repository import ItemRepository
from application.services.item_service import ItemService, NotFoundError

_repo = ItemRepository()
_service = ItemService(_repo)

class ItemViewSet(GenericViewSet):
    serializer_class = ItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter, SearchFilter]
    filterset_fields = ["owner", "is_active"]
    ordering_fields = ["created_at", "name"]
    search_fields = ["name", "description"]

    def list(self, request):
        filters = {}
        owner = request.query_params.get("owner")
        if owner:
            filters["owner__id"] = owner
        is_active = request.query_params.get("is_active")
        if is_active is not None:
            if is_active.lower() in ("true", "1"):
                filters["is_active"] = True
            elif is_active.lower() in ("false", "0"):
                filters["is_active"] = False
        ordering = request.query_params.get("ordering")
        qs = _service.list_items(filters=filters, ordering=ordering)
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    def retrieve(self, request, pk=None):
        try:
            item = _service.get_item(pk)
        except NotFoundError:
            raise NotFound("Item not found")
        serializer = self.get_serializer(item)
        return Response(serializer.data)

    def create(self, request):
        payload = request.data
        item = _service.create_item(payload, owner=request.user)
        serializer = self.get_serializer(item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request, pk=None):
        payload = request.data
        try:
            item = _service.update_item(pk, payload, user=request.user)
        except NotFoundError:
            raise NotFound("Item not found")
        except PermissionDenied:
            raise PermissionDenied("Not allowed")
        serializer = self.get_serializer(item)
        return Response(serializer.data)

    def partial_update(self, request, pk=None):
        return self.update(request, pk)

    def destroy(self, request, pk=None):
        try:
            _service.delete_item(pk, user=request.user)
        except NotFoundError:
            raise NotFound("Item not found")
        except PermissionDenied:
            raise PermissionDenied("Not allowed")
        return Response(status=status.HTTP_204_NO_CONTENT)
