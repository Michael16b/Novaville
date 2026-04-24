"""Tests for Reports API endpoints"""
import datetime
import pytest
from rest_framework import status
from core.db.models import Report, ProblemTypeEnum, ReportStatusEnum

pytestmark = pytest.mark.django_db


class TestReportsAPI:
    """Tests for reports endpoints"""

    def test_list_reports_public(self, api_client, report):
        """Test anonymous users can list reports."""
        response = api_client.get("/api/v1/reports/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
    
    def test_list_reports(self, authenticated_client, report):
        """Test listing reports"""
        response = authenticated_client.get("/api/v1/reports/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1

    def test_list_reports_includes_neighborhood_only_reports(
        self,
        authenticated_client,
        citizen_user,
        neighborhood,
    ):
        """Test listing also returns reports that only have a neighborhood."""
        legacy_report = Report.objects.create(
            user=citizen_user,
            title="Legacy neighborhood report",
            problem_type=ProblemTypeEnum.ROADS,
            description="Legacy report",
            neighborhood=neighborhood,
        )

        response = authenticated_client.get("/api/v1/reports/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        matching_reports = [item for item in results if item["id"] == legacy_report.id]
        assert len(matching_reports) == 1
        assert matching_reports[0]["address"] == ""
        assert matching_reports[0]["neighborhood"] == neighborhood.id
    
    def test_create_report(self, authenticated_client, neighborhood):
        """Test creating a report"""
        data = {
            "title": "Street cleanliness issue",
            "problem_type": "CLEANLINESS",
            "description": "Trash on the street",
            "address": "15 avenue Victor Hugo",
            "neighborhood": neighborhood.id
        }
        response = authenticated_client.post("/api/v1/reports/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["problem_type"] == "CLEANLINESS"
        assert response.data["address"] == "15 avenue Victor Hugo"

    def test_create_report_with_neighborhood_only(
        self,
        authenticated_client,
        neighborhood,
    ):
        """Test creating a report without exact address when a neighborhood is provided."""
        data = {
            "title": "Street cleanliness issue",
            "problem_type": "CLEANLINESS",
            "description": "Trash on the street",
            "address": "",
            "neighborhood": neighborhood.id,
        }

        response = authenticated_client.post("/api/v1/reports/", data, format="json")

        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["address"] == ""
        assert response.data["neighborhood"] == neighborhood.id

    def test_create_report_requires_address_or_neighborhood(self, authenticated_client):
        """Test creating a report requires an exact address or a neighborhood."""
        data = {
            "title": "Street cleanliness issue",
            "problem_type": "CLEANLINESS",
            "description": "Trash on the street",
            "address": "",
        }
        response = authenticated_client.post("/api/v1/reports/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "address" in response.data
        assert "neighborhood" in response.data

    def test_create_report_rejects_malformed_exact_address(
        self,
        authenticated_client,
        neighborhood,
    ):
        """Test malformed exact addresses are still rejected when provided."""
        data = {
            "title": "Street cleanliness issue",
            "problem_type": "CLEANLINESS",
            "description": "Trash on the street",
            "address": "avenue Victor Hugo",
            "neighborhood": neighborhood.id,
        }

        response = authenticated_client.post("/api/v1/reports/", data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "address" in response.data
    
    def test_retrieve_report(self, authenticated_client, report):
        """Test retrieving a specific report"""
        response = authenticated_client.get(f"/api/v1/reports/{report.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == report.id

    def test_retrieve_report_public(self, api_client, report):
        """Test anonymous users can retrieve a specific report."""
        response = api_client.get(f"/api/v1/reports/{report.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == report.id
    
    def test_update_report(self, authenticated_client, report):
        """Test updating a report (only author can update)"""
        data = {
            "description": "Updated description",
            "address": "18 boulevard Saint-Germain",
        }
        response = authenticated_client.patch(
            f"/api/v1/reports/{report.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["description"] == "Updated description"
        assert response.data["address"] == "18 boulevard Saint-Germain"
    
    def test_delete_report(self, authenticated_client, report):
        """Test deleting a report"""
        response = authenticated_client.delete(f"/api/v1/reports/{report.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not Report.objects.filter(id=report.id).exists()
    
    def test_update_report_status_by_staff(self, elected_client, report):
        """Test staff can update report status"""
        response = elected_client.post(
            f"/api/v1/reports/{report.id}/update_status/",
            {"status": "IN_PROGRESS"},
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "IN_PROGRESS"
        
        report.refresh_from_db()
        assert report.status == ReportStatusEnum.IN_PROGRESS

    def test_update_report_status_requires_status(self, elected_client, report):
        """Test staff must provide status when updating"""
        response = elected_client.post(
            f"/api/v1/reports/{report.id}/update_status/",
            {},
            format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Status is required" in str(response.data)
    
    def test_citizen_cannot_update_status_of_other_report(self, other_citizen_client, report):
        """Test non-owner citizen cannot update report status"""
        response = other_citizen_client.post(
            f"/api/v1/reports/{report.id}/update_status/",
            {"status": "RESOLVED"},
            format="json",
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_update_report_status_invalid_value(self, elected_client, report):
        """Test elected official cannot set an invalid status value"""
        response = elected_client.post(
            f"/api/v1/reports/{report.id}/update_status/",
            {"status": "NOT_A_VALID_STATUS"},
            format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Invalid status" in str(response.data)
    
    def test_filter_reports_by_status(self, authenticated_client, citizen_user, neighborhood):
        """Test filtering reports by status"""
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Report 1",
            address="1 rue A",
            status=ReportStatusEnum.RECORDED,
            neighborhood=neighborhood
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Report 2",
            address="2 rue B",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=neighborhood
        )
        
        response = authenticated_client.get("/api/v1/reports/?status=IN_PROGRESS")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert all(r["status"] == "IN_PROGRESS" for r in results)
    
    def test_filter_reports_by_neighborhood(self, authenticated_client, citizen_user, neighborhood):
        """Test filtering reports by neighborhood remains available for legacy clients."""
        other_neighborhood = neighborhood.__class__.objects.create(
            name="Other",
            postal_code="75002"
        )

        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Report in my neighborhood",
            address="3 rue C",
            neighborhood=neighborhood
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Report in other neighborhood",
            address="4 rue D",
            neighborhood=other_neighborhood
        )
        
        response = authenticated_client.get(f"/api/v1/reports/?neighborhood={neighborhood.id}")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert all(r["neighborhood"] == neighborhood.id for r in results)

    def test_filter_reports_by_address(self, authenticated_client, citizen_user, neighborhood):
        """Test filtering reports by a partial address."""
        matching_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Report on Victor Hugo",
            address="15 avenue Victor Hugo",
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Another report elsewhere",
            address="9 rue des Fleurs",
            neighborhood=neighborhood,
        )

        response = authenticated_client.get("/api/v1/reports/?address=victor")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        result_ids = [r["id"] for r in results]

        assert matching_report.id in result_ids
        assert all("victor" in r["address"].lower() for r in results)

    def test_filter_reports_with_multiple_attributes(self, authenticated_client, citizen_user, neighborhood):
        """Test combining multiple report filters in one request"""
        matching_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Multi attr report",
            address="5 rue Victor Hugo",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Wrong status",
            address="6 rue Victor Hugo",
            status=ReportStatusEnum.RECORDED,
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Wrong problem type",
            address="7 rue Victor Hugo",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Wrong address",
            address="8 rue des Lilas",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=neighborhood,
        )

        response = authenticated_client.get(
            "/api/v1/reports/?status=IN_PROGRESS&problem_type=ROADS&address=victor"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        result_ids = [r["id"] for r in results]

        assert matching_report.id in result_ids
        for report_data in results:
            assert report_data["status"] == "IN_PROGRESS"
            assert report_data["problem_type"] == "ROADS"
            assert "victor" in report_data["address"].lower()

    def test_non_owner_citizen_cannot_update_report(self, other_citizen_client, report):
        """Test a non-owner citizen receives 403 when updating another user's report"""
        response = other_citizen_client.patch(
            f"/api/v1/reports/{report.id}/",
            {"description": "Should not work"},
            format="json",
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_non_owner_citizen_cannot_full_update_report(self, other_citizen_client, report, neighborhood):
        """Test a non-owner citizen receives 403 on full PUT of another user's report"""
        response = other_citizen_client.put(
            f"/api/v1/reports/{report.id}/",
            {
                "problem_type": "CLEANLINESS",
                "description": "Should not work",
                "neighborhood": neighborhood.id,
            },
            format="json",
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_non_owner_citizen_cannot_delete_report(self, other_citizen_client, report):
        """Test a non-owner citizen receives 403 when deleting another user's report"""
        response = other_citizen_client.delete(f"/api/v1/reports/{report.id}/")
        assert response.status_code == status.HTTP_403_FORBIDDEN
        assert Report.objects.filter(id=report.id).exists()

    def test_owner_citizen_can_update_own_report_status(self, authenticated_client, report):
        """Test that the report owner (citizen) can update the status of their own report"""
        response = authenticated_client.post(
            f"/api/v1/reports/{report.id}/update_status/",
            {"status": "IN_PROGRESS"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "IN_PROGRESS"
        report.refresh_from_db()
        assert report.status == ReportStatusEnum.IN_PROGRESS

    def test_search_filter(self, authenticated_client, citizen_user, neighborhood):
        """Test full-text search across report description"""
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Unique search term xyzzy",
            address="9 rue I",
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Other report without the term",
            address="10 rue J",
            neighborhood=neighborhood,
        )

        response = authenticated_client.get("/api/v1/reports/?search=xyzzy")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert len(results) >= 1
        assert all("xyzzy" in r["description"] for r in results)

    def test_created_after_filter(self, authenticated_client, citizen_user, neighborhood):
        """Test filtering reports created after a given datetime"""
        old_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Old report",
            address="11 rue K",
            neighborhood=neighborhood,
        )
        # Back-date the old report
        Report.objects.filter(id=old_report.id).update(
            created_at=datetime.datetime(2020, 1, 1, tzinfo=datetime.timezone.utc)
        )

        new_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="New report",
            address="12 rue L",
            neighborhood=neighborhood,
        )

        cutoff = "2021-01-01T00:00:00Z"
        response = authenticated_client.get(f"/api/v1/reports/?created_after={cutoff}")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        result_ids = [r["id"] for r in results]
        assert new_report.id in result_ids
        assert old_report.id not in result_ids

    def test_created_before_filter(self, authenticated_client, citizen_user, neighborhood):
        """Test filtering reports created before a given datetime"""
        old_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Old report for before filter",
            address="13 rue M",
            neighborhood=neighborhood,
        )
        Report.objects.filter(id=old_report.id).update(
            created_at=datetime.datetime(2020, 6, 1, tzinfo=datetime.timezone.utc)
        )

        new_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="New report for before filter",
            address="14 rue N",
            neighborhood=neighborhood,
        )

        cutoff = "2021-01-01T00:00:00Z"
        response = authenticated_client.get(f"/api/v1/reports/?created_before={cutoff}")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        result_ids = [r["id"] for r in results]
        assert old_report.id in result_ids
        assert new_report.id not in result_ids

    def test_legacy_report_with_neighborhood_only_is_still_readable(
        self,
        authenticated_client,
        citizen_user,
        neighborhood,
    ):
        """Test legacy reports without exact address still exist and remain readable."""
        legacy_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Legacy report",
            neighborhood=neighborhood,
        )

        response = authenticated_client.get(f"/api/v1/reports/{legacy_report.id}/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["neighborhood"] == neighborhood.id
        assert response.data["address"] == ""
