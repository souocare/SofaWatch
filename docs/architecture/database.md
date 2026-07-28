
# Database Architecture

SofaWatch stores application data locally using SQLAlchemy.

SQLite is the default database.

## Main entities

### User

Represents a SofaWatch user.

The current application creates a single local user, while the schema is designed to support multiple users later.

### Show

Represents a locally imported TV series.

A show contains metadata retrieved from external providers and relationships to genres, networks and seasons.

### Season

Belongs to a show and contains episodes.

Season zero is used for specials when returned by the metadata provider.

### Episode

Belongs to a season and stores episode-level metadata.

### Genre

Genres are shared between shows through a many-to-many relationship.

### Network

Television networks are shared between shows through a many-to-many relationship.

### LibraryEntry

Associates a user with a show and stores the user's tracking state.

### EpisodeProgress

Associates a user with an episode.

It stores:

- watched state;
- viewing date.

### BackgroundJob

Stores the current state of a registered background job.

### BackgroundJobRun

Stores the execution history of a background job.

## Relationships

```text
User
 ├── LibraryEntry ───────────── Show
 │                              │
 │                              ├── Genre
 │                              ├── Network
 │                              └── Season
 │                                   │
 └── EpisodeProgress ─────────────── Episode

BackgroundJob
 └── BackgroundJobRun
```

## Local metadata preservation
Metadata imported from TMDB is stored separately from local media overrides where applicable.
For example:

```bash
tmdb_poster_path
local_poster_path
```

This allows metadata synchronization to update external metadata without overwriting locally managed artwork.

## Deletion behaviour
Relationships use database constraints and ORM cascades where ownership is clear.
Examples include:

- deleting a show removes its owned seasons;
- deleting a season removes its owned episodes;
- deleting a user removes user-owned library and progress data;
- deleting a background job removes its execution history.

Shared entities such as genres and networks are not owned by a single show.