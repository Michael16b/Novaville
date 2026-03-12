from django.db import models
from django.core.exceptions import ValidationError


# Order of days for consistent ordering
DAY_ORDER = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
]


def validate_opening_hours(value):
    """Validate opening_hours format: must be dict<str, list<str>>."""
    if not isinstance(value, dict):
        raise ValidationError("opening_hours must be a dictionary")
    
    for day, hours in value.items():
        if not isinstance(day, str):
            raise ValidationError(f"Day key must be a string, got {type(day).__name__}")
        if not isinstance(hours, list):
            raise ValidationError(
                f"Hours for '{day}' must be a list of strings, got {type(hours).__name__}"
            )
        for hour_range in hours:
            if not isinstance(hour_range, str):
                raise ValidationError(
                    f"Each hour range must be a string, got {type(hour_range).__name__}"
                )


def sort_opening_hours(opening_hours_dict):
    """Sort opening_hours dict by day order for consistent persistence."""
    if not opening_hours_dict:
        return {}
    
    # Create new dict with days in correct order
    result = {}
    
    # Add days in DAY_ORDER first
    for day in DAY_ORDER:
        if day in opening_hours_dict:
            result[day] = opening_hours_dict[day]
    
    # Add any unknown days at the end
    for day, hours in opening_hours_dict.items():
        if day not in result:
            result[day] = hours
    
    return result


class UsefulInfo(models.Model):
    city_hall_name = models.CharField(max_length=255)
    address_line1 = models.CharField(max_length=255)
    address_line2 = models.CharField(max_length=255, blank=True, default="")
    postal_code = models.CharField(max_length=10)
    city = models.CharField(max_length=100)
    phone = models.CharField(max_length=30)
    email = models.EmailField()
    website = models.URLField()
    instagram = models.CharField(max_length=255, blank=True, null=True)
    facebook = models.CharField(max_length=255, blank=True, null=True)
    x = models.CharField(max_length=255, blank=True, null=True)
    opening_hours = models.JSONField(
        default=dict,
        blank=True,
        validators=[validate_opening_hours],
        help_text='Format: {"Lundi": ["09:00-16:00"], "Mardi": []}'
    )

    class Meta:
        db_table = "useful_info"

    def save(self, *args, **kwargs):
    # enforce singleton
        self.pk = 1

        # Sort opening_hours by day order before saving
        if self.opening_hours:
            self.opening_hours = sort_opening_hours(self.opening_hours)

        exists = type(self).objects.filter(pk=1).exists()

        # If create() (or caller) set force_insert=True, remove it when we need update
        if exists:
            kwargs.pop("force_insert", None)
            # If object is in "adding" state, it would try to INSERT -> force UPDATE instead
            if self._state.adding:
                kwargs["force_update"] = True

        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        # disallow deletion via ORM; remove only by manual SQL if really needed
        return

    def __str__(self):
        return "Useful information"