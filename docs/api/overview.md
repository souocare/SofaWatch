
# API Overview

SofaWatch exposes a REST API using FastAPI.

Interactive OpenAPI documentation is available automatically through FastAPI.

## Main resources

### Shows

Supports:

- local show listing;
- local show detail;
- TMDB detail lookup;
- TMDB import;
- manual metadata refresh;
- show progress;
- next episode.

### Seasons

Supports:

- listing seasons belonging to a show;
- season progress;
- episodes belonging to a season.

### Episodes

Supports:

- episode detail;
- marking an episode as watched;
- marking an episode as unwatched;
- storing the viewing date.

### Library

Supports:

- adding shows;
- removing shows;
- changing tracking state;
- listing library entries;
- filtering by state.

### Search

Provides TV series search through metadata providers.

### Genres

Provides locally available genre information.

### Background jobs

Supports:

- listing registered jobs;
- retrieving execution history;
- manually executing a job.

## Resource identifiers

External provider identifiers such as TMDB IDs are stored separately from SofaWatch's internal identifiers.

Local entities generally use UUIDs.

For example:

```text
GET /shows/{show_id}
``` 
uses the SofaWatch UUID, while:
```text
GET /shows/tmdb/{tmdb_id}
```
uses the TMDB identifier.

##Error handling
The API uses standard HTTP status codes.
Typical examples include:

```text
400 / 422  invalid request
404        resource not found
409        conflicting state
500        internal configuration or server error
502        invalid upstream provider response
503        upstream provider unavailable
```

## Authentication
The current backend operates using a local-user model.
Full authentication and authorization are planned for a later stage.