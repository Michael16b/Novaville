from django.utils import timezone
from rest_framework import serializers

from api.v1.serializers.user_serializer import UserPublicSerializer
from core.db.models import NewsQuestion, NewsQuestionStatus


class NewsQuestionSerializer(serializers.ModelSerializer):
    """Serializer for news-page questions and answers."""

    citizen = UserPublicSerializer(read_only=True)
    answered_by = UserPublicSerializer(read_only=True)

    class Meta:
        model = NewsQuestion
        fields = [
            "id",
            "subject",
            "message",
            "response",
            "status",
            "created_at",
            "answered_at",
            "citizen",
            "answered_by",
        ]
        read_only_fields = ["id", "status", "created_at", "answered_at", "citizen", "answered_by"]


class NewsQuestionCreateSerializer(serializers.ModelSerializer):
    """Serializer used when a citizen submits a new question."""

    class Meta:
        model = NewsQuestion
        fields = ["id", "subject", "message", "status", "created_at"]
        read_only_fields = ["id", "status", "created_at"]


class NewsQuestionReplySerializer(serializers.Serializer):
    """Serializer used by municipal staff to answer a question."""

    response = serializers.CharField(allow_blank=False, trim_whitespace=True)

    def save(self, **kwargs):
        question = self.context["question"]
        request = self.context["request"]
        question.response = self.validated_data["response"].strip()
        question.status = NewsQuestionStatus.ANSWERED
        question.answered_at = timezone.now()
        question.answered_by = request.user
        question.save(
            update_fields=["response", "status", "answered_at", "answered_by"]
        )
        return question
