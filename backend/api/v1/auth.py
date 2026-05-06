from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView

from core.db.models.user import ApprovalStatus


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = get_user_model()
        fields = (
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "role",
            "address",
            "approval_status",
        )


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # place to add custom claims if needed
        token["username"] = user.get_username()
        return token

    def validate(self, attrs):
        username_field = self.username_field
        username = attrs.get(username_field)
        password = attrs.get("password")

        if username and password:
            user_model = get_user_model()
            try:
                candidate = user_model.objects.get(**{f"{username_field}__iexact": username})
            except user_model.DoesNotExist:
                candidate = user_model.objects.filter(email__iexact=username).first()

            if candidate and candidate.check_password(password):
                if candidate.approval_status != ApprovalStatus.APPROVED:
                    raise AuthenticationFailed("pending_approval")
                if not candidate.is_active:
                    raise AuthenticationFailed("account_disabled")
                attrs = attrs.copy()
                attrs[username_field] = candidate.get_username()

        data = super().validate(attrs)

        # attach user info to the response
        user = self.user
        data["user"] = UserSerializer(user).data

        return data


class LoginView(TokenObtainPairView):
    """Login view that returns access/refresh tokens and minimal user info."""
    serializer_class = CustomTokenObtainPairSerializer
