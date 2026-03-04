"""Tests for the useful-info endpoint."""
import pytest
from rest_framework import status

pytestmark = pytest.mark.django_db


class TestUsefulInfoAPI:
    def test_get_returns_default_object(self, api_client):
        """GET should succeed even if no row existed before."""
        response = api_client.get("/api/v1/useful-info/")
        assert response.status_code == status.HTTP_200_OK
        data = response.data
        # at least the expected keys are present
        for key in [
            "city_hall_name",
            "address_line1",
            "address_line2",
            "postal_code",
            "city",
            "phone",
            "email",
            "website",
            "opening_hours",
        ]:
            assert key in data

    def test_put_requires_admin(self, api_client, authenticated_client):
        """Only an admin can perform PUT; unauthenticated users get 401 and
        authenticated non-admins get 403."""
        payload = {"city_hall_name": "foo"}

        # unauthenticated request should not be allowed (401 or 403)
        response = api_client.put("/api/v1/useful-info/", payload, format="json")
        assert response.status_code in (
            status.HTTP_401_UNAUTHORIZED,
            status.HTTP_403_FORBIDDEN,
        )

        # authenticated citizen should receive forbidden
        response = authenticated_client.put("/api/v1/useful-info/", payload, format="json")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_put_by_admin_persists(self, admin_client):
        """An administrator can create/update the record."""
        payload = {
            "city_hall_name": "Mairie de Test",
            "address_line1": "1 Rue Exemple",
            "address_line2": "",
            "postal_code": "75000",
            "city": "Novaville",
            "phone": "0123456789",
            "email": "contact@test.fr",
            "website": "https://novaville.example.com",
            "opening_hours": {"monday": "9-12,14-17"},
        }
        response = admin_client.put("/api/v1/useful-info/", payload, format="json")
        assert response.status_code == status.HTTP_200_OK
        for k, v in payload.items():
            assert response.data[k] == v

        # subsequent GET should return the same values
        get_resp = admin_client.get("/api/v1/useful-info/")
        assert get_resp.status_code == status.HTTP_200_OK
        for k, v in payload.items():
            assert get_resp.data[k] == v
