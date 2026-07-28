# Backend Architecture

The SofaWatch backend is implemented with FastAPI, SQLAlchemy and Pydantic.

## Structure

The backend application is divided into several layers.

### API

`app/api/`

Contains HTTP routes, request parameters and FastAPI dependencies.

Routes should remain thin and delegate business logic to services.

### Services

`app/services/`

Contains application and business logic.

Examples include:

- importing TV series;
- managing the personal library;
- tracking viewing progress;
- calculating the next episode;
- retrieving TMDB metadata.

Services may coordinate multiple repositories and providers.

### Repositories

`app/repositories/`

Contains database queries and persistence operations.

Repositories isolate SQLAlchemy query logic from services.

### Models

`app/models/`

Contains SQLAlchemy entities representing local persistent data.

Examples include:

- users;
- shows;
- seasons;
- episodes;
- genres;
- networks;
- library entries;
- episode progress;
- background jobs.

### Schemas

`app/schemas/`

Contains Pydantic models used for:

- API responses;
- request payloads;
- application-level data transfer.

### Providers

`app/providers/`

Contains integrations with external services.

TMDB is currently implemented as a provider with its own HTTP client, response schemas and provider-specific exceptions.

### Jobs

`app/jobs/`

Contains background job infrastructure and scheduled application tasks.

The job system consists of:

- a registry;
- an executor;
- a scheduler;
- individual job handlers.

## Dependency flow

Dependencies should generally flow inward:

```text
routes
  → services
      → repositories
      → providers
```

Repositories and models should not depend on API routes or FastAPI.

This keeps the domain reusable outside HTTP requests, including background jobs and tests.