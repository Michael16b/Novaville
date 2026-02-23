from rest_framework import serializers
from core.db.models import Vote


class VoteSerializer(serializers.ModelSerializer):
    """Serializer for Vote model"""
    
    class Meta:
        model = Vote
        fields = ['id', 'user', 'survey', 'option', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class VoteCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a vote"""
    
    class Meta:
        model = Vote
        fields = ['survey', 'option']
    
    def validate(self, attrs):
        """Ensure the option belongs to the survey"""
        survey = attrs.get('survey')
        option = attrs.get('option')
        
        if option.survey != survey:
            raise serializers.ValidationError(
                "The selected option does not belong to this survey."
            )
        
        return attrs
