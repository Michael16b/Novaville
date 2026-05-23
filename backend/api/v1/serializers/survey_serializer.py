from rest_framework import serializers
from core.db.models import Survey, SurveyOption, Vote
from api.v1.serializers.neighborhood_serializer import NeighborhoodSerializer
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
    neighborhood_detail = NeighborhoodSerializer(source='neighborhood', read_only=True)
    options = SurveyOptionSerializer(many=True, read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    total_votes = serializers.SerializerMethodField()
    current_user_vote_id = serializers.SerializerMethodField()
    current_user_vote_option_id = serializers.SerializerMethodField()
    current_user_vote_ids = serializers.SerializerMethodField()
    current_user_vote_option_ids = serializers.SerializerMethodField()

    class Meta:
        model = Survey
        fields = [
            'id', 'title', 'description', 'address', 'neighborhood',
            'neighborhood_detail', 'created_at', 'start_date',
            'end_date', 'citizen_target', 'multiple_answers', 'created_by', 'options',
            'is_active', 'total_votes', 'current_user_vote_id',
            'current_user_vote_option_id', 'current_user_vote_ids',
            'current_user_vote_option_ids',
        ]
        read_only_fields = ['id', 'created_at', 'created_by']
        extra_kwargs = {
            'address': {'required': False, 'allow_blank': True},
            'neighborhood': {'required': False, 'allow_null': True},
            'citizen_target': {'required': False, 'allow_null': True},
            'multiple_answers': {'required': False},
        }
    
    def get_total_votes(self, obj):
        """Get the total number of votes for this survey"""
        return obj.votes.count()

    def _get_current_user_votes(self, obj):
        """Return the current authenticated user's votes for this survey."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return []

        cache_attr = '_current_user_votes_cache'
        cached_user_id_attr = '_current_user_votes_cache_user_id'
        user_id = request.user.id

        if (
            hasattr(obj, cache_attr)
            and getattr(obj, cached_user_id_attr, None) == user_id
        ):
            return getattr(obj, cache_attr)

        prefetched_votes = getattr(obj, '_prefetched_objects_cache', {}).get('votes')
        if prefetched_votes is not None:
            votes = [v for v in prefetched_votes if v.user_id == user_id]
        else:
            votes = list(Vote.objects.filter(user=request.user, survey=obj))

        setattr(obj, cache_attr, votes)
        setattr(obj, cached_user_id_attr, user_id)
        return votes

    def _get_current_user_vote(self, obj):
        """Return the first current authenticated user's vote for compatibility."""
        votes = self._get_current_user_votes(obj)
        return votes[0] if votes else None

    def get_current_user_vote_id(self, obj):
        """Get current user vote id for this survey."""
        vote = self._get_current_user_vote(obj)
        return vote.id if vote else None

    def get_current_user_vote_option_id(self, obj):
        """Get current user selected option id for this survey."""
        vote = self._get_current_user_vote(obj)
        return vote.option_id if vote else None

    def get_current_user_vote_ids(self, obj):
        """Get current user vote ids for this survey."""
        return [vote.id for vote in self._get_current_user_votes(obj)]

    def get_current_user_vote_option_ids(self, obj):
        """Get current user selected option ids for this survey."""
        return [vote.option_id for vote in self._get_current_user_votes(obj)]


class SurveyCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a survey with options"""
    options = serializers.ListField(
        child=serializers.CharField(max_length=255),
        write_only=True,
        help_text="List of option texts for the survey"
    )
    
    class Meta:
        model = Survey
        fields = [
            'id', 'title', 'description', 'address', 'neighborhood',
            'start_date', 'end_date', 'citizen_target', 'multiple_answers',
            'options',
        ]
        read_only_fields = ['id']
        extra_kwargs = {
            'address': {'required': False, 'allow_blank': True},
            'neighborhood': {'required': False, 'allow_null': True},
            'citizen_target': {'required': False, 'allow_null': True},
            'multiple_answers': {'required': False},
        }
    
    def validate_options(self, value):
        """Ensure at least two options are provided"""
        if len(value) < 2:
            raise serializers.ValidationError("At least two options are required.")
        return value

    def create(self, validated_data):
        """Create survey with options"""
        options_data = validated_data.pop('options')
        survey = Survey.objects.create(**validated_data)
        
        # Create options
        for option_text in options_data:
            SurveyOption.objects.create(survey=survey, text=option_text)
        
        return survey
