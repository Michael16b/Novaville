# Novaville API - Test Suite

## Overview
Comprehensive test suite for the Novaville civic engagement platform API. Tests validate database models, authentication, authorization, and all API endpoints.

## Test Results
- **Total Tests:** 83
- **Passing:** 83 (100%)
- **Code Coverage:** 91%
- **Framework:** pytest 9.0.0 + pytest-django 4.8.0

## Test Organization

### Model Tests (`test_models.py`) - 18 tests
Tests for Django database models and their behavior:
- **User Model** (5 tests): Creation, roles, properties, string representation
- **Neighborhood Model** (3 tests): Creation, relationships, report counting
- **Report Model** (3 tests): Creation, status changes, ordering
- **Survey Model** (3 tests): Creation with options, active property
- **Vote Model** (2 tests): Creation, uniqueness constraint
- **Event Model** (2 tests): Creation, chronological ordering

### Authentication Tests (`test_auth.py`) - 11 tests
Tests for JWT authentication and role-based permissions:
- **Authentication Flow** (6 tests): Login, token refresh, authenticated requests
- **Permission System** (5 tests): Role-based access control (citizen, elected, agent, admin)

### API Endpoint Tests
Complete CRUD testing for all API endpoints:

#### Reports API (`test_api_reports.py`) - 9 tests
- List, create, retrieve, update, delete reports
- Status updates (staff only)
- Filtering by status and neighborhood

#### Surveys API (`test_api_surveys.py`) - 11 tests
- List, create, retrieve, update, delete surveys
- Active surveys endpoint
- Survey results with vote counts
- Vote creation and duplicate prevention

#### Events API (`test_api_events.py`) - 11 tests
- List, create, retrieve, update, delete events
- Event themes management
- Upcoming events endpoint
- Filtering by theme

#### Users & Neighborhoods API (`test_api_users.py`) - 13 tests
- User CRUD operations
- Profile management (/me/ endpoint)
- Neighborhood management
- Permission boundaries

### Integration Tests (`test_integration.py`) - 10 tests
End-to-end workflow validation:
- **Authentication Flow** (2 tests): Login and user info retrieval
- **Reports Flow** (2 tests): Create and manage reports
- **Surveys Flow** (1 test): Complete survey creation and voting process
- **Events Flow** (1 test): Event creation and viewing
- **Permissions** (4 tests): Basic permission rules enforcement

## Running Tests

### Quick Test Run
```bash
# Run all tests
docker compose exec backend pytest tests/ -q

# Run with verbose output
docker compose exec backend pytest tests/ -v

# Run specific test file
docker compose exec backend pytest tests/test_models.py -v

# Run specific test
docker compose exec backend pytest tests/test_models.py::TestUserModel::test_user_creation -v
```

### With Coverage Report
```bash
# Generate HTML coverage report
docker compose exec backend pytest tests/ --cov=. --cov-report=html

# View coverage in browser (generated at backend/htmlcov/index.html)
```

### Test Markers
```bash
# Run only unit tests
docker compose exec backend pytest tests/ -m unit

# Run only integration tests  
docker compose exec backend pytest tests/ -m integration

# Run slow tests
docker compose exec backend pytest tests/ -m slow
```

## Test Fixtures
Located in `tests/conftest.py`:

### Users
- `citizen_user` - Regular citizen user
- `elected_user` - Elected official (staff)
- `agent_user` - Municipal agent (staff)
- `admin_user` - Global administrator

### API Clients
- `api_client` - Unauthenticated client
- `authenticated_client` - Authenticated as citizen
- `elected_client` - Authenticated as elected official
- `admin_client` - Authenticated as admin

### Models
- `neighborhood` - Test neighborhood
- `theme` - Event theme
- `report` - Sample report
- `survey` - Sample survey
- `survey_with_options` - Survey with predefined options
- `event` - Sample event

## Sample Data for Development
Sample data scripts are located in `tests/fixtures/`:
- `create_sample_data.py` - Comprehensive sample data for manual testing
- `create_initial_data.py` - Minimal initial data

```bash
# Load sample data
docker compose exec backend python tests/fixtures/create_sample_data.py
```

## Key Technical Details

### Permission Classes
Custom permission classes in `api/v1/permissions.py`:
- `IsOwnerOrStaff` - Owner or staff can access
- `IsStaffOrReadOnly` - Read: all authenticated, Write: staff only
- `IsAdminOrReadOnly` - Read: all authenticated, Write: admin only
- `IsElectedOrAgentOrAdmin` - Elected officials, agents, and admins

### Role System
Four user roles (defined in `RoleEnum`):
- `CITIZEN` - Regular users
- `ELECTED` - Elected officials (staff access)
- `AGENT` - Municipal agents (staff access)
- `GLOBAL_ADMIN` - System administrators (superuser)

### API Behavior
- All list endpoints return paginated results (PAGE_SIZE=20)
- Create endpoints use specialized CreateSerializers
- JWT tokens required for all authenticated endpoints
- Dynamic permissions via `get_permissions()` methods in viewsets

## Common Patterns

### Testing Create Operations
```python
def test_create_resource(self, elected_client):
    response = elected_client.post(
        "/api/v1/resource/",
        {"field": "value"},
        format="json"
    )
    assert response.status_code == status.HTTP_201_CREATED
    assert response.data["id"] is not None
```

### Testing Pagination
```python
def test_list_paginated(self, authenticated_client):
    response = authenticated_client.get("/api/v1/resource/")
    assert response.status_code == status.HTTP_200_OK
    # Check if paginated
    if "results" in response.data:
        data = response.data["results"]
    else:
        data = response.data
```

### Testing Permissions
```python
def test_forbidden_action(self, authenticated_client):
    response = authenticated_client.post("/api/v1/admin-action/", {})
    assert response.status_code == status.HTTP_403_FORBIDDEN
```

## Troubleshooting

### Test Database
Tests use `pytest-django` with `--reuse-db` and `--nomigrations` for speed.

### Common Issues
1. **Import Errors**: Clear Python cache: `docker compose exec backend find /app -type d -name __pycache__ -exec rm -rf {} +`
2. **Stale Data**: Tests use Django's transaction rollback - no manual cleanup needed
3. **Permission Failures**: Verify user fixtures have correct roles and `is_staff` flags

## Coverage Goals
- **Target**: >90% coverage on core API code
- **Current**: 91% overall coverage
- **Focus Areas**: 
  - API viewsets: 90-98%
  - Models: 92-94%
  - Serializers: 94-97%
  - Permissions: 46% (many edge cases not yet covered)

## CI/CD Integration
```bash
# Run tests in CI pipeline
docker compose exec backend pytest tests/ --cov=. --cov-report=xml --junitxml=pytest-report.xml
```

## Next Steps
1. Add more permission edge case tests to reach >80% coverage on permissions.py
2. Add stress tests for concurrent voting
3. Add API rate limiting tests
4. Add tests for file upload functionality (once implemented)
