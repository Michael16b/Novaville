from rest_framework import serializers
from core.db.models import Survey, SurveyOption, Vote
from api.v1.survey_access import can_vote_on_survey


class VoteSerializer(serializers.ModelSerializer):
    """Serializer for Vote model"""
    
    class Meta:
        model = Vote
        fields = ['id', 'user', 'survey', 'option', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class VoteCreateSerializer(serializers.Serializer):
    """Serializer for creating a vote"""

    survey = serializers.PrimaryKeyRelatedField(queryset=Survey.objects.all())
    option = serializers.PrimaryKeyRelatedField(
        queryset=SurveyOption.objects.all(),
        required=False,
        allow_null=True,
    )
    options = serializers.PrimaryKeyRelatedField(
        queryset=SurveyOption.objects.all(),
        many=True,
        required=False,
    )
    
    def validate(self, attrs):
        """Ensure the option belongs to the survey"""
        survey = attrs.get('survey')
        option = attrs.get('option')
        options = list(attrs.get('options') or [])
        request = self.context.get('request')

        if option is not None:
            options = [option]

        if not options:
            raise serializers.ValidationError(
                "At least one selected option is required."
            )

        if not survey.multiple_answers and len(options) > 1:
            raise serializers.ValidationError(
                "This survey accepts only one selected option."
            )

        unique_option_ids = {selected_option.id for selected_option in options}
        if len(unique_option_ids) != len(options):
            raise serializers.ValidationError(
                "Duplicate selected options are not allowed."
            )

        if any(selected_option.survey_id != survey.id for selected_option in options):
            raise serializers.ValidationError(
                "The selected option does not belong to this survey."
            )

        if request and not can_vote_on_survey(request.user, survey):
            raise serializers.ValidationError(
                "This survey is not available for your role."
            )

        attrs['options'] = options
        return attrs
