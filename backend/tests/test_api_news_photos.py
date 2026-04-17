import pytest
from rest_framework import status

from core.db.models import NewsPhoto


pytestmark = pytest.mark.django_db


class TestNewsPhotosAPI:
    def test_authenticated_user_can_list_news_photos(self, authenticated_client, elected_user):
        NewsPhoto.objects.create(
            title="Place",
            subtitle="Centre ville",
            image_url="https://example.com/photo.jpg",
            created_by=elected_user,
        )

        response = authenticated_client.get("/api/v1/news-photos/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert len(results) == 1

    def test_elected_can_create_news_photo(self, elected_client):
        response = elected_client.post(
            "/api/v1/news-photos/",
            {
                "title": "Marche du dimanche",
                "subtitle": "Ambiance matinale",
                "image_url": "https://example.com/marche.jpg",
            },
            format="json",
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert NewsPhoto.objects.count() == 1

    def test_citizen_cannot_create_news_photo(self, authenticated_client):
        response = authenticated_client.post(
            "/api/v1/news-photos/",
            {
                "title": "Refuse",
                "subtitle": "",
                "image_url": "https://example.com/refuse.jpg",
            },
            format="json",
        )

        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_admin_or_elected_can_delete_news_photo(self, elected_client, elected_user):
        photo = NewsPhoto.objects.create(
            title="Photo",
            subtitle="Sub",
            image_url="https://example.com/photo.jpg",
            created_by=elected_user,
        )

        response = elected_client.delete(f"/api/v1/news-photos/{photo.id}/")

        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert NewsPhoto.objects.filter(id=photo.id).exists() is False
