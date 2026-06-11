"""
User model.
"""

from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models

from core.db.enums import RoleEnum


class ApprovalStatus(models.TextChoices):
    PENDING = "PENDING", "Pending"
    APPROVED = "APPROVED", "Approved"


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
    address = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="User's postal address",
    )
    approval_status = models.CharField(
        max_length=20,
        choices=ApprovalStatus.choices,
        default=ApprovalStatus.APPROVED,
        help_text="Approval workflow status for user registrations",
    )
    first_login_completed = models.BooleanField(
        default=False,
        help_text="Whether the user has completed their first login and set their own password"
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

    @property
    def is_pending_approval(self):
        return self.approval_status == ApprovalStatus.PENDING
