from typing import Dict, Any, Optional
from django.db.models import QuerySet
from core.db.models import Item

class ItemRepository:
    def __init__(self):
        self.model = Item

    def get(self, pk: int) -> Optional[Item]:
        try:
            return self.model.objects.get(pk=pk)
        except self.model.DoesNotExist:
            return None

    def list(self, filters: Dict[str, Any] = None, ordering: str = None) -> QuerySet:
        qs = self.model.objects.all()
        if filters:
            qs = qs.filter(**filters)
        if ordering:
            qs = qs.order_by(ordering)
        return qs

    def create(self, **data) -> Item:
        return self.model.objects.create(**data)

    def update(self, instance: Item, **data) -> Item:
        for k, v in data.items():
            setattr(instance, k, v)
        instance.save()
        return instance

    def delete(self, instance: Item) -> None:
        instance.delete()
