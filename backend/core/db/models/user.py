"""
User model.
"""

from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models

from core.db.enums import RoleEnum


class User(AbstractUser):
    """Custom user model with role-based access"""
    role = models.CharField(
        max_length=20,
        choices=RoleEnum.choices,
        default=RoleEnum.CITIZEN,
        help_text="User role in the system"
    )
    neighborhood = models.ForeignKey(
        'Neighborhood',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='residents',
        help_text="User's neighborhood"
    )
    
    class Meta:
        db_table = 'users'
        ordering = ['-date_joined']
    
    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.get_role_display()})"
    
    @property
    def is_citizen(self):
        return self.role == RoleEnum.CITIZEN
    
    @property
    def is_staff_member(self):
        return self.role in [RoleEnum.ELECTED, RoleEnum.AGENT, RoleEnum.GLOBAL_ADMIN]
