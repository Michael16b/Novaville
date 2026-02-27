"""Tests for Reports API endpoints"""
import pytest
from rest_framework import status
from core.db.models import Report, ProblemTypeEnum, ReportStatusEnum

pytestmark = pytest.mark.django_db


class TestReportsAPI:
    """Tests for reports endpoints"""
    
    def test_list_reports(self, authenticated_client, report):
        """Test listing reports"""
        response = authenticated_client.get("/api/v1/reports/")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert len(results) >= 1
    
    def test_create_report(self, authenticated_client, neighborhood):
        """Test creating a report"""
        data = {
            "problem_type": "CLEANLINESS",
            "description": "Trash on the street",
            "neighborhood": neighborhood.id
        }
        response = authenticated_client.post("/api/v1/reports/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["problem_type"] == "CLEANLINESS"
    
    def test_retrieve_report(self, authenticated_client, report):
        """Test retrieving a specific report"""
        response = authenticated_client.get(f"/api/v1/reports/{report.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == report.id
    
    def test_update_report(self, authenticated_client, report):
        """Test updating a report (only author can update)"""
        data = {"description": "Updated description"}
        response = authenticated_client.patch(
            f"/api/v1/reports/{report.id}/",
            data,
            format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["description"] == "Updated description"
    
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
    
    def test_citizen_cannot_update_status(self, authenticated_client, report):
        """Test citizen cannot update report status"""
        response = authenticated_client.post(
            f"/api/v1/reports/{report.id}/update_status/",
            {"status": "RESOLVED"},
            format="json"
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
            status=ReportStatusEnum.RECORDED,
            neighborhood=neighborhood
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Report 2",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=neighborhood
        )
        
        response = authenticated_client.get("/api/v1/reports/?status=IN_PROGRESS")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert all(r["status"] == "IN_PROGRESS" for r in results)
    
    def test_filter_reports_by_neighborhood(self, authenticated_client, citizen_user, neighborhood):
        """Test filtering reports by neighborhood"""
        other_neighborhood = neighborhood.__class__.objects.create(
            name="Other",
            postal_code="75002"
        )
        
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Report in my neighborhood",
            neighborhood=neighborhood
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Report in other neighborhood",
            neighborhood=other_neighborhood
        )
        
        response = authenticated_client.get(f"/api/v1/reports/?neighborhood={neighborhood.id}")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        assert all(r["neighborhood"] == neighborhood.id for r in results)

    def test_filter_reports_with_multiple_attributes(self, authenticated_client, citizen_user, neighborhood):
        """Test combining multiple report filters in one request"""
        other_neighborhood = neighborhood.__class__.objects.create(
            name="Other Multi",
            postal_code="75003"
        )

        matching_report = Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Multi attr report",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Wrong status",
            status=ReportStatusEnum.RECORDED,
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.LIGHTING,
            description="Wrong problem type",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=neighborhood,
        )
        Report.objects.create(
            user=citizen_user,
            problem_type=ProblemTypeEnum.ROADS,
            description="Wrong neighborhood",
            status=ReportStatusEnum.IN_PROGRESS,
            neighborhood=other_neighborhood,
        )

        response = authenticated_client.get(
            f"/api/v1/reports/?status=IN_PROGRESS&problem_type=ROADS&neighborhood={neighborhood.id}"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get('results', response.data)
        result_ids = [r["id"] for r in results]

        assert matching_report.id in result_ids
        for report_data in results:
            assert report_data["status"] == "IN_PROGRESS"
            assert report_data["problem_type"] == "ROADS"
            assert report_data["neighborhood"] == neighborhood.id
