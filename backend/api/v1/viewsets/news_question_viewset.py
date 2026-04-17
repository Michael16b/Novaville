from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from api.v1.serializers.news_question_serializer import (
    NewsQuestionCreateSerializer,
    NewsQuestionReplySerializer,
    NewsQuestionSerializer,
)
from core.db.models import NewsQuestion, NewsQuestionStatus


@extend_schema_view(
    list=extend_schema(
        summary="List news questions",
        description=(
            "Citizens see only their own questions. Municipal staff sees all "
            "citizen questions."
        ),
        tags=["News"],
    ),
    create=extend_schema(
        summary="Create a news question",
        description="Send a question to city hall from the news page.",
        tags=["News"],
    ),
    retrieve=extend_schema(
        summary="Get a news question",
        description="Retrieve a question and its answer.",
        tags=["News"],
    ),
)
class NewsQuestionViewSet(viewsets.ModelViewSet):
    """ViewSet for citizen questions sent from the news page."""

    queryset = NewsQuestion.objects.select_related("citizen", "answered_by").all()
    permission_classes = [IsAuthenticated]
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_queryset(self):
        user = self.request.user
        if getattr(user, "is_staff_member", False) or user.is_staff:
            return self.queryset.filter(hidden_by_staff=False)
        return self.queryset.filter(citizen=user, citizen_deleted=False)

    def get_serializer_class(self):
        if self.action == "create":
            return NewsQuestionCreateSerializer
        return NewsQuestionSerializer

    def perform_create(self, serializer):
        serializer.save(citizen=self.request.user)

    @extend_schema(
        summary="Reply to a news question",
        description="Municipal staff answers a citizen question.",
        tags=["News"],
        request=NewsQuestionReplySerializer,
        responses={200: NewsQuestionSerializer},
    )
    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def reply(self, request, pk=None):
        question = self.get_object()
        if not (getattr(request.user, "is_staff_member", False) or request.user.is_staff):
            return Response(
                {"error": "Only municipal staff can answer questions."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = NewsQuestionReplySerializer(
            data=request.data,
            context={"request": request, "question": question},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(NewsQuestionSerializer(question).data)

    @extend_schema(
        summary="Hide an answered news question",
        description="Municipal staff archives an answered discussion.",
        tags=["News"],
        responses={200: NewsQuestionSerializer},
    )
    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def hide(self, request, pk=None):
        question = self.get_object()
        if not (getattr(request.user, "is_staff_member", False) or request.user.is_staff):
            return Response(
                {"error": "Only municipal staff can hide discussions."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if question.status != NewsQuestionStatus.ANSWERED:
            return Response(
                {"error": "Only answered discussions can be hidden."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        question.hidden_by_staff = True
        question.save(update_fields=["hidden_by_staff"])
        return Response(NewsQuestionSerializer(question).data)

    def destroy(self, request, *args, **kwargs):
        question = self.get_object()
        if question.citizen_id != request.user.id and not (
            getattr(request.user, "is_staff_member", False) or request.user.is_staff
        ):
            return Response(
                {"error": "Only the owner or staff can delete this discussion."},
                status=status.HTTP_403_FORBIDDEN,
            )

        question.citizen_deleted = True
        question.save(update_fields=["citizen_deleted"])
        return Response(status=status.HTTP_204_NO_CONTENT)
