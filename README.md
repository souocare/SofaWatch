# SofaWatch

**SofaWatch** is a self-hosted companion application for tracking TV shows and movies across web, iOS, and Android.

The goal is to provide a private, self-hosted alternative for managing what you watch, keeping track of your progress, discovering what to watch next, and maintaining your own viewing history while keeping application data under your control.

> [!NOTE]
> SofaWatch is currently under active development. Things are being build. 

## Features

### Currently implemented

The backend currently supports:

- TV show search through TMDB
- Importing TV shows into the local database
- Show, season, and episode metadata
- Genres and television networks
- Personal TV show library
- Library tracking states
- Watched and unwatched episode tracking
- Viewing dates
- Season and show progress
- Next episode detection
- Manual metadata refresh
- Periodic metadata synchronization
- Persistent background jobs and execution history
- User-scoped library and viewing progress

### Planned

SofaWatch is intended to grow into a complete TV and movie companion, including:

- Movie tracking
- Native iOS and Android applications
- Responsive web application
- Personalized home and discovery experiences
- Upcoming episode tracking
- Ratings and favorites
- Viewing statistics and history
- Recommendations
- Notifications
- Multi-user support
- Authentication and first-run administrator setup
- Internationalization
- Additional metadata and service integrations

The exact scope may evolve as the project develops.

## Architecture

SofaWatch is designed around a self-hosted backend API consumed by web and native clients.

```text
                    ┌─────────────────────┐
                    │   SofaWatch Client  │
                    │ Web / iOS / Android │
                    └──────────┬──────────┘
                               │
                          HTTP / REST
                               │
                    ┌──────────▼──────────┐
                    │   FastAPI Backend   │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
        ┌─────▼─────┐   ┌──────▼──────┐  ┌─────▼─────┐
        │  SQLite   │   │    TMDB     │  │Background │
        │ Database  │   │  Metadata   │  │   Jobs    │
        └───────────┘   └─────────────┘  └───────────┘
```

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

External integrations are isolated behind provider components rather than being accessed directly from API routes or persistence code.

More information is available in the [architecture documentation](docs/architecture/overview.md).

## Tech Stack

### Backend

- Python
- FastAPI
- SQLAlchemy
- Alembic
- Pydantic
- SQLite
- HTTPX
- pytest
- Ruff

### Metadata

- TMDB — current TV metadata provider
- TVDB — planned integration

### Frontend

The client is planned around:

- React Native
- Expo
- Web, iOS, and Android targets

Frontend development is the next major phase of the project.

## Project Structure

```text
SofaWatch/
├── backend/       # FastAPI API and server-side logic
├── frontend/      # React Native / Expo client
├── docs/          # Technical and feature documentation
├── scripts/       # Development and maintenance scripts
├── .env.example   # Example environment configuration
├── LICENSE
└── README.md
```

For backend-specific information, see [`backend/README.md`](backend/README.md).

For technical documentation, see [`docs/README.md`](docs/README.md).

## Getting Started

SofaWatch is not yet considered production-ready, but the backend can already be run locally for development.

Clone the repository:

```bash
git clone https://github.com/souocare/SofaWatch.git
cd SofaWatch/backend
```

Create and activate a Python virtual environment:

```bash
python -m venv .sofawatchvenv
source .sofawatchvenv/bin/activate
```

Install the backend:

```bash
pip install -e .
```

Configure the required environment variables using `.env.example`, then apply the database migrations:

```bash
alembic upgrade head
```

Start the development API:

```bash
uvicorn app.main:app --reload
```

For complete setup instructions, see the [Development Setup](docs/development/setup.md).

## API Documentation

FastAPI automatically generates interactive OpenAPI documentation while the backend is running.

By default:

```text
http://127.0.0.1:8000/docs
```

provides Swagger UI, while:

```text
http://127.0.0.1:8000/redoc
```

provides ReDoc.

See the [API Overview](docs/api/overview.md) for an overview of the available resources.

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

- [Database Architecture](docs/architecture/database.md)
- [Database Migrations](docs/development/migrations.md)

## Metadata

TMDB is currently the primary metadata source.

Metadata is imported into the local database rather than being fetched directly by clients. This allows SofaWatch to maintain its own application state independently from external providers.

Synchronization currently covers:

- TV shows
- Seasons
- Episodes
- Genres
- Networks

Local metadata overrides, such as locally managed artwork paths, are preserved when external metadata is refreshed.

Ended and canceled TV shows are excluded from automatic metadata refreshes but can still be refreshed manually.

See [Metadata Synchronization](docs/features/metadata-sync.md) for more information.

## Background Jobs

SofaWatch includes a persistent background job system for recurring server-side work.

Jobs track their:

- Status
- Schedule
- Last execution
- Execution duration
- Next execution
- Errors
- Execution history

The first scheduled job handles TV metadata synchronization.

The scheduler checks for metadata synchronization every eight hours. Automatic synchronization respects the metadata refresh policy and does not force updates for shows that should not be refreshed.

Ended and canceled TV shows are excluded from automatic metadata refreshes but remain available for manual refresh.

See [Background Jobs](docs/architecture/background-jobs.md) for details.

## Testing

The backend has automated tests covering:

- API routes
- Services
- Repositories
- Models
- External providers
- Library management
- Viewing progress
- Metadata synchronization
- Background job execution and scheduling

Run the complete test suite from the `backend` directory:

```bash
python -m pytest
```

External provider calls are mocked where appropriate so the test suite does not depend on live TMDB responses.

See [Testing](docs/development/testing.md) for more information.

## Development

SofaWatch follows a layered backend architecture intended to keep responsibilities separated and the codebase maintainable.

In general:

```text
Routes
  ↓
Services
  ↓
Repositories
  ↓
Database
```

External APIs are accessed through provider abstractions:

```text
Services
  ↓
Providers
  ↓
External APIs
```

Recurring tasks are handled independently through the background job infrastructure.

Ruff is used for linting and formatting:

```bash
ruff check .
```

```bash
ruff format .
```

Additional development documentation is available under [`docs/development/`](docs/development/).

## Documentation

Project documentation lives under [`docs/`](docs/).

Useful starting points include:

- [Documentation Index](docs/README.md)
- [Architecture Overview](docs/architecture/overview.md)
- [Backend Architecture](docs/architecture/backend.md)
- [Database Architecture](docs/architecture/database.md)
- [Background Jobs](docs/architecture/background-jobs.md)
- [API Overview](docs/api/overview.md)
- [Development Setup](docs/development/setup.md)
- [Testing](docs/development/testing.md)
- [Database Migrations](docs/development/migrations.md)

Feature-specific documentation is available under [`docs/features/`](docs/features/).

## Project Status

SofaWatch is in active development.

Development so far has focused on building the backend foundation:

```text
TV metadata
      ↓
Local database
      ↓
Personal library
      ↓
Viewing progress
      ↓
Metadata synchronization
      ↓
Background jobs
```

The next major development phase is the frontend, starting with the application foundation and integration with the existing backend API.

SofaWatch should currently be considered development software rather than a production-ready release.

## Contributing

SofaWatch is still evolving, so APIs, database models, and project structure may change as development continues.

Issues, ideas, bug reports, and contributions are welcome.

Technical documentation is available under [`docs/`](docs/), and backend-specific development information is available in [`backend/README.md`](backend/README.md).


## Acknowledgements

SofaWatch would not exist without the projects and services that inspired and support its development.

### TMDB

SofaWatch uses the TMDB API as its current source for TV show, season, episode, genre, network, and related metadata.
This product uses the TMDB API but is not endorsed or certified by TMDB.
TMDB data, images, and other content remain subject to TMDB's own terms and policies.

### Inspiration

SofaWatch has been inspired by existing TV and movie tracking applications, particularly:

- **TV Time** — for its approach to personal TV and movie tracking, viewing progress, discovery, and the overall companion experience around watching content.
- **[Sofa](https://github.com/jakejarvis/sofa)** — for its self-hosted approach and several ideas around application structure, background jobs, library management, and the experience of running your own media tracking service.

SofaWatch is an independent project and is not affiliated with, endorsed by, or associated with TMDB, TV Time, or Sofa.

Special thanks to the developers and communities behind these projects for helping inspire SofaWatch.


## License

SofaWatch is open-source software licensed under the [MIT License](LICENSE).

You are free to use, copy, modify, distribute, sublicense, and build upon SofaWatch, including for commercial purposes, subject to the terms of the license.

Copyright (c) 2026 Gonçalo Fonseca.