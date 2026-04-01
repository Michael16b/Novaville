from rest_framework import serializers
from core.db.models import User, RoleEnum
from core.db.models.user import ApprovalStatus
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError

class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model"""
    password = serializers.CharField(write_only=True, required=False, validators=[validate_password])

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'neighborhood', 'date_joined', 'password',
            'address', 'approval_status', 'is_active'
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

    def validate_username(self, value):
        queryset = User.objects.filter(username__iexact=value)
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError("username_already_exists")
        return value

    def validate_approval_status(self, value):
        request = self.context.get('request')
        if request and (not request.user.is_authenticated or not request.user.is_staff):
            if self.instance:
                return self.instance.approval_status
            return ApprovalStatus.PENDING
        return value

    def validate_is_active(self, value):
        request = self.context.get('request')
        if request and (not request.user.is_authenticated or not request.user.is_staff):
            if self.instance:
                return self.instance.is_active
            return False
        return value

    def create(self, validated_data):
        """Create a new user with hashed password"""
        password = validated_data.pop('password', None)
        if not password:
            raise serializers.ValidationError({"password": "This field is required."})

        request = self.context.get('request')
        is_staff_request = bool(
            request and request.user.is_authenticated and request.user.is_staff
        )
        if not is_staff_request:
            validated_data['role'] = RoleEnum.CITIZEN
            validated_data['approval_status'] = ApprovalStatus.PENDING
            validated_data['is_active'] = False
        else:
            validated_data.setdefault('approval_status', ApprovalStatus.APPROVED)
            validated_data.setdefault('is_active', True)

        user = User(**validated_data)

        try:
            validate_password(password, user=user)
        except DjangoValidationError as e:
            raise serializers.ValidationError({"password": list(e.messages)})

        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        """Update user, handle password hashing"""
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if password:
            try:
                validate_password(password, user=instance)
            except DjangoValidationError as e:
                raise serializers.ValidationError({"password": list(e.messages)})
            instance.set_password(password)

        instance.save()
        return instance

class UserPublicSerializer(serializers.ModelSerializer):
    """Public serializer for User model (minimal information)"""

    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'role', 'address']
        read_only_fields = fields
