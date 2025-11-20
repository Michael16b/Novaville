from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = get_user_model()
        fields = ("id", "username", "email", "first_name", "last_name")


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # place to add custom claims if needed
        token["username"] = user.get_username()
        return token

    def validate(self, attrs):
        data = super().validate(attrs)

        # attach user info to the response
        user = self.user
        data["user"] = UserSerializer(user).data

        return data


class LoginView(TokenObtainPairView):
    """Login view that returns access/refresh tokens and minimal user info."""
    serializer_class = CustomTokenObtainPairSerializer
