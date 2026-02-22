"""Custom permissions for Novaville API"""
from rest_framework import permissions
from core.db.models import RoleEnum


class IsOwnerOrStaff(permissions.BasePermission):
    """
    Object-level permission to only allow owners of an object or staff to edit it.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any authenticated user
        if request.method in permissions.SAFE_METHODS:
            return request.user.is_authenticated
        
        # Check if user is staff
        if request.user.is_staff:
            return True
        
        # Check if user is the owner
        if hasattr(obj, 'user'):
            return obj.user == request.user
        if hasattr(obj, 'created_by'):
            return obj.created_by == request.user
        
        return False


class IsStaffOrReadOnly(permissions.BasePermission):
    """
    Permission to only allow staff members to create/edit.
    Read-only access for authenticated users.
    """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Read operations are allowed for all authenticated users
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write operations require staff
        return request.user.is_staff


class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Permission to only allow admins to create/edit.
    Read-only access for authenticated users.
    """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Read operations are allowed for all authenticated users
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write operations require admin
        return request.user.role == RoleEnum.GLOBAL_ADMIN


class IsElectedOrAgentOrAdmin(permissions.BasePermission):
    """
    Permission for elected officials, agents, and admins.
    """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        return request.user.role in [
            RoleEnum.ELECTED,
            RoleEnum.AGENT,
            RoleEnum.GLOBAL_ADMIN
        ]


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Object-level permission to only allow owners to edit.
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Check ownership
        if hasattr(obj, 'user'):
            return obj.user == request.user
        if hasattr(obj, 'created_by'):
            return obj.created_by == request.user
        
        return request.user.is_staff
