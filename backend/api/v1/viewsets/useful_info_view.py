from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser, AllowAny
from rest_framework import status

from core.db.models import UsefulInfo
from api.v1.serializers.useful_info_serializer import UsefulInfoSerializer


class UsefulInfoView(APIView):
    """Endpoint for reading/updating the useful information.

    GET is publicly accessible and returns the current stored JSON object.
    PUT can only be performed by admin users and will replace the stored
    info with the provided data.
    """

    def get_permissions(self):
        # allow anyone to read, only admins can write
        if self.request.method in ["PUT", "PATCH"]:
            return [IsAdminUser()]
        return [AllowAny()]

    def _get_object(self):
        # always work with the singleton instance
        obj, _ = UsefulInfo.objects.get_or_create(pk=1)
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
