from typing import Dict, Any, Optional
from django.core.exceptions import PermissionDenied
from infrastructure.repositories.item_repository import ItemRepository

class NotFoundError(Exception):
    pass

class ItemService:
    def __init__(self, repository: ItemRepository):
        self.repo = repository

    def get_item(self, pk: int):
        item = self.repo.get(pk)
        if not item:
            raise NotFoundError("Item not found")
        return item

    def list_items(self, filters: Dict[str, Any] = None, ordering: str = None):
        return self.repo.list(filters=filters or {}, ordering=ordering)

    def create_item(self, data: Dict[str, Any], owner):
        data["owner"] = owner
        return self.repo.create(**data)

    def update_item(self, pk: int, data: Dict[str, Any], user):
        item = self.get_item(pk)
        if item.owner != user:
            raise PermissionDenied("Not allowed")
        return self.repo.update(item, **data)

    def delete_item(self, pk: int, user):
        item = self.get_item(pk)
        if item.owner != user:
            raise PermissionDenied("Not allowed")
        self.repo.delete(item)
