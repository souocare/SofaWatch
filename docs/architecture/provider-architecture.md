# Provider Architecture

This document describes how SofaWatch integrates with external metadata providers and how the provider layer should evolve as additional sources are introduced.

The goal is to keep SofaWatch's domain independent from any specific provider while still allowing provider-specific capabilities where they add value.

> [!NOTE]
> TMDB is currently the primary metadata provider. TVDB is planned as a complementary provider. IMDb or another legitimate source may later be evaluated for external identifiers and ratings.

---

## 1. Goals

The provider architecture is designed to:

- keep SofaWatch domain identity independent from external APIs
- isolate provider-specific HTTP and response formats
- support multiple providers over time
- define clear metadata ownership
- allow fallback between providers
- avoid duplicating business rules per provider
- support matching/cross-identification
- allow secondary provider failures without breaking local media
- separate personal ratings from external ratings
- make provider health and configuration explicit
- preserve user-owned data during metadata synchronization

---

## 2. High-Level Model

The intended direction is:

```text
SofaWatch Domain
       ^
       |
Provider Mapping / Application Services
       ^
       |
   Provider Clients
       |
       +-- TMDB
       +-- TVDB
       +-- IMDb / external source
```

Provider clients know external APIs.

Application services decide how provider data is imported, merged, synchronized, and persisted.

The domain should not depend directly on TMDB, TVDB, or IMDb response models.

---

## 3. Internal vs External Identity

SofaWatch uses internal IDs for local entities.

External provider IDs are mappings.

Example:

```text
TMDB Show ID 1396
        |
        v
Import / Match
        |
        v
SofaWatch Show ID 42
```

After import:

```text
Show.id = 42
```

is the internal identity used by SofaWatch relationships.

The provider ID remains external metadata.

This allows the same local Show to later be associated with multiple providers:

```text
SofaWatch Show 42
      |
      +-- TMDB: 1396
      +-- TVDB: 81189
      +-- IMDb: tt0903747
```

The exact persistence model may evolve, but the conceptual separation should remain.

---

## 4. Why Provider IDs Must Not Become Domain IDs

Using TMDB IDs directly as SofaWatch primary keys would couple local data to TMDB.

That would make future provider changes much harder.

It would also blur ownership between:

- SofaWatch data
- provider metadata
- user-specific state

Internal identity allows:

- provider replacement
- multiple providers
- rematching
- imports from additional sources
- local records even when provider data is unavailable

---

## 5. Current Provider: TMDB

TMDB is currently the primary provider.

It is used for:

- Search
- TV metadata
- Movie metadata
- Seasons
- Episodes
- Genres
- Images
- Trending
- Popular content
- discovery
- metadata synchronization

TMDB-specific request/response logic should remain isolated in provider/data-layer components.

---

## 6. Future Provider: TVDB

TVDB is planned primarily as a complementary TV provider.

Potential uses include:

- Show metadata
- Season metadata
- Episode metadata
- episode numbering
- air dates
- aliases
- alternative titles
- external IDs
- improved matching
- metadata fallback
- potentially air times if reliably supplied
- provider health diagnostics

TVDB should not be added by scattering `tvdb_id` fields throughout business logic.

Instead, provider mappings should be explicit.

---

## 7. Future IMDb / External Ratings Source

IMDb itself or another legitimate data source may be evaluated later.

Potential uses:

- IMDb IDs
- cross-provider matching
- external ratings
- rating vote counts
- external links
- complementary metadata

Any integration should first evaluate:

- legal data access
- API stability
- licensing
- rate limits
- update policy
- availability of rating and vote-count data
- identifier quality

Fragile scraping should not become a core dependency.

---

## 8. Provider Boundaries

Provider code should own:

- HTTP communication
- provider authentication
- provider-specific DTOs/schemas
- provider-specific request parameters
- provider-specific errors
- provider rate-limit behavior
- provider timeouts
- response parsing

Provider code should not own:

- Library state
- watch progress
- rewatches
- user ratings
- registration
- authorization
- SofaWatch status rules

---

## 9. Application-Service Responsibilities

Application services decide how provider data is used.

Examples:

- import a Show
- import a Movie
- match existing media to another provider
- refresh metadata
- choose a fallback provider
- merge metadata
- preserve user-owned state
- decide whether a failed secondary provider is fatal

This keeps provider clients focused and makes provider orchestration testable.

---

## 10. DTO / Mapping Boundary

Provider responses should be mapped before becoming local domain/persistence data.

Conceptually:

```text
TMDB JSON
    |
    v
TMDB DTO
    |
    v
Provider Mapping
    |
    v
SofaWatch Data
```

The same applies to future providers:

```text
TVDB JSON
    |
    v
TVDB DTO
    |
    v
Provider Mapping
    |
    v
SofaWatch Data
```

Do not pass raw provider JSON through services and repositories.

---

## 11. External Identifier Model

The long-term architecture should support multiple external IDs per local entity.

Conceptually:

```text
ExternalIdentifier
------------------
media/entity
provider
external_id
type/scope if needed
```

Potential provider values:

```text
TMDB
TVDB
IMDb
```

Potential entity scopes:

```text
Show
Season
Episode
Movie
Person
```

The exact database model should be introduced only when needed by real provider integration.

Do not prematurely over-generalize if a simpler mapping table solves the immediate problem cleanly.

---

## 12. Genre Provider Mappings

Genre is an internal SofaWatch entity.

Provider mappings connect local genres to external provider taxonomies.

Conceptually:

```text
SofaWatch Genre
      |
      +-- TMDB TV genre
      +-- TMDB Movie genre
      +-- future TVDB mapping
```

This avoids treating a provider-specific genre ID as the internal Genre identity.

---

## 13. Provider Precedence

Once multiple providers exist, metadata precedence must be explicit.

Possible fields include:

- title
- original title
- overview
- poster
- backdrop
- genres
- runtime
- release date
- air date
- episode numbering
- networks
- aliases
- external ratings

A provider should not silently overwrite another provider's preferred field without a rule.

---

## 14. Primary vs Secondary Provider

A simple initial model may be:

```text
Primary metadata provider: TMDB
Secondary provider: TVDB
External rating provider: IMDb / approved source
```

This does not mean TMDB must remain primary forever.

The architecture should support changing precedence later.

---

## 15. Field-Level Precedence

Provider precedence may need to be field-specific.

Example:

```text
Title
  -> TMDB preferred
  -> TVDB fallback

Episode numbering
  -> TVDB preferred
  -> TMDB fallback

Poster
  -> TMDB preferred

IMDb rating
  -> IMDb source only
```

This is better than one global "provider priority" if providers have different strengths.

---

## 16. Fallback Rules

Fallback should be explicit.

Example:

```text
TMDB overview exists?
    |
    +-- yes --> use TMDB
    |
    +-- no --> TVDB overview exists?
                  |
                  +-- yes --> use TVDB
                  |
                  +-- no --> keep existing/local value
```

Fallback should not cause unnecessary data churn.

A lower-priority provider should not replace a valid preferred value merely because it responded later.

---

## 17. Missing Data

Providers may legitimately omit fields.

Missing external data should not automatically erase useful local data.

Synchronization logic should distinguish:

```text
Provider returned null intentionally
vs
Provider response omitted field
vs
Provider request failed
```

Where possible, mapping logic should preserve existing values when the provider cannot supply a reliable replacement.

---

## 18. Provider Failure Strategy

Provider failures should be classified.

Examples:

- network failure
- timeout
- unauthorized/misconfigured provider
- rate limit
- 404/not found
- malformed response
- provider server error

These should be translated into SofaWatch-level errors.

The frontend should not depend on raw provider exception types.

---

## 19. Primary Provider Failure

If a required primary-provider operation fails during a user-requested import/search, the operation may need to fail.

Example:

```text
Search TMDB
   |
   +-- failure
          |
          v
Safe provider error to client
```

The failure should be explicit and retryable where appropriate.

---

## 20. Secondary Provider Failure

A secondary provider failure should often degrade gracefully.

Example:

```text
Refresh local Show
   |
   +-- TMDB succeeds
   |
   +-- TVDB fails
          |
          v
Persist valid TMDB refresh
Record/log TVDB failure
```

Whether this is allowed depends on the operation.

Provider orchestration should define which sources are mandatory vs optional.

---

## 21. Existing Local Media Should Remain Usable

Once media has been imported into SofaWatch, provider outages should not make it unusable.

Existing local data such as:

- title
- poster path/reference
- seasons
- episodes
- Library state
- watch history

should remain available where possible.

Provider availability affects freshness and discovery more than basic local usability.

---

## 22. Metadata Ownership

Provider-owned metadata includes examples such as:

- titles
- overviews
- images
- release/air dates
- provider ratings
- cast
- provider external IDs

SofaWatch-owned state includes:

- internal IDs
- Library membership
- tracking status
- watch events
- watched state
- ratings entered by the user
- user ownership
- local administrative/security state

Synchronization must never overwrite SofaWatch-owned state using provider data.

---

## 23. Personal Ratings vs External Ratings

Personal ratings and provider ratings are separate concepts.

Conceptually:

```text
SofaWatch Personal Rating
        |
        +-- user-entered rating

External Ratings
        |
        +-- TMDB rating
        +-- IMDb rating
        +-- future sources
```

Do not silently average or merge these into one number without an explicit product rule.

---

## 24. External Rating Model

A future external rating structure may include:

```text
provider
rating
scale
vote_count
updated_at
```

Example:

```text
TMDB
8.2 / 10
votes: 12345

IMDb
8.7 / 10
votes: 234567

SofaWatch
9 / 10
personal
```

Provider rating values should retain their original meaning and provenance.

---

## 25. Search Architecture

Search currently uses TMDB.

Future provider-aware Search might support:

- primary-provider results
- complementary matching
- alias resolution
- cross-provider IDs

However, Search should continue to expose one normalized SofaWatch-facing contract.

Conceptually:

```text
Provider Search Result
        |
        v
Normalization
        |
        v
SearchMediaResult
```

The frontend should not need separate rendering logic per provider.

---

## 26. Import Architecture

Import converts provider data into local SofaWatch entities.

Conceptually:

```text
Search Result
    |
    v
Import Request
    |
    v
Provider Fetch
    |
    v
Mapping
    |
    v
Local Entity
```

Import should be idempotent where appropriate.

If the entity already exists for the same provider mapping, the operation should reuse/update the local entity instead of creating duplicates.

---

## 27. Matching Architecture

With multiple providers, SofaWatch will need explicit matching rules.

Possible signals include:

- external IDs
- IMDb ID
- title
- original title
- release year
- first air date
- runtime
- episode structure

Direct shared external identifiers are stronger than fuzzy title matching.

Matching should have confidence rules and avoid silently merging unrelated media.

---

## 28. Matching Priority

A possible priority order:

```text
1. Existing provider mapping
2. Shared authoritative external ID
3. Strong exact metadata match
4. Fuzzy/heuristic match
5. Manual review / no match
```

Heuristic matching should not automatically create permanent cross-provider links without sufficient confidence.

---

## 29. Provider Aliases

TVDB or another provider may provide aliases/alternative titles.

Aliases can improve:

- matching
- Search
- localization
- title fallback

Aliases should be modeled as provider/local metadata rather than replacing the canonical title blindly.

---

## 30. Episode Numbering

Episode numbering is a particularly sensitive provider area.

Different providers may represent:

- aired order
- DVD order
- absolute order
- specials
- split seasons

Before TVDB integration, SofaWatch should define which numbering system is canonical for the product.

Provider-specific numbering may need mappings rather than overwriting local episode identity.

---

## 31. Air Dates and Air Times

Air dates can be provider metadata.

Air times should only be added if a provider supplies reliable time data.

Do not infer air time from:

- air date
- timezone guesses
- release patterns
- network assumptions

If provider quality is insufficient, leave the time unknown.

---

## 32. Images

Image precedence should eventually be explicit.

Potential sources:

- TMDB poster
- TMDB backdrop
- TVDB artwork
- future provider artwork

Possible criteria:

- source priority
- resolution
- aspect ratio
- language
- availability

Do not overwrite a good existing image with a lower-quality fallback without a rule.

---

## 33. Localization

Provider requests may be language-aware.

Current TMDB integration already supports language configuration.

Future providers should define:

- supported language format
- fallback language
- localized titles
- localized overviews
- image-language handling

SofaWatch localization and provider-language selection should remain related but distinct concerns.

---

## 34. Provider Configuration

Provider credentials and settings belong on the backend.

Examples:

```text
TMDB API token
TVDB API key
TVDB PIN
provider base URLs
timeouts
```

These must not be embedded in Flutter clients.

Configuration should be validated safely at startup/use.

---

## 35. Provider Health

Provider health diagnostics should reflect real integrations.

TMDB health may include:

- configured
- reachable
- latency

TVDB health should only be added once TVDB is actually integrated.

Do not expose fictional provider status for a provider that the application cannot use.

---

## 36. Health Degradation

Provider health affects overall server health differently from database health.

A possible model:

```text
Database unavailable
    -> severe/unavailable behavior

TMDB unavailable
    -> degraded, but local media remains usable
```

The exact overall health calculation should reflect operational impact.

---

## 37. Rate Limits

Provider clients should handle rate limits explicitly.

Potential strategies:

- respect provider response headers
- bounded retry where safe
- avoid aggressive automatic retries
- cache where appropriate
- stagger background synchronization

Do not hide repeated rate-limit failures behind endless retries.

---

## 38. Timeouts

Each provider should have explicit timeout configuration.

Provider calls must not block indefinitely.

Timeouts should be translated into safe application errors and be distinguishable from generic network failure where useful.

---

## 39. Caching

Caching should be introduced per use case.

Current Search cache is:

- in-memory
- TTL-based
- LRU-bounded

Future provider caches may differ.

Do not create one universal provider cache without clear semantics around:

- freshness
- invalidation
- user-specific vs global data
- memory/storage limits

---

## 40. Metadata Synchronization

Metadata sync refreshes provider-owned fields for already imported entities.

Conceptually:

```text
Local Entity
    |
    v
Is refresh needed?
    |
    +-- no --> skip
    |
    +-- yes
          |
          v
Provider fetch
          |
          v
Mapping/precedence rules
          |
          v
Persist metadata changes
```

Sync should preserve user-owned data.

---

## 41. Synchronization with Multiple Providers

A future multi-provider sync may look like:

```text
Local Show
   |
   +--> TMDB refresh
   |
   +--> TVDB refresh
   |
   v
Merge according to precedence
   |
   v
Persist
```

The workflow should define:

- which provider is mandatory
- which provider is optional
- what happens on partial failure
- which fields each provider may update

---

## 42. Partial Synchronization Failures

A multi-provider refresh may partially succeed.

Example:

```text
TMDB: success
TVDB: timeout
```

Possible outcome:

- persist valid TMDB updates
- leave TVDB-owned fields unchanged
- record structured partial failure
- do not mark the entire local media object unusable

Background job result models should eventually make this visible where useful.

---

## 43. Manual vs Automatic Refresh

Manual refresh may be allowed to force provider calls.

Automatic refresh should respect freshness policy.

Conceptually:

```text
Automatic
   |
   +-- respect metadata refresh age

Manual
   |
   +-- may bypass age policy
```

Provider-specific rate limits should still be respected.

---

## 44. Ended/Canceled Shows

Automatic refresh policy may treat ended/canceled Shows differently.

Normalization should eventually handle provider variants such as:

```text
Ended
Canceled
Cancelled
```

Status normalization belongs in application/provider mapping logic rather than being duplicated across background jobs and UI.

---

## 45. Provider-Specific Metadata Persistence

Not all provider fields need to become first-class columns immediately.

Possible strategies:

- normalized local fields for product-critical metadata
- mapping tables for external identifiers
- external-rating table
- provider-specific extension data only when truly needed

Avoid storing large opaque provider blobs unless there is a clear operational reason.

---

## 46. Provider Versioning and API Changes

External APIs evolve.

Provider clients should isolate change impact.

If TMDB changes a response field:

```text
TMDB Client / DTO
        |
        v
Mapping fix
```

should ideally be enough.

The frontend and most business services should remain unaffected.

---

## 47. Provider Testing

Provider tests should not depend on live APIs for normal test runs.

Test:

- request construction
- authentication headers
- query parameters
- response parsing
- mapping
- missing fields
- malformed responses
- provider errors
- timeouts
- rate-limit behavior where implemented

Use fixtures/mocks.

Live integration tests, if ever added, should be explicit and separate.

---

## 48. Matching Tests

Future multi-provider matching tests should cover:

- existing direct mapping
- shared IMDb ID
- exact title/year
- alternate titles
- ambiguous matches
- no match
- false-positive prevention

Matching code should favor correctness over aggressive automatic linking.

---

## 49. Precedence Tests

When multiple providers exist, tests should verify field-level precedence.

Example:

```text
TMDB overview exists
TVDB overview differs

Expected:
TMDB overview retained
```

and:

```text
TMDB overview missing
TVDB overview exists

Expected:
TVDB fallback used
```

Rules should be explicit enough that tests read like product decisions.

---

## 50. External Ratings Tests

Future external rating tests should verify:

- provider provenance
- scale
- vote count
- missing rating
- refresh behavior
- separation from personal rating

Personal rating changes must not mutate external ratings.

---

## 51. Provider Anti-Patterns to Avoid

Avoid:

- using TMDB IDs as SofaWatch primary keys
- spreading `tmdb_id`/`tvdb_id` logic throughout business services
- exposing raw provider JSON to Flutter
- making frontend widgets provider-aware unnecessarily
- treating provider ratings as personal ratings
- silently overwriting preferred metadata without precedence rules
- inventing air times
- hardcoding provider-specific genres as internal Genre identity
- blocking local media usage because a secondary provider is down
- scraping unstable sources for core functionality
- adding generic abstractions before a second real provider exists
- swallowing provider failures without observability

---

## 52. Incremental Evolution Strategy

Provider architecture should evolve in stages.

### Stage 1 — Current

```text
TMDB
  |
  v
SofaWatch
```

### Stage 2 — External Identifier Generalization

```text
SofaWatch Entity
   |
   +-- TMDB mapping
   +-- TVDB mapping
```

### Stage 3 — Complementary TV Metadata

```text
TMDB + TVDB
      |
      v
Explicit merge/precedence
      |
      v
SofaWatch
```

### Stage 4 — External Ratings

```text
SofaWatch Media
   |
   +-- Personal Rating
   +-- TMDB Rating
   +-- IMDb Rating
```

Each stage should solve a real product need before moving to the next.

---

## 53. Open Decisions Before TVDB

Before implementing TVDB, decide:

- exact authentication model
- external identifier persistence shape
- canonical Episode numbering strategy
- matching rules
- field-level precedence
- fallback rules
- sync frequency
- whether TVDB is optional or required for any operation
- error/partial-failure behavior
- which metadata TVDB is expected to improve

These decisions should be written down before provider behavior spreads through the codebase.

---

## 54. Open Decisions Before IMDb / External Ratings

Before implementing external IMDb ratings, decide:

- approved data source
- licensing
- update cadence
- cache strategy
- rating scale representation
- vote-count storage
- external-link behavior
- provider availability expectations

Do not implement against an unreliable source merely to display an IMDb number.

---

## 55. Relationship with the Domain

Provider architecture exists to protect the domain.

The desired result is that application code can reason about:

```text
Show
Movie
Season
Episode
Genre
ExternalRating
```

without constantly asking:

```text
Is this from TMDB?
Is this from TVDB?
```

Provider-specific behavior should only be visible where provenance is materially important.

---

## 56. Relationship with the Frontend

The frontend should receive normalized SofaWatch API contracts.

For example, Search should expose a common result shape.

Media Details should expose local media plus external metadata in a provider-neutral way where possible.

If external ratings are shown, provenance should be explicit because the source matters:

```text
TMDB 8.2
IMDb 8.7
```

But the widget should not need to understand provider HTTP APIs.

---

## 57. Relationship with Background Jobs

Background metadata jobs should reuse the same provider/application services as manual refresh operations where possible.

Do not implement separate provider merge rules only for scheduled jobs.

Conceptually:

```text
Manual Refresh --------+
                       |
                       v
                 Metadata Service
                       ^
                       |
Scheduled Job ---------+
```

This prevents behavior drift.

---

## 58. Relationship with Server Diagnostics

Provider diagnostics should consume provider health abstractions rather than reimplement health logic in route/UI layers.

Potential normalized health contract:

```text
configured
reachable
latency
```

Provider-specific diagnostics may expand only when there is a real operational need.

---

## 59. Security

Provider secrets must remain backend-only.

Never expose:

- TMDB token
- TVDB API key
- TVDB PIN
- future provider credentials

through:

- API responses
- diagnostics
- logs
- Flutter configuration
- export files

Errors should not accidentally include authenticated request URLs or headers containing secrets.

---

## 60. Future Architectural Work

Known future provider work includes:

- external identifier mapping model
- TVDB client
- TVDB matching
- field-level precedence
- fallback rules
- provider-aware metadata synchronization
- TVDB health
- external rating model
- IMDb/approved source evaluation
- provider-specific localization rules
- additional provider contract tests

---

## Related Documentation

- [Architecture Overview](overview.md)
- [Backend Architecture](backend.md)
- [Authentication Architecture](authentication.md)
- [Metadata Synchronization](../features/metadata-sync.md)
- [Implementation Status](../features/implementation-status.md)
- [Backend README](../../backend/README.md)
