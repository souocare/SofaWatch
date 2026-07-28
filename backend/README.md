# SofaWatch Backend

Backend API and server-side services for SofaWatch.

SofaWatch is a self-hosted application for tracking TV shows and movies. The backend provides the local data layer, metadata integrations, personal library management, viewing progress tracking, and background synchronization used by SofaWatch clients.

## Tech Stack

- **Python 3.12+**
- **FastAPI** — REST API
- **SQLAlchemy** — ORM and persistence
- **Alembic** — database migrations
- **Pydantic** — validation and API schemas
- **SQLite** — default database
- **HTTPX** — external HTTP communication
- **pytest** — automated testing
- **Ruff** — linting and formatting

TMDB is currently used as the primary external metadata provider.

## Architecture

The backend follows a layered architecture:

```text
API Routes
    ↓
Services
    ↓
Repositories
    ↓
SQLAlchemy Models
    ↓
Database
```

External metadata integrations are isolated behind provider-specific components:

```text
External Provider
       ↓
Provider Client
       ↓
Provider Schemas
       ↓
Application Services
       ↓
Local Persistence
```

This keeps HTTP handling, business logic, persistence, and third-party integrations separated.

For more details, see the [backend architecture documentation](../docs/architecture/backend.md).

## Project Structure

```text
backend/
├── app/
│   ├── api/             # FastAPI routes and dependencies
│   ├── core/            # Application configuration
│   ├── db/              # Database configuration
│   ├── jobs/            # Background job infrastructure and handlers
│   ├── models/          # SQLAlchemy models
│   ├── providers/       # External metadata providers
│   ├── repositories/    # Persistence and database queries
│   ├── schemas/         # Pydantic schemas
│   └── services/        # Application and business logic
├── migrations/          # Alembic migrations
├── tests/               # Automated backend tests
├── alembic.ini
├── pyproject.toml
└── README.md
```

## Current Capabilities

The backend currently supports:

- TV show search through TMDB
- importing TV shows into the local database
- show, season, and episode metadata
- genres and television networks
- personal TV show library
- library tracking states
- episode watched/unwatched state
- custom viewing dates
- season and show progress calculation
- next episode detection
- manual metadata refresh
- periodic metadata synchronization
- persistent background job state and execution history
- manual background job execution
- local user association for library and viewing progress

Movies and additional application functionality will be added as development continues.

## Development Setup

From the `backend` directory, create and activate a virtual environment:

```bash
python -m venv .sofawatchvenv
source .sofawatchvenv/bin/activate
```

Install the project dependencies:

```bash
pip install -e .
```

Configure the required environment variables using the project's environment configuration.

Apply database migrations:

```bash
alembic upgrade head
```

Start the API:

```bash
uvicorn app.main:app --reload
```

For complete setup instructions, see [Development Setup](../docs/development/setup.md).

## API Documentation

FastAPI automatically generates interactive OpenAPI documentation while the backend is running.

By default:

```text
http://127.0.0.1:8000/docs
```

provides Swagger UI, and:

```text
http://127.0.0.1:8000/redoc
```

provides ReDoc.

See [API Overview](../docs/api/overview.md) for an overview of the available resources.

## Database

SQLite is the default database.

Database access is implemented using SQLAlchemy, while schema changes are managed through Alembic migrations.

Apply all pending migrations with:

```bash
alembic upgrade head
```

Create a migration after changing database models:

```bash
alembic revision --autogenerate -m "describe change"
```

Generated migrations should always be reviewed before being applied.

See:

- [Database Architecture](../docs/architecture/database.md)
- [Database Migrations](../docs/development/migrations.md)

## Metadata

TMDB is currently the primary metadata source.

Metadata is imported into the local database rather than being fetched directly by clients. This allows SofaWatch to maintain its own application state independently from external providers.

Synchronization currently covers:

- TV shows
- seasons
- episodes
- genres
- networks

Local metadata overrides, such as locally managed artwork paths, are preserved when external metadata is refreshed.

Ended and canceled TV shows are excluded from automatic metadata refreshes but can still be refreshed manually.

See [Metadata Synchronization](../docs/features/metadata-sync.md).

## Background Jobs

Recurring server-side tasks are handled by SofaWatch's background job system.

The system provides:

- registered job definitions
- scheduling
- persistent job state
- execution history
- execution duration
- failure information
- next-run tracking
- manual execution

The metadata synchronization job currently runs on an eight-hour schedule.

Start the background worker with:

```bash
python -m app.jobs.worker
```

A specific registered job can also be executed manually:

```bash
python -m app.jobs.run metadata_sync
```

See [Background Jobs](../docs/architecture/background-jobs.md).

## Testing

Run the complete backend test suite with:

```bash
python -m pytest
```

Run a specific module with:

```bash
python -m pytest tests/services/test_show_import_service.py -v
```

Tests cover API routes, services, repositories, providers, models, viewing progress, metadata synchronization, and background jobs.

External provider calls are mocked where appropriate so the test suite does not depend on live TMDB responses.

See [Testing](../docs/development/testing.md).

## Code Quality

Ruff is used for linting and formatting.

Check the backend:

```bash
ruff check .
```

Format the code:

```bash
ruff format .
```

Code should maintain the separation between API, service, repository, model, and provider layers.

## Documentation

Additional technical documentation is available in [`../docs`](../docs/).

Key documents include:

- [Architecture Overview](../docs/architecture/overview.md)
- [Backend Architecture](../docs/architecture/backend.md)
- [Database Architecture](../docs/architecture/database.md)
- [Background Jobs](../docs/architecture/background-jobs.md)
- [Development Setup](../docs/development/setup.md)
- [Testing](../docs/development/testing.md)
- [API Overview](../docs/api/overview.md)

Feature-specific documentation is available under [`docs/features`](../docs/features/).
