
# Testing

SofaWatch uses pytest for backend tests.

## Run the complete test suite

From the `backend` directory:

```bash
python -m pytest
```

### Run a specific test module
```bash
python -m pytest tests/services/test_show_import_service.py -v
```

### Run a specific test
```bash
python -m pytest tests/services/test_show_import_service.py::test_import_show_creates_new_show -v
```

## Test structure
Tests generally mirror the backend architecture:
```text
tests/
├── api/
├── jobs/
├── models/
├── providers/
├── repositories/
└── services/
```

### Repository tests
Verify database persistence and query behaviour.

### Service tests
Verify application and business logic.

### API tests
Verify HTTP responses, validation and dependency integration.

### Provider tests
Verify communication and response mapping for external metadata providers.

### Background job tests
Verify job persistence, execution, scheduling and failure handling.

## External services
Tests must not depend on live TMDB responses.
External HTTP calls are mocked so tests remain deterministic and can run offline.

## Test database
Tests use an isolated database configuration and must not modify the normal development or production database.