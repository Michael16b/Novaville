# Database Models Structure

This directory contains the database models and enumerations for the Novaville application.

## Organization

The models are organized into separate modules for better maintainability:

### 📁 `enums/`
Contains all enumeration types used across the application:

- **`role.py`**: User role enumeration (CITIZEN, ELECTED, AGENT, GLOBAL_ADMIN)
- **`problem_type.py`**: Problem types for reports (ROADS, LIGHTING, CLEANLINESS)
- **`report_status.py`**: Report status enumeration (RECORDED, IN_PROGRESS, RESOLVED)
- **`theme.py`**: Event theme enumeration (SPORT, CULTURE, CITIZENSHIP, ENVIRONMENT, OTHER)

### 📁 `models/`
Contains all database models organized by domain:

- **`user.py`**: Custom user model with role-based access control
- **`neighborhood.py`**: Neighborhood/District model
- **`report.py`**: Citizen reports about city issues
- **`survey.py`**: Survey-related models (Survey, SurveyOption, Vote)
- **`event.py`**: Event-related models (Event, ThemeEvent)

## Usage

All models and enums are re-exported from the main module, so you can import them as before:

```python
# Import models
from core.db.models import User, Neighborhood, Report, Survey, Event

# Import enums
from core.db.models import RoleEnum, ProblemTypeEnum, ReportStatusEnum

# Or import from specific modules if needed
from core.db.enums import RoleEnum
from core.db.models.user import User
```

## Benefits of This Structure

- ✅ **Better organization**: Each model has its own file, making it easier to find and maintain
- ✅ **Separation of concerns**: Enums are separated from models
- ✅ **Easier navigation**: Smaller files are easier to read and understand
- ✅ **Backward compatibility**: All imports remain the same thanks to re-exports
- ✅ **Scalability**: Easy to add new models without cluttering a single file
