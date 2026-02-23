from rest_framework import serializers
from core.db.models import Survey, SurveyOption, Vote
from api.v1.serializers.user_serializer import UserPublicSerializer


class SurveyOptionSerializer(serializers.ModelSerializer):
    """Serializer for SurveyOption model"""
    vote_count = serializers.SerializerMethodField()
    
    class Meta:
        model = SurveyOption
        fields = ['id', 'text', 'vote_count']
        read_only_fields = ['id']
    
    def get_vote_count(self, obj):
        """Get the number of votes for this option"""
        return obj.votes.count()


class SurveySerializer(serializers.ModelSerializer):
    """Serializer for Survey model"""
    created_by = UserPublicSerializer(read_only=True)
    options = SurveyOptionSerializer(many=True, read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    total_votes = serializers.SerializerMethodField()
    
    class Meta:
        model = Survey
        fields = [
            'id', 'title', 'description', 'created_at', 'start_date',
            'end_date', 'created_by', 'options', 'is_active', 'total_votes'
        ]
        read_only_fields = ['id', 'created_at', 'created_by']
    
    def get_total_votes(self, obj):
        """Get the total number of votes for this survey"""
        return obj.votes.count()


class SurveyCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a survey with options"""
    options = serializers.ListField(
        child=serializers.CharField(max_length=255),
        write_only=True,
        help_text="List of option texts for the survey"
    )
    
    class Meta:
        model = Survey
        fields = ['id', 'title', 'description', 'start_date', 'end_date', 'options']
        read_only_fields = ['id']
    
    def validate_options(self, value):
        """Ensure at least one option is provided"""
        if not value:
            raise serializers.ValidationError("At least one option is required.")
        return value

    def create(self, validated_data):
        """Create survey with options"""
        options_data = validated_data.pop('options')
        survey = Survey.objects.create(**validated_data)
        
        # Create options
        for option_text in options_data:
            SurveyOption.objects.create(survey=survey, text=option_text)
        
        return survey
