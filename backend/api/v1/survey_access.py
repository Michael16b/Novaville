from django.db.models import Q

from core.db.models import RoleEnum


def all_citizens_target_filter(field_name='citizen_target'):
    """Return a filter matching surveys open to every profile."""
    return Q(**{f'{field_name}__isnull': True}) | Q(**{field_name: ''})


def visible_survey_filter(user, field_name='citizen_target'):
    """Return the survey target filter for the current user's read access."""
    all_citizens = all_citizens_target_filter(field_name)

    if user.role in [RoleEnum.GLOBAL_ADMIN, RoleEnum.ELECTED]:
        return Q()

    return all_citizens | Q(**{field_name: user.role})


def can_vote_on_survey(user, survey):
    """Return whether the current user can vote on a visible survey."""
    if user.role == RoleEnum.GLOBAL_ADMIN:
        return True

    if not survey.citizen_target:
        return True

    return survey.citizen_target == user.role
