import pytest
from rest_framework import status

from core.db.models import NewsQuestion, NewsQuestionStatus


pytestmark = pytest.mark.django_db


class TestNewsQuestionsAPI:
    def test_citizen_can_create_question(self, authenticated_client, citizen_user):
        response = authenticated_client.post(
            "/api/v1/news-questions/",
            {"subject": "Travaux rue des Lilas", "message": "Quand se terminent-ils ?"},
            format="json",
        )

        assert response.status_code == status.HTTP_201_CREATED
        question = NewsQuestion.objects.get()
        assert question.citizen == citizen_user
        assert question.status == NewsQuestionStatus.PENDING

    def test_citizen_only_sees_own_questions(
        self,
        authenticated_client,
        citizen_user,
        neighborhood,
    ):
        NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Ma question",
            message="Mon message",
        )
        other_user = citizen_user.__class__.objects.create_user(
            username="someoneelse",
            password="TestPass123",
            role="CITIZEN",
            neighborhood=neighborhood,
        )
        NewsQuestion.objects.create(
            citizen=other_user,
            subject="Autre question",
            message="Autre message",
        )

        response = authenticated_client.get("/api/v1/news-questions/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert len(results) == 1
        assert results[0]["subject"] == "Ma question"

    def test_staff_sees_all_questions(self, elected_client, citizen_user):
        NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Question 1",
            message="Message 1",
        )
        NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Question 2",
            message="Message 2",
        )

        response = elected_client.get("/api/v1/news-questions/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert len(results) == 2

    def test_staff_can_reply(self, elected_client, citizen_user, elected_user):
        question = NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Question",
            message="Message",
        )

        response = elected_client.post(
            f"/api/v1/news-questions/{question.id}/reply/",
            {"response": "Les travaux se terminent vendredi."},
            format="json",
        )

        assert response.status_code == status.HTTP_200_OK
        question.refresh_from_db()
        assert question.status == NewsQuestionStatus.ANSWERED
        assert question.answered_by == elected_user
        assert question.response == "Les travaux se terminent vendredi."
        assert question.answered_at is not None

    def test_citizen_cannot_reply(self, authenticated_client, citizen_user):
        question = NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Question",
            message="Message",
        )

        response = authenticated_client.post(
            f"/api/v1/news-questions/{question.id}/reply/",
            {"response": "Réponse interdite"},
            format="json",
        )

        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_citizen_can_delete_own_discussion(self, authenticated_client, citizen_user):
        question = NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Question",
            message="Message",
        )

        response = authenticated_client.delete(
            f"/api/v1/news-questions/{question.id}/",
        )

        assert response.status_code == status.HTTP_204_NO_CONTENT
        question.refresh_from_db()
        assert question.citizen_deleted is True

    def test_staff_can_hide_answered_discussion(self, elected_client, citizen_user):
        question = NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Question",
            message="Message",
            status=NewsQuestionStatus.ANSWERED,
            response="Reponse",
        )

        response = elected_client.post(
            f"/api/v1/news-questions/{question.id}/hide/",
            {},
            format="json",
        )

        assert response.status_code == status.HTTP_200_OK
        question.refresh_from_db()
        assert question.hidden_by_staff is True

    def test_staff_cannot_hide_pending_discussion(self, elected_client, citizen_user):
        question = NewsQuestion.objects.create(
            citizen=citizen_user,
            subject="Question",
            message="Message",
        )

        response = elected_client.post(
            f"/api/v1/news-questions/{question.id}/hide/",
            {},
            format="json",
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST
