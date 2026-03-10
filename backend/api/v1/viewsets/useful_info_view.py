from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser, AllowAny
from rest_framework import status

from core.db.models import UsefulInfo
from api.v1.serializers.useful_info_serializer import UsefulInfoSerializer


class UsefulInfoView(APIView):
    def get_permissions(self):
        if self.request.method in ["PUT", "PATCH"]:
            return [IsAdminUser()]
        return [AllowAny()]

    def _get_object(self):
        # there should always be exactly one row; if missing we create it with
        # safe defaults so that the DB constraints are satisfied.
        defaults = {
            "city_hall_name": "",
            "address_line1": "",
            "address_line2": "",
            "postal_code": "",
            "city": "",
            "phone": "",
            "email": "",
            "website": "",
            "instagram": "",
            "facebook": "",
            "x": "",
            "opening_hours": {},    
        }
        obj, _ = UsefulInfo.objects.get_or_create(pk=1, defaults=defaults)
        return obj

    def get(self, request):
        obj = self._get_object()
        serializer = UsefulInfoSerializer(obj)
        return Response(serializer.data)

    def put(self, request):
        obj = self._get_object()
        serializer = UsefulInfoSerializer(obj, data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)