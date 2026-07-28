# Architecture Overview

SofaWatch is a self-hosted application for tracking television shows and movies.

The application is designed around a backend API that owns the local data and metadata integrations, with clients consuming that API through web and native interfaces.

## Main components

### Backend

The backend is implemented in Python using FastAPI.

Its responsibilities include:

- exposing the SofaWatch API;
- storing local application data;
- integrating with external metadata providers;
- managing personal libraries;
- tracking episode viewing progress;
- synchronizing metadata;
- running background jobs.

### Database

SQLite is the default database.

SQLAlchemy is used for persistence and Alembic is used for schema migrations.

### Metadata providers

TMDB is currently the primary metadata provider for TV series metadata.

The provider layer is intentionally separated from application services so that external APIs do not leak directly into the domain and persistence layers.

### Frontend

The frontend will provide web and native clients using React Native and Expo.

Clients communicate with the backend through the HTTP API.

## Backend layers

The backend follows a layered structure:

```text
API routes
    ↓
Services
    ↓
Repositories
    ↓
SQLAlchemy models
    ↓
Database
```

External metadata flows through provider clients:

```text
TMDB
  ↓
Provider client
  ↓
Provider schemas
  ↓
Application services
  ↓
Local models
```

This separation keeps HTTP concerns, business logic, persistence, and third-party integrations independent.


