from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from core.db.models import (
    User, Neighborhood, Report, Survey, SurveyOption, 
    Vote, Event, ThemeEvent
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin configuration for custom User model"""
    list_display = ['username', 'email', 'first_name', 'last_name', 'role', 'is_active', 'is_staff']
    list_filter = ['role', 'is_active', 'is_staff', 'is_superuser']
    search_fields = ['username', 'email', 'first_name', 'last_name']
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Role Information', {'fields': ('role', 'neighborhood')}),
    )
    
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Role Information', {'fields': ('role', 'neighborhood')}),
    )


@admin.register(Neighborhood)
class NeighborhoodAdmin(admin.ModelAdmin):
    """Admin configuration for Neighborhood model"""
    list_display = ['name', 'postal_code']
    search_fields = ['name', 'postal_code']


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    """Admin configuration for Report model"""
    list_display = ['id', 'problem_type', 'status', 'user', 'neighborhood', 'created_at']
    list_filter = ['status', 'problem_type', 'created_at']
    search_fields = ['description', 'user__username', 'neighborhood__name']
    date_hierarchy = 'created_at'
    raw_id_fields = ['user', 'neighborhood']


@admin.register(Survey)
class SurveyAdmin(admin.ModelAdmin):
    """Admin configuration for Survey model"""
    list_display = ['title', 'created_by', 'start_date', 'end_date', 'created_at']
    list_filter = ['created_at', 'start_date', 'end_date']
    search_fields = ['title', 'description']
    date_hierarchy = 'created_at'
    raw_id_fields = ['created_by']


@admin.register(SurveyOption)
class SurveyOptionAdmin(admin.ModelAdmin):
    """Admin configuration for SurveyOption model"""
    list_display = ['id', 'survey', 'text']
    search_fields = ['text', 'survey__title']
    raw_id_fields = ['survey']


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    """Admin configuration for Vote model"""
    list_display = ['id', 'user', 'survey', 'option', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'survey__title']
    date_hierarchy = 'created_at'
    raw_id_fields = ['user', 'survey', 'option']


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    """Admin configuration for Event model"""
    list_display = ['title', 'theme', 'start_date', 'end_date', 'created_by']
    list_filter = ['theme', 'start_date', 'end_date']
    search_fields = ['title', 'description']
    date_hierarchy = 'start_date'
    raw_id_fields = ['created_by', 'theme']


@admin.register(ThemeEvent)
class ThemeEventAdmin(admin.ModelAdmin):
    """Admin configuration for ThemeEvent model"""
    list_display = ['id', 'title']
    search_fields = ['title']
