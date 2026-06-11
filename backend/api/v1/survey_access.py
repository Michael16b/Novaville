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

    role_filter = all_citizens | Q(**{field_name: user.role})

    if field_name == 'citizen_target':
        neighborhood_filter = (
            Q(neighborhood__isnull=True)
            | Q(neighborhood=user.neighborhood)
        )
    else:
        survey_prefix = field_name.rsplit('__', 1)[0]
        neighborhood_filter = (
            Q(**{f'{survey_prefix}__neighborhood__isnull': True})
            | Q(**{f'{survey_prefix}__neighborhood': user.neighborhood})
        )

    return role_filter & neighborhood_filter


def can_vote_on_survey(user, survey):
    """Return whether the current user can vote on a visible survey."""
    if user.role == RoleEnum.GLOBAL_ADMIN:
        return True

    if survey.neighborhood_id and survey.neighborhood_id != user.neighborhood_id:
        return False

    if not survey.citizen_target:
        return True

    return survey.citizen_target == user.role
