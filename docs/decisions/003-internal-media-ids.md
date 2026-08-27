# ADR-003: Internal SofaWatch Media Identifiers

- Status: Accepted
- Date: 2026-08-27

## Context

SofaWatch imports and synchronizes media metadata from external providers.

TMDB is currently the primary metadata provider, with future support planned or under evaluation for providers such as:

```text
TVDB
IMDb / another legitimate external ratings source
```

External providers assign their own identifiers to entities such as:

- TV Shows;
- Seasons;
- Episodes;
- Movies;
- genres;
- people and other metadata resources.

It would be technically possible to use a provider identifier such as a TMDB ID as the primary identity of a SofaWatch media entity.

For example:

```text
Show.id = TMDB show ID
```

That approach appears simple while SofaWatch has one primary provider, but it would make SofaWatch's internal identity depend on an external system.

This creates problems as soon as the application needs to:

- support multiple providers;
- map the same media across providers;
- change metadata providers;
- retain local media if a provider becomes unavailable;
- store provider-specific identifiers independently;
- resolve mismatches;
- support provider-specific metadata without changing local identity.

SofaWatch therefore needs an identity model that belongs to SofaWatch itself.

---

## Decision

Imported media entities use **SofaWatch-owned internal identifiers** as their primary application identity.

External identifiers remain external/provider identifiers.

Conceptually:

```text
SofaWatch Show
--------------
id = 42

External identifiers
--------------------
TMDB = 1399
TVDB = 121361
IMDb = tt0944947
```

The exact external identifiers above are illustrative only.

The important distinction is:

```text
42
```

identifies the entity inside SofaWatch, while each provider identifier identifies the corresponding resource within that provider.

Provider identifiers must not become the primary domain identity merely because one provider is currently dominant.

---

## Scope

This decision applies to persisted SofaWatch media entities such as:

```text
Show
Season
Episode
Movie
```

and should guide future provider-integrated entities where SofaWatch needs durable local identity.

Not every temporary provider search result needs a local SofaWatch ID.

A Search result can remain provider-backed until the media is imported.

---

## Import Boundary

The import boundary is where external provider identity becomes associated with a SofaWatch entity.

Conceptually:

```text
TMDB Search Result
    |
    | tmdb_id
    v
Import
    |
    v
SofaWatch Show
    |
    | internal show.id
    v
Library / Progress / History
```

Before import:

```text
provider identity
```

may be sufficient.

After import:

```text
SofaWatch internal identity
```

is authoritative for local relationships.

---

## Example: Show Import

A user finds a Show through TMDB-backed Search.

The Search result may contain:

```text
provider = TMDB
provider_id = 12345
```

When imported, SofaWatch creates or finds the corresponding local Show:

```text
Show
id = 87
```

Subsequent local operations should reference:

```text
show_id = 87
```

rather than using the TMDB ID as if it were the SofaWatch primary key.

The TMDB identifier remains available for metadata synchronization and provider mapping.

---

## Example: Movie Import

The current Movie import flow includes a provider-specific endpoint such as:

```text
POST /api/v1/movies/import/tmdb/{tmdb_id}
```

The provider ID is appropriate at the import boundary because the requested operation means:

```text
import this TMDB Movie
```

After import, the resulting Movie has a SofaWatch internal ID.

Library, viewing history, ratings, and other local relationships should use that internal identity.

---

## Idempotent Import

Importing the same provider resource repeatedly should not create duplicate local media.

Conceptually:

```text
TMDB movie 550
    |
    +--> import --> SofaWatch Movie 12
    |
    +--> import again --> SofaWatch Movie 12
```

not:

```text
TMDB movie 550
    |
    +--> SofaWatch Movie 12
    +--> SofaWatch Movie 13
```

Provider mappings/identifiers therefore participate in import matching and idempotency even though they are not the local primary key.

---

## Local Relationships

Once imported, local relationships should reference internal IDs.

Examples:

```text
LibraryEntry -> Show.id
LibraryEntry -> Movie.id

Season -> Show.id
Episode -> Season.id

EpisodeWatchEvent -> Episode.id
MovieWatchEvent -> Movie.id
```

This keeps the relational model centered on SofaWatch entities.

---

## Library

Library membership is not attached directly to a TMDB resource.

Conceptually:

```text
User
  |
  v
LibraryEntry
  |
  +--> SofaWatch Show
  |
  or
  |
  +--> SofaWatch Movie
```

The external provider mapping belongs to the media entity/provider integration layer.

---

## Viewing History

Watch events reference local media.

Example:

```text
EpisodeWatchEvent
    |
    v
Episode.id
    |
    v
Season / Show
```

This allows viewing history to remain valid even if:

- TMDB is temporarily unavailable;
- another provider becomes primary for some metadata;
- provider matching changes;
- additional external IDs are added later.

---

## Ratings

Personal SofaWatch ratings should reference internal media identity.

External ratings are a separate concept.

Future model:

```text
SofaWatch Movie 42
    |
    +--> Personal Rating
    |
    +--> External Rating: TMDB
    |
    +--> External Rating: IMDb
```

The external rating provider does not redefine the identity of the Movie.

---

## Provider Mappings

As SofaWatch gains more providers, external identifiers should be represented through explicit provider mappings or an equivalent extensible structure.

Conceptually:

```text
SofaWatch Media
      |
      +--> TMDB mapping
      +--> TVDB mapping
      +--> IMDb mapping
```

rather than spreading fields such as:

```text
tmdb_id
tvdb_id
imdb_id
```

through every layer of business logic.

The exact mapping schema can evolve when multi-provider integration is implemented.

This ADR defines the identity principle, not one mandatory database table design.

---

## Provider-Specific Fields

Some provider-specific identifiers may exist in current models because TMDB is the current integration.

Their existence does not change the architectural direction.

Code should avoid patterns such as:

```text
if show.tmdb_id == ...
```

inside unrelated business logic when the rule actually concerns SofaWatch identity.

Provider IDs should be used where provider identity is genuinely relevant:

- provider requests;
- import matching;
- synchronization;
- cross-provider matching;
- external links;
- provider diagnostics.

---

## Seasons and Episodes

Season and Episode identity is particularly important because different providers may disagree about:

- numbering;
- specials;
- episode grouping;
- air dates;
- alternate orders.

SofaWatch should not assume that one provider's Episode ID is a universal Episode identity.

Conceptually:

```text
SofaWatch Episode
       |
       +--> TMDB Episode mapping
       +--> TVDB Episode mapping
```

Future TVDB integration may require explicit matching rules rather than simply copying provider IDs into the Episode primary key.

---

## Episode Numbering

Human-facing identifiers such as:

```text
S02E05
```

are not database primary identities.

They are useful media coordinates, but can be affected by:

- provider ordering differences;
- specials;
- alternate episode orders;
- metadata corrections.

Internal identity should remain stable independently of display numbering.

---

## Genres

Genres follow the same provider-independence principle.

A SofaWatch Genre should not conceptually mean:

```text
TMDB Genre ID
```

Instead:

```text
SofaWatch Genre
      |
      +--> TMDB TV genre mapping
      +--> TMDB Movie genre mapping
      +--> future provider mappings
```

This is especially important because providers may use different taxonomies or even different IDs for TV and Movie genres.

---

## Search Results vs Imported Entities

Search results and local media have different identity lifecycles.

### Search Result

A Search result can conceptually be:

```text
provider
provider media type
provider ID
metadata preview
```

It may not yet exist locally.

### Imported Media

After import:

```text
internal SofaWatch ID
+
provider mapping(s)
+
persisted local metadata
```

The frontend should not confuse these identities.

---

## Preview Flow

A preview opened from Search or Explore may initially be provider-backed.

If the user performs a mutation requiring a local entity, such as adding media to the Library, the backend can import/resolve the media first and then operate using the local identity.

Conceptually:

```text
Provider preview
      |
      v
Import / resolve local media
      |
      v
SofaWatch ID
      |
      v
Library mutation
```

---

## API Design

Provider-specific IDs are appropriate in provider-specific API operations.

Example:

```text
/import/tmdb/{tmdb_id}
```

Internal IDs are appropriate for local entity operations.

Conceptually:

```text
/shows/{show_id}
/movies/{movie_id}
/episodes/{episode_id}
```

This distinction makes the API boundary clearer.

---

## URLs and Navigation

Frontend routes for persisted local media should prefer SofaWatch internal IDs.

Example:

```text
Show Details
-> local show ID
```

A provider-specific preview route may use provider identity when the media has not yet been imported.

The route should make the distinction explicit rather than treating both identifiers as interchangeable integers.

---

## Provider Failure

If TMDB becomes unavailable temporarily, existing imported media should still retain local identity.

Operations based on already persisted SofaWatch data should not fail merely because the provider cannot currently resolve the entity's identity.

Metadata refresh may fail.

The local Show should not cease to exist.

---

## Provider Removal

If a provider is ever replaced or disabled, local relationships should remain structurally intact.

For example:

```text
Library
History
Progress
Personal Ratings
```

should not require primary-key migration simply because metadata sourcing changes.

This is one of the major benefits of internal identity.

---

## Cross-Provider Matching

Future TMDB ↔ TVDB matching should associate provider resources with an existing SofaWatch entity.

Conceptually:

```text
TMDB Show X ──┐
              │
              v
        SofaWatch Show 42
              ^
              │
TVDB Show Y ──┘
```

The goal is not:

```text
TMDB Show X == TVDB Show Y because their numeric IDs happen to match
```

Provider namespaces are independent.

---

## Identifier Namespace

An external ID is meaningful only together with its provider and entity context.

Conceptually:

```text
(provider = TMDB, type = SHOW, id = 123)
```

is different from:

```text
(provider = TVDB, type = SHOW, id = 123)
```

and may also differ from:

```text
(provider = TMDB, type = MOVIE, id = 123)
```

Provider mapping models should preserve sufficient namespace information to avoid ambiguity.

---

## Metadata Synchronization

Metadata synchronization uses provider mappings to find the external resource corresponding to a local entity.

Conceptually:

```text
SofaWatch Show 42
      |
      v
TMDB mapping
      |
      v
TMDB API
      |
      v
normalized metadata
      |
      v
update SofaWatch Show 42
```

Synchronization updates metadata.

It does not replace the local entity with a provider entity.

---

## Deletion

Deleting local media is a SofaWatch operation.

It should be based on internal identity and local relationship rules.

Deleting a SofaWatch Show does not mean deleting anything from TMDB.

Similarly, a provider resource disappearing does not automatically define how SofaWatch should delete user-owned local history.

Such behavior must be explicit.

---

## Database Migrations

Internal IDs make provider schema evolution easier.

For example, moving from:

```text
Show.tmdb_id
```

toward:

```text
ExternalMediaIdentifier
```

can preserve:

```text
Show.id
```

and therefore preserve all local foreign-key relationships.

This is preferable to migrating every relationship because a provider identity strategy changed.

---

## Consequences

### Positive

#### Provider Independence

SofaWatch identity does not belong to TMDB, TVDB, IMDb, or another external service.

#### Stable Local Relationships

Library, History, Progress, Ratings, and other data reference durable local entities.

#### Easier Multi-Provider Support

Multiple external resources can map to one SofaWatch entity.

#### Provider Failure Resilience

Existing media identity remains valid when a provider is unavailable.

#### Cleaner API Semantics

Provider IDs are used at provider boundaries; local IDs are used for local resources.

#### Easier Provider Migration

Changing metadata sources does not inherently require changing SofaWatch primary keys.

---

### Trade-offs

#### Mapping Complexity

SofaWatch must maintain relationships between local and provider identities.

#### Import Step

A provider result must be resolved/imported before some local operations can occur.

#### Matching Complexity

Multi-provider support introduces matching and conflict-resolution questions.

#### Additional Schema

A mature multi-provider implementation may require dedicated external identifier/mapping tables.

These costs are accepted because they prevent deeper coupling to one provider.

---

## Alternatives Considered

### Use TMDB IDs as Primary Keys

This would simplify the initial TMDB-only implementation.

Rejected because:

- TMDB would own SofaWatch identity;
- multi-provider matching would become awkward;
- provider changes could require primary-key migrations;
- local identity would be confused with external identity;
- provider namespaces are not universal.

---

### Use Provider + Provider ID as the Entire Domain Identity

Example:

```text
TMDB:SHOW:123
```

This avoids numeric collisions but still makes the domain entity fundamentally provider-owned.

It also makes representing:

```text
TMDB X
and
TVDB Y
are the same SofaWatch Show
```

less natural.

Rejected as the primary persisted domain identity.

---

### Duplicate Local Entity Per Provider

Example:

```text
TMDB Show record
TVDB Show record
```

with user state attached to one or both.

Rejected because it creates duplicate domain entities for the same real media and makes Library/History/Progress ownership ambiguous.

Provider resources should map to one SofaWatch media entity where they represent the same content.

---

### Provider IDs Everywhere Plus Internal IDs

SofaWatch could have internal IDs but still expose and use provider IDs throughout business logic.

Rejected as a general pattern because it preserves much of the coupling this ADR is intended to avoid.

Provider IDs should cross boundaries only where they are actually needed.

---

## Revisit When

The principle of SofaWatch-owned identity should only be reconsidered if the product fundamentally stops maintaining local media entities.

Examples might include:

### Pure Provider Proxy

If SofaWatch becomes a stateless UI directly proxying one provider with no durable local media model.

That would be a substantially different product.

### Federated Universal Identifier Standard

If a future reliable universal media identity standard genuinely replaces provider-specific identity and becomes appropriate as the domain identity.

Even then, migration consequences would require a new ADR.

Normal addition of TVDB or IMDb is **not** a reason to revisit this decision.

Those integrations are exactly why this decision exists.

---

## Future External Identifier Model

A future provider-independent model may conceptually resemble:

```text
ExternalIdentifier
------------------
id
media_type
local_media_id
provider
provider_entity_type
external_id
```

or separate typed mapping tables.

Possible constraints include:

```text
unique(provider, provider_entity_type, external_id)
```

where appropriate.

This is illustrative only.

The exact database design should be decided when the provider architecture is implemented rather than prematurely fixed by this ADR.

---

## Implementation Constraints

Code written under this decision should follow these rules:

```text
[ ] imported media receives SofaWatch-owned identity
[ ] local relationships use internal IDs
[ ] provider IDs remain provider identifiers
[ ] provider IDs are namespaced by provider/type where necessary
[ ] import remains idempotent
[ ] Search/Explore may use provider identity before import
[ ] local media routes should use internal IDs
[ ] provider-specific import routes may use provider IDs
[ ] provider outages do not erase local identity
[ ] personal state is not keyed directly to provider resources
[ ] future TVDB/IMDb integration maps onto existing local entities
[ ] business logic should not become dependent on TMDB IDs
[ ] provider mapping schema should be extensible when introduced
```

---

## Relationship to Other Decisions

### SQLite

[ADR-001](001-sqlite.md) defines the database that stores SofaWatch-owned media entities and their relationships.

### Backend as Source of Truth

[ADR-002](002-backend-source-of-truth.md) establishes that the backend owns persisted identity and resolves provider resources into local entities.

### Global Search

[ADR-004](004-global-search.md) allows Search to operate on provider-backed results before media is necessarily imported.

### Authentication

[ADR-005](005-authentication-model.md) establishes authenticated user identity separately from media identity.

### Provider Independence

[ADR-006](006-provider-independence.md) builds directly on this ADR by defining how metadata providers remain outside the core domain.

---

## Related Documentation

- [Documentation Index](../README.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [API Overview](../api/overview.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [Library](../features/library.md)
- [Show Search](../features/show-search.md)
- [Metadata Sync](../features/metadata-sync.md)
- [Implementation Status](../features/implementation-status.md)
