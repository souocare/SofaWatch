# SofaWatch Documentation

Welcome to the SofaWatch documentation.

This directory contains technical documentation about the architecture,
development workflow, API, features, and design decisions behind SofaWatch.

For a general introduction to the project, see the
[main README](../README.md).

## Architecture

Documentation about the overall design and internal structure of SofaWatch.

- [Architecture Overview](architecture/overview.md)
- [Backend Architecture](architecture/backend.md)
- [Database Architecture](architecture/database.md)
- [Background Jobs](architecture/background-jobs.md)

## Development

Guides for setting up and working on SofaWatch.

- [Development Setup](development/setup.md)
- [Testing](development/testing.md)
- [Database Migrations](development/migrations.md)

## Features

Technical documentation for implemented features.

- [TV Show Search](features/show-search.md)
- [TV Show Import](features/show-import.md)
- [Personal Library](features/library.md)
- [Viewing Progress](features/viewing-progress.md)
- [Metadata Synchronization](features/metadata-sync.md)

## API

Documentation about the SofaWatch backend API.

- [API Overview](api/overview.md)

Interactive OpenAPI documentation is also available when the backend is
running:

- Swagger UI: `/docs`
- ReDoc: `/redoc`

## Architecture Decisions

Important architectural decisions are documented as Architecture Decision
Records (ADRs).

See [Architecture Decisions](decisions/README.md).

## Documentation Structure

```text
docs/
├── architecture/    # System architecture and internal design
├── development/     # Development and contributor guides
├── features/        # Feature-specific technical documentation
├── api/             # API documentation
└── decisions/       # Architecture Decision Records