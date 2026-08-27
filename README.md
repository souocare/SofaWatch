# SofaWatch

**SofaWatch** is a self-hosted companion application for tracking TV shows and movies across Web, iOS, and Android.

The goal is to provide a private, self-hosted alternative for managing what you watch, keeping track of your progress, discovering what to watch next, and maintaining your own viewing history while keeping application data under your control.

> [!NOTE]
> SofaWatch is currently under active development. Features, APIs, and the interface may change as the project evolves.

## Features

### Implemented

#### TV Shows

- TV show library and status management
- Season and episode tracking
- Watch progress and Watch Next
- Upcoming episodes
- Complete episode viewing history
- Rewatch support
- Show and season details
- Metadata synchronization
- Season and show bulk watched actions
- Previous-episode catch-up when marking later episodes watched

#### Movies

- Movie library and watchlist
- Movie details
- Watched state and viewing history
- Rewatch support
- Movie metadata

#### Search & Discovery

- Global search for TV shows and movies
- Search filters and pagination
- Media previews
- Trending and popular content
- Genre-based discovery
- Responsive search experience across Web and mobile

#### Home

- Personal viewing dashboard
- Weekly viewing summary
- Continue Watching
- Premiering Today
- Upcoming episodes
- Missed episodes
- Recent activity

#### Statistics

- Viewing time and activity
- Episode and movie statistics
- Rewatch statistics
- Viewing habits and streaks
- Content and genre insights
- Library statistics

#### History

- Episode and movie viewing history
- Combined chronological history
- Individual entries for every viewing and rewatch
- Navigation back to the associated media

#### Authentication & Multi-user

- Multi-user authentication
- First-run administrator setup
- Web sessions using HttpOnly cookies
- Mobile authentication with access and rotating refresh credentials
- Session management and revocation
- Password changes and recovery
- Configurable public registration
- Mobile-to-Web authentication handoff

#### Administration

- Server health and diagnostics
- Database and storage diagnostics
- Background jobs
- Application logs
- Import / Export
- Security settings
- Administrator-only functionality

#### Self-hosting

- FastAPI backend
- Flutter Web, iOS, and Android clients
- SQLite database
- Alembic migrations
- Background worker
- TMDB metadata integration

---

### Planned

The roadmap is intentionally flexible. Some of these features are exploratory and may change or be removed as SofaWatch evolves.

#### Metadata Providers

- TVDB integration
- Provider-independent external identifiers
- TMDB / TVDB metadata matching
- Metadata precedence and fallback rules
- IMDb integration or another legitimate external ratings source
- External ratings alongside personal SofaWatch ratings

#### Discovery

- Personalized recommendations
- More Like This
- Because You Watched...
- Hidden Gems
- Coming Soon
- More advanced personal discovery

#### TV & Movie Tracking

- Additional Upcoming interactions
- Improved coordinated refresh behavior
- Additional progress and caught-up handling
- More advanced movie discovery
- Further responsive improvements

#### Statistics

- Backlog statistics
- Estimated future watch time
- Catch-up speed
- Additional long-term viewing insights

#### User Administration

- Full administrator user management
- Activate and deactivate accounts
- Session management improvements
- Desktop/Web administration interface

#### Localization

- English and Portuguese localization
- Language preferences
- Localized dates and numbers
- Metadata provider language integration

#### Backups

- SQLite backup strategy
- Backup status and history
- Restore workflow
- Backup storage diagnostics

#### Notifications

Potential future notifications for:

- Upcoming episodes
- New seasons
- Background job failures
- Administrative events

#### Self-hosting & Production

- Production deployment guidance
- HTTPS / reverse proxy configuration
- Backup and restore procedures
- Worker deployment
- Web and mobile release builds
- Upgrade and migration procedures

#### Quality

- Accessibility audit
- Responsive design audit
- Performance audit
- Integration testing
- Architecture review
- Stable release preparation

## Architecture

SofaWatch follows a layered architecture designed to keep business rules independent from external providers and presentation frameworks.

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

### Backend

```text
API / Routes
     |
     v
Services
     |
     v
Repositories
     |
     v
Database / External Providers
```

The backend is the source of truth for persisted state and application business rules.

External metadata providers are kept separate from the SofaWatch domain wherever possible.

### Frontend

The Flutter application follows a Feature First structure with a lightweight Clean Architecture approach:

```text
feature/
├── presentation/
├── application/
├── domain/
└── data/
```

Domain and application logic are shared across platforms whenever possible, while presentation adapts to Web and mobile.

For more detailed architecture and development information:

- [Backend documentation](backend/README.md)
- [Frontend documentation](frontend/README.md)

> The detailed backend and frontend documentation is being expanded as development continues.

---

## Tech Stack

### Backend

- Python
- FastAPI
- SQLAlchemy
- Pydantic
- Alembic
- SQLite
- pytest
- Ruff

### Frontend

- Flutter
- Dart
- flutter_bloc
- go_router
- Dio

### Metadata

Currently:

- TMDB

Planned / under evaluation:

- TVDB
- IMDb or another appropriate external ratings source

---

## Project Structure

```text
SofaWatch/
├── backend/
│   ├── app/
│   ├── alembic/
│   └── tests/
│
├── frontend/
│   ├── lib/
│   └── test/
│
├── docs/
│
└── README.md
```

For backend-specific information, see [`backend/README.md`](backend/README.md).

For frontend-specific information, see [`frontend/README.md`](frontend/README.md).

For technical documentation, see [`docs/README.md`](docs/README.md).

---

<!--
## Screenshots

Screenshots will be added as the interface approaches a more stable state.

### Home

### Shows

### Show Details

### Movies

### Explore

### Search

### Profile

### Mobile

Screenshots should be stored under:

docs/assets/screenshots/
-->

## Getting Started

SofaWatch is currently under active development. These instructions describe a development environment rather than a final production deployment.

Clone the repository:

```bash
git clone https://github.com/souocare/SofaWatch.git
```

### Backend

From the `backend` directory, activate the virtual environment:

```bash
source .sofawatchvenv/bin/activate
```

If the virtual environment is stored at the project root:

```bash
source ../.sofawatchvenv/bin/activate
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

The API is available at:

```text
http://127.0.0.1:8000
```

Interactive API documentation:

```text
http://127.0.0.1:8000/docs
```

### Background Worker

Run the worker in a separate terminal:

```bash
python -m app.jobs.worker
```

### Flutter Web

From the `frontend` directory:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

### iOS Simulator

```bash
flutter run -d "<iPhone Simulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

### Android Emulator

```bash
flutter run -d "<Android Emulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://10.0.2.2:8000
```

### Physical Devices

For physical iOS or Android devices, the backend must be reachable through the computer's LAN address.

Start FastAPI listening on all interfaces:

```bash
uvicorn app.main:app \
  --reload \
  --host 0.0.0.0 \
  --port 8000
```

Then run Flutter using the computer's LAN IP:

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://<LAN-IP>:8000
```

---

## Database

SofaWatch uses **SQLite** as its database.

SQLite is an intentional choice for the self-hosted deployment model rather than a temporary development database.

Schema changes are managed through Alembic migrations.

---

## Metadata Providers

TMDB is currently the primary metadata provider for search, discovery, TV shows, movies, seasons, episodes, genres, images, and related metadata.

SofaWatch maintains its own internal entity IDs after media is imported.

External identifiers such as TMDB, future TVDB IDs, and IMDb IDs are treated as provider identifiers rather than SofaWatch's primary domain identifiers.

The long-term architecture is intended to support multiple providers without coupling the application domain to any individual provider.

---

## Authentication

SofaWatch supports multiple users and persistent authenticated sessions.

Web clients use server-managed sessions through HttpOnly cookies.

Native clients use short-lived access tokens together with rotating refresh credentials.

A new installation enters a first-run setup flow where the first account becomes the initial Administrator.

Public registration is disabled by default and can be enabled by an Administrator.

---

## API

The API is versioned under:

```text
/api/v1
```

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

## Background Jobs

SofaWatch includes a persistent background job system for recurring server-side tasks, including metadata synchronization.

Jobs provide scheduling, execution history, status tracking, structured results, and failure reporting.

See [Background Jobs](docs/architecture/background-jobs.md) for details.

## Testing

### Backend

```bash
pytest -q
```

### Frontend

```bash
flutter test
```

Development normally follows an incremental workflow:

1. Make a focused change.
2. Run focused tests.
3. Run static analysis/linting where applicable.
4. Run the relevant full test suite.
5. Fix regressions before continuing.

See [Testing](docs/development/testing.md) for more information.

## Development

Detailed backend and frontend development information is maintained alongside each application layer:

- [Backend development](backend/README.md)
- [Frontend development](frontend/README.md)
- [Technical documentation](docs/README.md)

Backend linting and formatting use Ruff:

```bash
ruff check .
```

```bash
ruff format .
```

Additional development documentation is available under [`docs/development/`](docs/development/).

## Development Principles

SofaWatch is developed around a few core principles:

- Clean Architecture
- SOLID
- DRY
- KISS
- Feature First organization
- Backend as the source of truth
- Provider-independent domain models
- Incremental development
- Automated regression testing
- Responsive UI
- Avoiding unnecessary abstractions and premature optimization

---

## Project Status

SofaWatch is under active development.

The core application already supports TV and movie tracking, watch history and rewatches, global search, discovery, statistics, multi-user authentication, administration, background jobs, and responsive Flutter clients.

The project should still be considered **pre-release software**.

Features and architecture may continue to evolve before the first stable release.

---

## Documentation

More detailed documentation is separated by application layer:

- [Backend](backend/README.md)
- [Frontend](frontend/README.md)
- [Technical documentation](docs/README.md)

Additional architecture, deployment, and development documentation may be added under `docs/` as the project approaches a stable release.

## Contributing

SofaWatch is still evolving, so APIs, database models, and project structure may change as development continues.

Issues, ideas, bug reports, and contributions are welcome.

Technical documentation is available under [`docs/`](docs/), and backend-specific development information is available in [`backend/README.md`](backend/README.md).

## Acknowledgements

SofaWatch would not exist without the projects and services that inspired and support its development.

### TMDB

SofaWatch uses the TMDB API as its current source for TV show, movie, season, episode, genre, image, and related metadata.

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
