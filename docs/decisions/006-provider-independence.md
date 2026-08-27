# ADR-006: Provider-Independent Domain Architecture

- Status: Accepted
- Date: 2026-08-27

## Context

SofaWatch depends on external metadata to provide useful information about TV Shows and Movies.

TMDB is currently the primary metadata provider and supplies data used for capabilities such as:

- Search;
- TV Show metadata;
- Movie metadata;
- Seasons;
- Episodes;
- genres;
- images;
- Trending;
- Popular/discovery content;
- metadata synchronization.

Future integrations are expected or being evaluated.

TVDB is a planned complementary provider, particularly for TV metadata.

Potential uses include:

- Show metadata;
- Seasons;
- Episodes;
- Episode numbering;
- air dates;
- air times where reliable;
- aliases and alternate titles;
- matching and cross-provider identification;
- metadata that may be missing or more appropriate than TMDB data.

IMDb, or another legitimate source capable of supplying IMDb-related identifiers and ratings, may also be evaluated.

Potential uses include:

- IMDb identifiers;
- cross-provider matching;
- external ratings;
- vote counts;
- external links;
- complementary metadata.

If SofaWatch allows its domain and business logic to become synonymous with TMDB, adding these providers later would require provider-specific conditions throughout the application.

For example:

```text
if tmdb_id ...
if tvdb_id ...
if imdb_id ...
```

could begin appearing in:

- domain entities;
- services;
- Library logic;
- viewing history;
- Statistics;
- Flutter models;
- navigation;
- database relationships.

That would make the application increasingly difficult to evolve and would incorrectly make external provider identity part of SofaWatch's own domain.

---

## Decision

SofaWatch's **domain and core business rules remain independent from individual metadata providers**.

External providers are accessed through explicit integration boundaries.

Conceptually:

```text
SofaWatch Domain
       ^
       |
normalized provider data / mappings
       ^
       |
Provider adapters
   |       |       |
   v       v       v
 TMDB    TVDB    IMDb /
                ratings source
```

TMDB is the primary provider today.

That operational fact does not make TMDB the SofaWatch domain model.

Provider-specific identifiers, requests, responses, errors, and authentication belong at provider/integration boundaries.

---

## Provider Independence Does Not Mean Provider Uniformity

Different providers have different strengths and different data models.

SofaWatch should not force every provider into a fictional lowest-common-denominator API.

For example:

```text
TMDB
-> strong discovery/search/images

TVDB
-> potentially useful TV/Episode metadata and numbering

IMDb / ratings source
-> external identifiers/ratings
```

Provider independence means SofaWatch controls how these capabilities enter its domain.

It does not mean every provider must implement every capability.

---

## Domain Identity

SofaWatch media uses internal identity after import.

Example:

```text
SofaWatch Show 42
       |
       +--> TMDB mapping
       +--> TVDB mapping
       +--> IMDb mapping
```

The provider mappings identify external representations of the same local media.

This follows [ADR-003](003-internal-media-ids.md).

---

## Provider Adapters

Provider-specific clients/adapters should encapsulate concerns such as:

- authentication;
- endpoint paths;
- query parameters;
- provider DTOs;
- provider pagination;
- rate-limit behavior;
- provider-specific errors;
- response parsing.

Higher application layers should consume normalized data or provider capability contracts rather than raw provider JSON.

---

## Conceptual Flow

A metadata flow should look like:

```text
Service
   |
   v
Provider abstraction / client
   |
   v
TMDB API
   |
   v
TMDB response DTO
   |
   v
normalization / mapping
   |
   v
SofaWatch entity/update
```

not:

```text
Route
  |
  +--> parse TMDB JSON
  +--> update database
  +--> expose TMDB fields directly to Flutter
```

---

## Provider DTOs

External API response models belong to provider/data integration code.

They should not become domain entities merely because their fields look similar.

Provider DTOs can contain provider-specific details.

Mapping converts them into the concepts SofaWatch needs.

---

## Flutter Boundary

Flutter should generally consume SofaWatch API contracts rather than call metadata providers directly.

Conceptually:

```text
Flutter
   |
   v
SofaWatch API
   |
   v
Provider integration
```

This keeps:

- provider credentials out of clients;
- provider rules centralized;
- Web/iOS/Android consistent;
- provider replacement possible without rewriting every client.

---

## Search

Global Search currently uses TMDB-backed results.

The architectural identity is still:

```text
SofaWatch Search
```

not:

```text
TMDB Search
```

The backend normalizes provider results into a common media Search contract.

If Search later uses another provider or aggregates providers, the global Search experience should not need to become an entirely new client feature.

See [ADR-004](004-global-search.md).

---

## Search Results and Provider Identity

Before import, a Search result may need provider identity:

```text
provider = TMDB
provider_id = ...
media_type = SHOW
```

That is appropriate because the result has not necessarily become a local SofaWatch entity.

Once imported, local operations use SofaWatch identity.

Provider independence does not require hiding provider identity where it is genuinely relevant.

---

## Import

Import is an explicit provider boundary.

A provider-specific import route such as:

```text
POST /api/v1/movies/import/tmdb/{tmdb_id}
```

is valid because the operation explicitly means:

```text
resolve/import this TMDB resource into SofaWatch
```

The resulting entity is then a SofaWatch Movie with an internal ID.

---

## Metadata Synchronization

Synchronization refreshes provider-owned metadata associated with existing SofaWatch entities.

Conceptually:

```text
SofaWatch Show
      |
      v
provider mapping
      |
      v
TMDB
      |
      v
normalized metadata
      |
      v
update selected local metadata
```

The local entity is not replaced by the provider object.

---

## Provider Ownership of Metadata

Provider independence requires explicit thinking about which source owns which metadata.

Current TMDB-backed fields may include concepts such as:

- titles;
- overview;
- images;
- genres;
- dates;
- Episode metadata.

When multiple providers exist, SofaWatch should define precedence rather than allowing whichever provider ran last to overwrite everything.

---

## Metadata Precedence

Future multi-provider synchronization should establish rules such as:

```text
field
-> primary provider
-> optional fallback provider
-> local override behavior, if supported
```

Example conceptually:

```text
poster
-> TMDB primary

Episode numbering
-> provider rule to be decided

external rating
-> provider-specific, never merged implicitly
```

The exact precedence rules are intentionally deferred until the relevant provider integrations exist.

This ADR requires those rules to be explicit when needed.

---

## Fallback Metadata

A secondary provider may fill missing metadata.

However, fallback should be distinguishable from arbitrary overwrite behavior.

Conceptually:

```text
primary value exists
-> keep primary according to precedence rule

primary value missing
-> consider fallback
```

More complex rules may be appropriate for specific fields.

---

## Provider Failure

Failure of one metadata provider should be contained according to the operation.

Examples:

### Search

If the only active Search provider is unavailable, Search may fail with a normalized provider error.

### Existing Local Media

An existing imported Show should not cease to exist because TMDB is unavailable.

Local data such as:

```text
Library
History
Progress
Personal Ratings
```

should remain valid.

### Secondary Provider

In a future multi-provider sync, failure of an optional secondary provider should not necessarily invalidate successful primary-provider work.

Partial failure behavior should be explicit.

---

## Error Mapping

Raw provider exceptions should not leak through the public API.

Conceptually:

```text
TMDB exception
      |
      v
provider error mapping
      |
      v
SofaWatch API error
      |
      v
Flutter AppException
```

The client should receive safe application-level errors rather than internal provider stack traces or implementation details.

---

## Provider Timeouts

Provider calls should have explicit timeout behavior.

A slow provider must not hold application requests indefinitely.

Timeout configuration should be validated and provider failures mapped into the common API error strategy.

---

## Rate Limits

Each provider may impose different rate limits.

Rate-limit handling belongs to provider integration/application orchestration.

The domain should not contain assumptions such as:

```text
TMDB allows N requests
```

unless the rule is genuinely needed by a provider-specific component.

---

## Provider Authentication

Provider API keys/tokens are server configuration.

They must not be sent to Flutter clients.

Secrets should be:

- loaded through configuration;
- excluded from logs;
- excluded from API diagnostics;
- represented only as configured/not configured where appropriate.

---

## Health Checks

Provider health diagnostics should reflect real integrations.

Current TMDB diagnostics may report concepts such as:

```text
configured
reachable
latency
```

TVDB diagnostics should only be added after a real TVDB integration exists.

Do not display fictional:

```text
TVDB: healthy
```

when no TVDB client/configuration exists.

---

## TVDB Integration

TVDB is a planned provider.

Before implementation, SofaWatch should define:

1. current TVDB API/authentication requirements;
2. provider client boundary;
3. provider DTOs;
4. error mapping;
5. rate-limit handling;
6. timeout behavior;
7. external identifier mappings;
8. Show matching;
9. Season matching;
10. Episode matching;
11. aliases;
12. air-date/time behavior;
13. metadata precedence;
14. synchronization rules;
15. health/configuration reporting;
16. tests.

The integration should extend provider architecture rather than spread `tvdb_id` conditionals throughout the codebase.

---

## TVDB and Episode Numbering

Episode identity and numbering are a particularly important multi-provider problem.

Providers may differ on:

- specials;
- season numbering;
- alternate orders;
- Episode numbering;
- air-date interpretation.

SofaWatch must not assume:

```text
TMDB Episode X
```

and:

```text
TVDB Episode Y
```

are identical merely because season/episode numbers happen to match.

Matching rules should be explicit and testable.

---

## Air Times

SofaWatch currently has reliable air-date concepts but should not invent air times.

If TVDB or another provider later supplies sufficiently reliable air-time data, SofaWatch may add it through an explicit provider/domain mapping.

Until then:

```text
unknown air time
```

is preferable to fabricated precision.

---

## IMDb

IMDb integration is not assumed to mean direct use of an unofficial scraper.

Before implementation, SofaWatch should evaluate:

- legitimate API/data source;
- licensing/terms;
- stability;
- rate limits;
- update frequency;
- available identifiers;
- rating availability;
- vote count availability.

A provider-independent architecture makes this evaluation possible without committing the domain to a particular source prematurely.

---

## No Fragile Scraping as Core Architecture

SofaWatch should not make an unstable scraping implementation a foundational dependency for IMDb data.

If an external rating source is added, it should be sufficiently legitimate and stable for the intended use.

This is especially important for self-hosted software expected to continue functioning without frequent emergency fixes to HTML parsers.

---

## External Ratings

External ratings and personal SofaWatch ratings are separate concepts.

Conceptually:

```text
SofaWatch Movie
      |
      +--> Personal Rating
      |
      +--> TMDB Rating
      |
      +--> IMDb Rating
```

Do not automatically combine them into one rating.

---

## Rating Source

An external rating should preserve source identity.

Conceptually:

```text
source
rating
scale
vote_count
updated_at
```

where appropriate.

A value such as:

```text
8.4
```

without source/scale context is insufficient for a multi-provider ratings model.

---

## Rating Scale

Providers may use different rating scales.

SofaWatch should not silently normalize them into a single number unless a deliberate product rule defines how.

Display can adapt:

```text
TMDB   8.2 / 10
IMDb   8.7 / 10
You    9 / 10
```

while preserving the underlying source semantics.

---

## Genres

Genres are internal SofaWatch entities rather than direct aliases for one provider taxonomy.

Conceptually:

```text
SofaWatch Genre
      |
      +--> TMDB TV genre mapping
      +--> TMDB Movie genre mapping
      +--> future TVDB mapping
```

This allows provider taxonomies to differ without redefining the local Genre identity.

---

## Images

Images may be provider-backed metadata.

Future multi-provider support should define image precedence intentionally.

Potential considerations include:

- image quality;
- language;
- aspect ratio;
- provider availability;
- caching;
- fallback.

Do not assume every provider image URL is interchangeable or permanent.

---

## Language

Provider requests may depend on the user's/application language.

Future localization support should define how language preference flows through:

```text
Flutter preference
      |
      v
SofaWatch API
      |
      v
provider request language
```

Fallback behavior should be explicit.

Provider independence means each adapter can translate SofaWatch language intent into the provider's supported language semantics.

---

## Caching

Provider-specific caching may be useful, but caching is not itself part of the domain.

Current Search cache is deliberately small and bounded.

Future provider caches should be added based on measured need.

Do not create one large generic provider cache abstraction before different providers demonstrate common requirements.

---

## Background Jobs

Metadata synchronization jobs should call application/provider services rather than implement provider HTTP logic directly inside job runners.

Conceptually:

```text
Background Job
      |
      v
Metadata Sync Service
      |
      v
Provider integration
```

This keeps provider behavior reusable between:

- manual refresh;
- scheduled refresh;
- import/sync flows.

---

## Provider-Specific Jobs

A future provider may require specialized maintenance.

Such jobs can exist when necessary.

They should still avoid leaking provider concerns into unrelated domain features.

---

## API Contracts

Public SofaWatch API responses should prefer SofaWatch concepts.

Provider-specific fields may be exposed when they are genuinely useful, for example external identifiers.

But clients should not need to understand raw TMDB response schemas to render core SofaWatch screens.

---

## Database Design

Current models may contain provider-specific fields due to the existing TMDB implementation.

The long-term direction is toward extensible provider mappings where that improves multi-provider support.

Possible conceptual structure:

```text
ExternalIdentifier
------------------
local entity
provider
provider entity type
external ID
```

The exact schema is deliberately not fixed by this ADR.

Avoid premature migrations before the second provider creates a real requirement.

---

## Avoiding Premature Abstraction

Provider independence does **not** require immediately building:

```text
AbstractProviderFactoryRegistryManager
```

or a large plugin framework.

The desired approach is incremental.

Today:

```text
clean TMDB boundary
```

Later:

```text
introduce shared abstraction when TVDB reveals real common behavior
```

This follows SofaWatch's KISS principle.

Abstractions should emerge from concrete provider requirements.

---

## Capability-Based Design

As multiple providers are introduced, capability-oriented interfaces may be more appropriate than one enormous provider interface.

Conceptually:

```text
SearchProvider
MetadataProvider
EpisodeProvider
ExternalRatingsProvider
```

rather than forcing every provider to implement:

```text
search
movies
shows
episodes
ratings
images
trending
everything else
```

This is a direction, not a requirement to introduce all interfaces immediately.

---

## Primary vs Secondary Providers

A future provider configuration may distinguish:

```text
primary metadata provider
secondary/fallback provider
ratings provider
```

SofaWatch should define these roles through explicit rules.

Provider order must not be determined accidentally by implementation order.

---

## Local Overrides

If SofaWatch later supports user/admin metadata overrides, those values introduce another source:

```text
local override
```

Precedence might then become:

```text
local override
primary provider
fallback provider
```

for selected fields.

This requires its own product/architecture decision when implemented.

---

## Observability

Provider diagnostics and logs should identify enough provider context to debug failures safely.

Useful information may include:

- provider name;
- operation;
- latency;
- normalized error category.

Do not log:

- provider API tokens;
- sensitive request headers;
- unnecessary full payloads.

---

## Testing

Provider integration should be tested at several boundaries.

### Provider Client Tests

Test:

- request construction;
- response parsing;
- authentication configuration;
- timeout/error mapping.

### Mapping Tests

Test:

```text
provider DTO
-> normalized/internal model
```

including missing/optional data.

### Service Tests

Test provider behavior within application rules without requiring live external requests.

### API Tests

Test public SofaWatch contracts rather than raw provider contracts.

### Multi-Provider Tests

When TVDB is introduced, add tests for:

- matching;
- precedence;
- fallback;
- provider failure isolation;
- conflicting metadata;
- external identifier uniqueness.

---

## Live Provider Tests

The normal automated suite should not depend on live external provider availability.

Tests should use mocks/fakes/fixtures at appropriate integration boundaries.

Optional manual/integration checks against live providers may exist separately.

This keeps CI and local tests deterministic.

---

## Consequences

### Positive

#### Provider Flexibility

SofaWatch can add TVDB, IMDb-related data, or other sources without redefining its entire domain.

#### Stable Local State

Library, History, Progress, and personal data remain independent from provider availability.

#### Cleaner Clients

Flutter consumes SofaWatch contracts rather than multiple external APIs.

#### Better Testing

Provider behavior can be isolated and mocked.

#### Safer Secrets

Provider credentials remain on the backend.

#### Explicit Metadata Rules

Multi-provider precedence/fallback must be deliberate rather than accidental.

---

### Trade-offs

#### Mapping Layer

Provider responses must be translated into SofaWatch concepts.

#### Cross-Provider Matching

Supporting multiple providers introduces non-trivial entity matching.

#### Metadata Conflicts

Providers may disagree, requiring precedence rules.

#### More Integration Code

Each provider needs its own client, DTOs, error handling, and tests.

#### Some Provider-Specific Concepts Remain

Provider independence does not eliminate legitimate provider-specific code.

It contains it.

---

## Alternatives Considered

### TMDB-Centric Domain

The domain could use TMDB IDs, response shapes, and terminology directly everywhere.

Rejected because it would make future provider integration expensive and fragile.

---

### Provider Calls Directly from Flutter

Rejected because it would:

- expose provider credentials or require client-specific auth workarounds;
- duplicate integration behavior across platforms;
- bypass backend normalization;
- complicate provider replacement;
- weaken centralized error handling.

---

### Build a Complete Generic Provider Framework Immediately

Rejected because only TMDB is currently implemented.

A generic framework designed without real TVDB/IMDb requirements would likely contain speculative abstractions.

The architecture should remain provider-independent while abstractions evolve incrementally.

---

### Store Every Provider's Metadata Separately Forever

SofaWatch could persist complete provider-specific copies and force the client to choose.

Rejected as the default domain model because the application needs coherent SofaWatch media entities.

Provider-specific raw data may be cached where useful, but it should not replace normalized application concepts.

---

### Automatically Merge Ratings

Rejected because ratings from different sources have distinct:

- populations;
- scales;
- vote counts;
- methodologies.

They should remain source-specific unless a future explicit aggregation rule is introduced.

---

## Revisit When

The principle of provider independence should only be reconsidered if SofaWatch intentionally becomes tied to one provider as a product requirement.

That is currently contrary to the roadmap.

More likely, this ADR will be extended by future decisions concerning:

### TVDB Integration

A future ADR may define concrete matching and metadata precedence rules after TVDB API behavior is evaluated.

### External Ratings

A future ADR may define the external rating model and legitimate source.

### Metadata Overrides

A future ADR may define local override precedence.

### Provider Aggregation

If Search or discovery begins combining multiple providers simultaneously, ranking/deduplication may require a dedicated ADR.

These decisions refine provider independence rather than invalidate it.

---

## If a Provider Is Removed

Removing a provider should not require deleting SofaWatch user state.

The migration plan should consider:

- existing external mappings;
- persisted metadata;
- replacement provider matching;
- cached images/data;
- synchronization jobs;
- configuration;
- health diagnostics.

Local media identity remains stable under [ADR-003](003-internal-media-ids.md).

---

## Implementation Constraints

Code written under this decision should follow these rules:

```text
[ ] SofaWatch domain identity remains provider-independent
[ ] provider IDs are external identifiers/mappings
[ ] Flutter normally calls SofaWatch, not external metadata APIs
[ ] provider secrets remain backend-only
[ ] raw provider responses do not become public SofaWatch contracts by default
[ ] provider DTOs remain outside the core domain
[ ] provider errors are normalized before reaching clients
[ ] provider calls have explicit timeout behavior
[ ] rate-limit behavior stays in provider/integration layers
[ ] existing local media remains valid during provider outages
[ ] user state never depends on provider availability
[ ] TVDB health is not implemented before TVDB integration exists
[ ] air times are not invented when providers do not provide reliable values
[ ] IMDb-related integration uses a legitimate/stable source
[ ] fragile scraping is not a foundational metadata strategy
[ ] personal ratings remain separate from external ratings
[ ] external ratings preserve their source
[ ] multi-provider metadata precedence is explicit
[ ] abstractions are introduced incrementally rather than speculatively
[ ] tests do not normally require live provider APIs
```

---

## Relationship to Other Decisions

### SQLite

[ADR-001](001-sqlite.md) defines the local database used to persist normalized SofaWatch entities and provider mappings.

### Backend as Source of Truth

[ADR-002](002-backend-source-of-truth.md) establishes the backend as the authority that mediates provider data and local application state.

### Internal Media IDs

[ADR-003](003-internal-media-ids.md) provides the identity model required for multiple providers to map onto the same local media.

### Global Search

[ADR-004](004-global-search.md) ensures Search remains a SofaWatch capability even when its underlying provider strategy evolves.

### Authentication

[ADR-005](005-authentication-model.md) keeps user identity and session security independent from metadata providers.

---

## Related Documentation

- [Documentation Index](../README.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Background Jobs](../architecture/background-jobs.md)
- [API Overview](../api/overview.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [Show Search](../features/show-search.md)
- [Metadata Sync](../features/metadata-sync.md)
- [Implementation Status](../features/implementation-status.md)
