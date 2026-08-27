# SofaWatch Backend

The SofaWatch backend is the server-side application responsible for persistence, business rules, authentication, metadata integration, background processing, administration, and the REST API used by SofaWatch clients.

It is designed for a self-hosted deployment model and uses SQLite as its intended database.

> [!NOTE]
> SofaWatch is under active development. API contracts, configuration, and internal structure may continue to evolve before the first stable release.

## Tech Stack

- Python 3.12+
- FastAPI
- SQLAlchemy
- Pydantic / pydantic-settings
- Alembic
- SQLite
- HTTPX
- Argon2 password hashing
- JWT access tokens
- pytest
- Ruff

TMDB is currently the primary external metadata provider. TVDB support is planned, but TVDB is not currently an active metadata provider.

---

## Architecture

The backend follows a layered architecture intended to keep HTTP handling, business rules, persistence, and third-party integrations separated.

```text
HTTP Request
     |
     v
API Routes / Dependencies
     |
     v
Services
     |
     v
Repositories
     |
     v
SQLAlchemy Models
     |
     v
SQLite
```

External integrations are kept behind provider-specific components:

```text
Application Services
        |
        v
Provider Client
        |
        v
Provider Schemas / Mapping
        |
        v
External API
```

The backend is the source of truth for SofaWatch business rules and persisted application state.

The main layers have distinct responsibilities:

- **API** — HTTP routing, request/response schemas, authentication dependencies, authorization, status codes, and safe API error mapping.
- **Services** — business rules, application workflows, orchestration, cross-repository operations, and provider coordination.
- **Repositories** — persistence operations, database queries, and user-scoped data access.
- **Models** — SQLAlchemy persistence models, relationships, and database constraints.
- **Providers** — external API communication, provider-specific schemas, error handling, and mapping.

This separation should be preserved when adding new functionality.

See [Backend Architecture](../docs/architecture/backend.md).

---

## Project Structure

```text
backend/
├── app/
│   ├── api/
│   │   ├── routes/          # FastAPI route modules
│   │   ├── dependencies.py  # Dependency injection and auth dependencies
│   │   └── router.py        # /api/v1 router composition
│   ├── core/                # Configuration, logging and core infrastructure
│   ├── db/                  # SQLAlchemy engine and database sessions
│   ├── jobs/                # Background jobs and worker
│   ├── models/              # SQLAlchemy models
│   ├── providers/           # External metadata providers
│   ├── repositories/        # Persistence layer
│   ├── schemas/             # Pydantic schemas
│   ├── services/            # Business/application services
│   └── main.py              # FastAPI application
├── data/                    # Local application data
├── migrations/              # Alembic migrations
├── tests/                   # Automated backend tests
├── alembic.ini
├── pyproject.toml
└── README.md
```

---

## Development Setup

All commands below assume the current directory is `backend/`.

### Python

SofaWatch requires Python 3.12 or newer.

Create and activate a virtual environment if needed:

```bash
python -m venv .sofawatchvenv
source .sofawatchvenv/bin/activate
```

If the project virtual environment is stored at the repository root:

```bash
source ../.sofawatchvenv/bin/activate
```

Install the backend and development dependencies:

```bash
pip install -e ".[dev]"
```

Apply database migrations:

```bash
alembic upgrade head
```

Start the API:

```bash
uvicorn app.main:app \
  --reload \
  --host 0.0.0.0 \
  --port 8000
```

The API will normally be available at:

```text
http://127.0.0.1:8000
```

Run the background worker in a separate terminal:

```bash
python -m app.jobs.worker
```

See [Development Setup](../docs/development/setup.md).

---

## Configuration

Backend configuration is defined through `app/core/config.py` using `pydantic-settings`.

Configuration values use the `SOFAWATCH_` environment variable prefix. The backend reads the repository-level `.env` file.

For example:

```text
SOFAWATCH_SECRET_KEY=replace-with-a-secure-random-secret
SOFAWATCH_TMDB_API_TOKEN=your-tmdb-token
```

### Application

| Setting | Default | Purpose |
| --- | --- | --- |
| `SOFAWATCH_APP_NAME` | `SofaWatch` | Application name |
| `SOFAWATCH_ENVIRONMENT` | `development` | Runtime environment |
| `SOFAWATCH_DEBUG` | `false` | Debug mode |
| `SOFAWATCH_API_HOST` | `0.0.0.0` | API bind host |
| `SOFAWATCH_API_PORT` | `8000` | API port |

### Storage and Database

| Setting | Default | Purpose |
| --- | --- | --- |
| `SOFAWATCH_DATABASE_URL` | `sqlite:///./data/sofawatch.db` | SQLAlchemy database URL |
| `SOFAWATCH_DATA_STORAGE_PATH` | `./data` | Application data directory |
| `SOFAWATCH_IMAGE_STORAGE_PATH` | `./data/images` | Local image storage |

### Authentication

| Setting | Default | Purpose |
| --- | --- | --- |
| `SOFAWATCH_SECRET_KEY` | required | Authentication/server secret |
| `SOFAWATCH_ACCESS_TOKEN_EXPIRE_MINUTES` | `15` | Access-token lifetime |
| `SOFAWATCH_SESSION_IDLE_EXPIRE_DAYS` | `180` | Persistent session idle lifetime |

`SOFAWATCH_SECRET_KEY` must contain at least 32 characters. Secrets should never be committed to the repository.

### Languages

| Setting | Default |
| --- | --- |
| `SOFAWATCH_DEFAULT_LANGUAGE` | `en-US` |
| `SOFAWATCH_SUPPORTED_LANGUAGES` | `en-US,pt-PT` |

Full application localization is still planned.

### TMDB

| Setting | Default |
| --- | --- |
| `SOFAWATCH_TMDB_API_TOKEN` | unset |
| `SOFAWATCH_TMDB_BASE_URL` | `https://api.themoviedb.org/3` |
| `SOFAWATCH_TMDB_IMAGE_BASE_URL` | `https://image.tmdb.org/t/p` |
| `SOFAWATCH_TMDB_TIMEOUT_SECONDS` | `20` |

### Metadata Refresh

```text
SOFAWATCH_METADATA_REFRESH_DAYS=7
```

This controls the normal metadata refresh age used by synchronization logic.

### CORS

Production CORS origins can be configured using:

```text
SOFAWATCH_CORS_ORIGINS=https://example.com,https://another.example.com
```

In development, the API accepts localhost and `127.0.0.1` HTTP origins on arbitrary ports. In non-development environments, the explicitly configured CORS origin list is used.

### Reserved TVDB Configuration

Configuration currently contains placeholders for future TVDB integration:

```text
SOFAWATCH_TVDB_API_KEY
SOFAWATCH_TVDB_PIN
SOFAWATCH_TVDB_BASE_URL
```

Their presence does **not** mean that TVDB metadata integration is currently implemented.

---

## API

The application API is versioned under:

```text
/api/v1
```

Most application resources require an authenticated SofaWatch user. Authentication and bootstrap routes remain publicly reachable where required.

Current API areas include:

- Authentication
- Users
- Security
- Shows
- Seasons
- Episodes
- Movies
- Genres
- Library
- Search
- Explore
- Statistics
- Images
- Background Jobs
- Server administration

### API Documentation

Swagger UI:

```text
http://127.0.0.1:8000/docs
```

ReDoc:

```text
http://127.0.0.1:8000/redoc
```

See [API Overview](../docs/api/overview.md).

### Error Handling

Application errors are mapped to safe API responses through centralized exception handlers.

Routes should avoid leaking implementation details, provider internals, secrets, or raw exceptions to clients.

---

## Authentication

SofaWatch uses real multi-user authentication. The old fixed/local-user model has been removed.

### Passwords

Passwords are hashed using Argon2. Plaintext passwords must never be persisted or logged.

### Access Tokens

Short-lived access tokens are used for authenticated API access. The default lifetime is 15 minutes.

Access tokens are intentionally not used as long-lived persistent credentials.

### Web Sessions

Web authentication uses persistent server-side sessions.

The browser receives a session credential through the `sofawatch_session` cookie, configured as:

- HttpOnly
- SameSite=Lax
- Path=/
- Secure in production

The browser can restore an authenticated Web session and receive a fresh short-lived access token without exposing the persistent session credential to JavaScript.

### Mobile Sessions

Native clients use:

```text
short-lived access token
        +
rotating refresh credential
```

Successful refresh rotates the persistent credential and invalidates the previous one.

Persistent authentication credentials are stored server-side as hashes.

### Unified Authentication

Protected API routes resolve the authenticated user through backend authentication dependencies.

Bearer authentication and Web session authentication resolve to the same user model.

Authorization must always be enforced by the backend rather than relying on hidden frontend controls.

### Logout

SofaWatch supports current Web-session logout, current Mobile-session logout, and revocation of all sessions belonging to the current user.

### First-Run Setup

A new installation without users enters setup mode.

The first account created is a real persistent SofaWatch user and automatically becomes an Administrator.

After the first user exists, initial setup can no longer be used. The setup flow also protects against concurrent creation of multiple initial administrators.

### Registration

Public registration is controlled by the global **Open Registration** security setting and is disabled by default.

When registration is disabled, the backend rejects public registration attempts regardless of frontend behavior.

### Password Recovery

Regular-user recovery uses random, short-lived, user-bound, hashed, single-use recovery credentials.

Completing password recovery invalidates existing sessions for the affected user.

Administrator recovery is also available directly on the server:

```bash
python -m app.admin.reset_password <username-or-email>
```

The new password is requested interactively and must never be supplied as a command-line argument.

### Mobile-to-Web Handoff

Authenticated clients can create a short-lived handoff credential that allows SofaWatch Web to establish its own Web session.

Handoff credentials are temporary, user-bound, single-use, and separate from access and refresh credentials.

---

## Authorization

Administrative functionality is protected by backend authorization. Frontend visibility is not considered a security boundary.

User-scoped resources such as Library, progress, history, ratings, and sessions must remain scoped to the authenticated user.

---

## Database

SofaWatch uses SQLite.

SQLite is the intended database for the self-hosted application and is not merely a development placeholder.

The default database URL is:

```text
sqlite:///./data/sofawatch.db
```

Database access uses SQLAlchemy.

### Foreign Keys

SQLite foreign-key enforcement is explicitly enabled:

```sql
PRAGMA foreign_keys=ON;
```

This behavior should also remain enabled in tests.

### Internal IDs

Once external media is imported, SofaWatch uses its own internal entity IDs.

Provider identifiers such as TMDB IDs remain external identifiers and should not replace internal database identity.

Application state such as Library membership, tracking status, viewing progress, history, rewatches, ratings, and user ownership belongs to SofaWatch.

---

## Database Migrations

Schema changes are managed using Alembic.

Apply pending migrations:

```bash
alembic upgrade head
```

Inspect the current revision:

```bash
alembic current
```

Check for model/schema differences:

```bash
alembic check
```

Create a migration after changing SQLAlchemy models:

```bash
alembic revision --autogenerate -m "describe change"
```

Autogenerated migrations must always be reviewed before being committed or applied.

Before stable releases, upgrade compatibility should also be tested against older SofaWatch database snapshots rather than only databases created from scratch.

See:

- [Database Architecture](../docs/architecture/database.md)
- [Database Migrations](../docs/development/migrations.md)

---

## Core Media Functionality

### TV Shows and Episodes

The backend provides the domain and persistence required for shows, seasons, episodes, Library state, progress, Watch Next, Upcoming, viewing events, rewatches, and metadata synchronization.

Each episode viewing is represented by an individual watch event. A rewatch creates another event instead of replacing previous history.

### Movies

Movies are first-class local SofaWatch entities with TMDB import, local persistence, Library/watchlist integration, viewing events, rewatches, history, and statistics integration.

Importing a movie and adding it to a user's Library are separate operations.

### Library

Library data is user-scoped.

Importing metadata into SofaWatch does not automatically mean that the media belongs to a user's Library.

### Search and Explore

Search provides global media lookup and normalized results.

Explore provides discovery-oriented content such as trending and popular media.

TMDB responses are normalized before being exposed to clients so provider-specific response structures do not become the frontend domain model.

Search uses a small bounded in-memory cache with TTL/LRU behavior to reduce unnecessary repeated provider calls.

### Statistics and History

Statistics are calculated from SofaWatch's persisted viewing data.

Rewatches are individual viewing events and therefore contribute to viewing totals.

The backend provides user-scoped history for episodes and movies, including combined chronological activity.

---

## Metadata Providers

### TMDB

TMDB is currently the primary metadata provider and supports areas including:

- Search
- TV show and movie metadata
- Seasons and episodes
- Genres
- Images
- Trending and popular content
- Discovery
- Metadata synchronization

Metadata is mapped into local SofaWatch entities rather than exposing provider objects as the application domain.

### TVDB

TVDB is planned as a future complementary provider, particularly for TV metadata.

The intended architecture is to add provider mappings and adapters rather than spread provider-specific IDs throughout business logic.

TVDB health diagnostics should only be exposed once a real TVDB integration exists.

### IMDb / External Ratings

IMDb or another legitimate external-rating source may be evaluated later.

Any integration should use a stable and legally appropriate source rather than fragile scraping.

Personal SofaWatch ratings and external provider ratings must remain separate concepts.

---

## Metadata Synchronization

Metadata synchronization keeps locally imported media information up to date.

Automatic refresh behavior respects the application's metadata refresh policy and should update external metadata without destroying SofaWatch-owned state.

Recurring synchronization is executed through the background job infrastructure.

See [Metadata Synchronization](../docs/features/metadata-sync.md).

---

## Background Jobs

SofaWatch includes a persistent background job system for recurring server-side work.

It provides registered jobs, scheduling, persistent state, execution history, duration, next-run tracking, structured results, failure information, and manual execution.

The current deployment model assumes a normal self-hosted single-worker installation.

Start the worker:

```bash
python -m app.jobs.worker
```

Run the metadata synchronization job manually when needed:

```bash
python -m app.jobs.run metadata_sync
```

See [Background Jobs](../docs/architecture/background-jobs.md).

---

## Server Administration

The backend exposes administrator-only infrastructure for server health, database/storage/runtime diagnostics, provider health, background jobs, logs, import/export, security settings, and password recovery.

Diagnostics must avoid exposing secrets or sensitive configuration values.

Administrative routes must remain independently protected by backend authorization.

---

## Import / Export

The backend contains infrastructure for portable SofaWatch data.

Export/import functionality is designed around versioned data and can cover user-owned information such as Library, viewing history, ratings, and relevant user/application data.

Import workflows should validate input, avoid unintended duplication, report partial failures safely, and preserve existing data integrity.

---

## Logging

SofaWatch configures application logging for runtime components such as the API and background worker.

Logs must not expose passwords, tokens, session/refresh/recovery credentials, provider secrets, or other sensitive values.

Administrator-facing logs should expose safe messages rather than raw sensitive application state.

---

## Testing

Run the complete backend suite:

```bash
pytest -q
```

or:

```bash
python -m pytest
```

Run a focused module:

```bash
pytest tests/services/test_show_import_service.py -q
```

Run a specific test:

```bash
pytest path/to/test_file.py::test_name -q
```

Tests cover routes, authentication and authorization, services, repositories, database behavior, providers, background jobs, viewing progress, history, statistics, and metadata synchronization.

External provider calls should be mocked where appropriate so the suite does not depend on live provider availability.

Preferred workflow:

1. Inspect the current implementation.
2. Make a focused change.
3. Run focused tests.
4. Run linting/format checks when relevant.
5. Run the complete relevant test suite.
6. Fix regressions before continuing.

See [Testing](../docs/development/testing.md).

---

## Code Quality

Ruff is used for linting and formatting.

```bash
ruff check .
```

```bash
ruff format .
```

The configured Python target is Python 3.12 with a line length of 100 characters.

Code should preserve the separation between routes, services, repositories, models, schemas, and providers.

New abstractions or infrastructure should solve a concrete problem rather than being introduced preemptively.

---

## Development Principles

Backend development follows the project's broader engineering principles:

- Clean Architecture
- SOLID
- DRY
- KISS
- clear dependency direction
- backend as the source of truth
- provider-independent business rules
- explicit user scoping
- safe authentication and authorization
- incremental changes
- automated regression tests
- no unnecessary abstractions
- no premature optimization

---

## Documentation

Additional technical documentation is available under [`../docs`](../docs/).

Useful starting points include:

- [Architecture Overview](../docs/architecture/overview.md)
- [Backend Architecture](../docs/architecture/backend.md)
- [Database Architecture](../docs/architecture/database.md)
- [Background Jobs](../docs/architecture/background-jobs.md)
- [Development Setup](../docs/development/setup.md)
- [Database Migrations](../docs/development/migrations.md)
- [Testing](../docs/development/testing.md)
- [API Overview](../docs/api/overview.md)
- [Metadata Synchronization](../docs/features/metadata-sync.md)

---

## Related Documentation

- [Main SofaWatch README](../README.md)
- [Frontend README](../frontend/README.md)
- [Technical Documentation](../docs/README.md)
