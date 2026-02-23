from rest_framework import serializers
from core.db.models import User, RoleEnum
from django.contrib.auth.password_validation import validate_password


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model"""
    password = serializers.CharField(write_only=True, required=False, validators=[validate_password])
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'neighborhood', 'is_active', 'date_joined', 'password'
        ]
        read_only_fields = ['id', 'date_joined']
        extra_kwargs = {
            'password': {'write_only': True}
        }
    
    def validate_role(self, value):
        """Prevent non-admin users from changing their role"""
        request = self.context.get('request')
        if request and (not request.user.is_authenticated or not request.user.is_staff):
            if self.instance:
                return self.instance.role
            return RoleEnum.CITIZEN
        return value

    def create(self, validated_data):
        """Create a new user with hashed password"""
        password = validated_data.pop('password', None)
        if not password:
            raise serializers.ValidationError({"password": "This field is required."})
        user = User.objects.create(**validated_data)
        user.set_password(password)
        user.save()
        return user
    
    def update(self, instance, validated_data):
        """Update user, handle password hashing"""
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class UserPublicSerializer(serializers.ModelSerializer):
    """Public serializer for User model (minimal information)"""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'role']
        read_only_fields = fields
