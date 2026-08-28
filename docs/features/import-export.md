# Import / Export

## Overview

Import / Export provides SofaWatch with controlled mechanisms for bringing viewing data into the application and taking user-owned application data out of it.

The feature has two related but distinct responsibilities:

```text
Import
-> ingest supported external or SofaWatch data
-> validate
-> normalize
-> resolve media
-> preserve meaningful historical state
-> persist through SofaWatch business rules

Export
-> read canonical SofaWatch data
-> serialize it into a documented portable format
-> allow users to retain or migrate their data
```

Import / Export is not the same as database backup and restore.

```text
Import / Export
-> application-level portability

Backup / Restore
-> operational recovery of the SofaWatch installation
```

This distinction is important because a portable export does not necessarily contain every database-level detail required to restore an installation exactly.

See:

- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [History](history.md)
- [Movies](movies.md)
- [Authentication](authentication.md)
- [Server Administration](server-administration.md)
- [Metadata Sync](metadata-sync.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)

---

## Status

**Planned / Partially Established**

The broader Import / Export architecture and product direction are established, while the complete end-user workflow remains future work.

Established principles include:

- user-owned data portability;
- backend-owned validation and persistence;
- internal SofaWatch IDs remain canonical;
- provider IDs are external identifiers;
- historical watch events are first-class data;
- rewatches remain individual events;
- historical timestamps should be preserved when known;
- imported data must remain user-scoped;
- imports should be idempotent or duplicate-aware where possible;
- partial failures should be reported without unnecessarily discarding successful work;
- exports should use a documented/versioned application format;
- imports should validate format/version before mutation;
- TMDB/provider resolution should remain separate from SofaWatch domain identity;
- application export is distinct from SQLite backup.

Future work includes the final file format, import preview/validation, provider matching, conflict handling, execution progress/results, export generation, administrator/user UI, compatibility policy, and tests.

See [Implementation Status](implementation-status.md).

---

# Goals

Import / Export should allow SofaWatch users to:

- retain ownership of their data;
- migrate between SofaWatch installations;
- import supported data from other tracking services;
- preserve historical viewing activity;
- preserve rewatches;
- preserve ratings where supported;
- preserve Library state where supported;
- inspect what will be imported;
- understand partial failures;
- retry unresolved items safely;
- export data in a documented portable format.

---

# Non-Goals

Import / Export is not:

- arbitrary database SQL import;
- raw database replacement;
- an unrestricted filesystem upload mechanism;
- a way to bypass user ownership;
- a way to trust external provider IDs as SofaWatch primary IDs;
- a guaranteed lossless importer for every third-party service;
- a substitute for operational SQLite backups.

---

# Core Principles

Import / Export follows these principles:

1. The backend owns validation and mutation.
2. SofaWatch internal IDs remain canonical.
3. External IDs are matching identifiers, not domain identity.
4. User ownership is derived from authenticated context.
5. Historical timestamps should be preserved when known.
6. Rewatches remain distinct watch events.
7. Import should avoid duplicate media and duplicate events.
8. Partial success should be explicit.
9. Imported files are untrusted input.
10. Export format should be versioned.
11. Import compatibility should be explicit.
12. Import should not silently destroy existing data.
13. Backup and Export remain separate concepts.

---

# Import Sources

SofaWatch can eventually support multiple import sources.

Conceptually:

```text
Import
├── SofaWatch export
├── Trakt
├── TV Time
└── future supported source
```

Each source can require its own adapter/parser while producing normalized SofaWatch import data.

Support should be added only when the source format can be handled reliably.

---

# Source Adapters

Third-party import parsing should remain separate from SofaWatch business logic.

Conceptually:

```text
Third-party file/data
        |
        v
Source Adapter
        |
        v
Normalized Import Model
        |
        v
Validation / Resolution
        |
        v
SofaWatch Services
        |
        v
Database
```

This prevents external file formats from leaking throughout the domain.

---

# Normalized Import Model

Source-specific adapters should map external data into a normalized intermediate representation.

Potential concepts include:

```text
ImportedMediaReference
ImportedWatchEvent
ImportedRating
ImportedLibraryEntry
ImportedUserPreference
```

The exact model should remain purpose-driven rather than attempting to mirror every third-party field.

---

# SofaWatch Export Import

Importing a SofaWatch-generated export should be the most deterministic migration path.

Because SofaWatch controls both ends of the format, it can preserve richer semantics than a third-party importer.

Potentially preserved information includes:

- Shows;
- Movies;
- Library status;
- Episode watch events;
- Movie watch events;
- rewatches;
- ratings;
- historical timestamps;
- selected user preferences.

---

# Third-Party Import

Third-party services may represent data differently.

Examples:

```text
watched flag only
```

versus:

```text
multiple individual watch events
```

or:

```text
show-level progress
```

versus:

```text
episode-level history
```

SofaWatch should preserve what the source actually provides and avoid inventing unsupported historical precision.

---

# Do Not Invent History

If an import source says only:

```text
Episode watched = true
```

but provides no date, SofaWatch should not fabricate an arbitrary historical timestamp and present it as fact.

The import model should explicitly handle missing historical dates according to the final domain rules.

---

# Historical Timestamps

When a source provides a trustworthy viewing timestamp:

```text
watched_at
```

SofaWatch should preserve it.

This is important because timestamps affect:

- History ordering;
- Statistics;
- streaks;
- weekly activity;
- rewatch analysis;
- recent activity.

---

# Rewatches

Rewatches are separate viewing events.

Example import:

```text
Episode 1
2025-01-10
2025-04-20
2026-02-03
```

should become three watch events rather than:

```text
watch_count = 3
```

with no event history.

The canonical event history then derives the current watch count/state.

---

# Event-Based History

Conceptually:

```text
Imported viewing records
        |
        v
EpisodeWatchEvent / MovieWatchEvent
        |
        +-> History
        +-> watched state
        +-> watch count
        +-> watched_at
        +-> Statistics
```

This keeps imported activity consistent with activity created natively in SofaWatch.

---

# User Ownership

Imports are user-scoped.

For ordinary user imports:

```text
authenticated user
-> owns imported Library/history/ratings
```

The client should not be trusted to submit an arbitrary owner ID.

---

# Administrator Imports

If administrator-assisted imports are added for another account, that must be an explicit privileged workflow.

It should not reuse an ordinary user endpoint with a casually supplied `user_id`.

---

# Media Resolution

Imported data often identifies media using external provider identifiers or text.

Resolution should prefer strong identifiers.

Conceptually:

```text
1. known SofaWatch/export identity mapping
2. TMDB ID
3. future TVDB ID
4. IMDb/provider ID where applicable
5. controlled metadata matching
6. unresolved
```

Exact precedence depends on the import source and provider architecture.

---

# Internal IDs

After resolution/import, SofaWatch uses its own internal IDs.

Example:

```text
external TMDB show ID
-> resolve/import Show
-> internal show.id
-> imported Library/history references internal ID
```

See [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md).

---

# Provider Independence

Import should not assume TMDB will always be the only provider.

Normalized media references can contain provider identifiers without making one provider's ID the SofaWatch primary key.

See [ADR-006: Provider Independence](../decisions/006-provider-independence.md).

---

# TVDB

Future TVDB integration can improve matching for sources that contain TVDB identifiers.

The resolver should use provider-specific identifiers through the external-ID architecture rather than adding TVDB-specific fields throughout unrelated domain logic.

---

# IMDb / External Ratings IDs

IMDb identifiers can be useful for matching Movies/Shows or external ratings integration.

They should remain provider/external identifiers.

The presence of an IMDb ID does not make it the SofaWatch entity ID.

---

# Metadata Import

When imported media does not yet exist locally:

```text
external identifier
-> metadata provider
-> import normalized media
-> assign SofaWatch internal ID
```

Existing media should be reused rather than duplicated.

---

# Existing Media

If the media already exists:

```text
match provider identifier
-> reuse internal entity
```

Importing History should not create a second copy of the same Show/Movie.

---

# Episode Resolution

Episode imports require stable resolution to SofaWatch Episode entities.

Strong matching typically uses:

```text
Show identity
+
season number
+
episode number
```

where the source provides those semantics.

Provider episode IDs can improve matching where available.

---

# Special Episodes

Specials and provider numbering differences can complicate episode matching.

The importer should not silently map uncertain records to arbitrary Episodes.

Unresolved or ambiguous records should be reported.

---

# Provider Numbering Differences

Future TVDB/TMDB support may expose different episode ordering/numbering schemes.

Import resolution must define which numbering scheme the source uses before assuming:

```text
S01E05
```

means the same provider episode in every dataset.

---

# Movie Resolution

Movie imports should prefer provider identifiers where available.

Fallback text matching can consider:

```text
title
year
```

but ambiguous matches require caution.

Do not silently choose the first similarly named Movie.

---

# Matching Confidence

If heuristic matching is introduced, matching confidence should be explicit.

Conceptually:

```text
exact
high confidence
ambiguous
unresolved
```

Automatic persistence should be limited to sufficiently reliable matches.

---

# Import Preview

A future import workflow should validate and preview before committing large mutations.

Conceptually:

```text
Select file
    |
    v
Parse
    |
    v
Validate
    |
    v
Resolve / Preview
    |
    v
Confirm
    |
    v
Import
```

---

# Preview Information

The preview can summarize:

```text
Shows found
Movies found
Watch events
Ratings
Library entries
Already existing
Unresolved
Invalid
```

This gives the user context before applying changes.

---

# Validation Before Mutation

Where practical, format-level validation should happen before any database mutation.

Examples:

- valid file;
- supported format;
- supported version;
- required fields;
- valid timestamps;
- valid enum values;
- bounded file size.

This reduces half-applied imports caused by obviously invalid input.

---

# Untrusted Files

Import files are untrusted input.

Never assume a user-uploaded JSON/CSV/archive is safe merely because it has the expected extension.

Validate:

- size;
- structure;
- encoding;
- types;
- nested depth where relevant;
- archive paths if archives are supported;
- filenames where applicable.

---

# File Size Limits

Import endpoints should enforce reasonable upload limits.

A malformed multi-gigabyte file should not be able to exhaust server memory.

Limits should be appropriate for realistic SofaWatch histories.

---

# Archive Safety

If ZIP or another archive format is ever accepted, protect against:

```text
path traversal / zip slip
decompression bombs
unexpected executable files
unbounded extracted size
```

Avoid archives entirely if they provide no meaningful benefit.

---

# Format Detection

Do not rely solely on the filename extension.

Source/format selection can be explicit, with content validation confirming the expected structure.

---

# Import Modes

Potential import semantics include:

```text
merge
```

and possibly more advanced modes later.

A destructive:

```text
replace everything
```

mode should not be introduced casually.

---

# Merge

The safest general default is merge-like behavior:

```text
existing data
+
new non-duplicate imported data
```

with clearly defined conflict rules.

---

# Replace

A future replace mode would be destructive and require:

- explicit scope;
- confirmation;
- backup guidance;
- transactional strategy;
- rollback semantics.

It is not required for the initial Import feature.

---

# Duplicate Handling

Import must define duplicates at the correct domain level.

Potential duplicates include:

```text
same media entity
same Library membership
same watch event
same rating
```

Each has different semantics.

---

# Media Duplicates

Provider/internal identity prevents duplicate media entities.

```text
same TMDB Movie
-> one SofaWatch Movie
```

---

# Library Duplicates

Importing a Library entry for media already in the user's Library should reconcile state rather than create duplicate membership rows.

Conflict rules depend on Library status semantics.

---

# Watch Event Duplicates

Watch events are more complex because legitimate rewatches look similar to duplicates.

Example:

```text
same Episode
different watched_at
-> legitimate rewatch
```

Whereas:

```text
same Episode
same exact source event/timestamp
imported twice
```

may be a duplicate.

---

# Import Idempotency

Running the same import twice should ideally not double the user's entire viewing History.

To support this, imports may use:

- source event IDs where available;
- source/import provenance;
- stable event fingerprints;
- exact timestamp/media matching where appropriate.

The final strategy should minimize both false duplicates and accidental rewatch loss.

---

# Event Fingerprints

If fingerprints are used, they should be domain-aware.

Conceptually:

```text
source
source_event_id
```

is stronger than heuristically treating:

```text
same media + same calendar day
```

as duplicate.

Two legitimate rewatches can occur on the same day.

---

# Import Provenance

Persisting limited provenance can help idempotency and diagnostics.

Potential safe metadata:

```text
source type
source event ID
import execution ID
```

Do not preserve unnecessary raw third-party payloads indefinitely.

---

# Ratings

If the source includes ratings, SofaWatch can import them when the rating scale and target media are understood.

Different services can use different scales.

---

# Rating Normalization

Example:

```text
source scale: 1-5
SofaWatch scale: 1-10
```

requires an explicit conversion rule if supported.

Do not silently reinterpret ratings without documenting the mapping.

---

# Rating Conflicts

If SofaWatch already contains a user rating and the import contains another rating, the conflict policy must be explicit.

Potential options:

```text
keep existing
use imported
ask during preview
use newest if trustworthy timestamps exist
```

The initial implementation should choose a predictable rule rather than implicit overwrites.

---

# Library Status

External services may use statuses that do not map exactly to SofaWatch.

SofaWatch statuses include concepts such as:

```text
Watching
Planning / Watchlist
Completed
Dropped
```

with Paused/postponed planned/evolving according to the Library model.

Source adapters own mapping into normalized SofaWatch semantics.

---

# Status Mapping

Source-specific mappings should be documented.

Example conceptual mapping:

```text
source "watchlist"
-> SofaWatch Planning
```

Do not spread third-party status strings through the core Library feature.

---

# Progress

If an external source provides only progress rather than explicit Episode events, import behavior must be careful.

For example:

```text
watched through S02E05
```

may imply previous Episodes were watched, but may not provide historical timestamps.

The importer can represent watched state according to defined rules without inventing exact dates.

---

# Importing Missing Historical Dates

If SofaWatch's canonical event model requires an event to represent watched state, missing-date imports need a deliberate representation.

Possible strategies should be decided at implementation time and documented.

The key requirement is:

```text
unknown date
!=
fabricated known date
```

---

# Statistics Impact

Imported events affect Statistics because Statistics derives from canonical viewing data.

After import:

```text
History changes
-> watch counts change
-> viewing time changes
-> rewatches change
-> streaks/activity may change
```

This is expected.

---

# Historical Accuracy

Statistics can only be as historically accurate as the imported source.

If watch dates are missing, date-dependent metrics cannot be reconstructed perfectly.

The UI/documentation should not imply false precision.

---

# Import Execution

Large imports should be treated as explicit executions with observable results.

Conceptually:

```text
ImportExecution
├── status
├── started_at
├── finished_at
├── source
├── counts
├── warnings
└── failures
```

The exact persistence model can be introduced when implementation requires it.

---

# Background Processing

Small imports can potentially execute synchronously.

Large imports may benefit from Background Jobs.

The decision should be based on real import size/runtime rather than automatically introducing asynchronous complexity.

See [Background Jobs](background-jobs.md).

---

# Structured Import Results

Import results should be structured.

Example:

```text
Shows:
  imported: 12
  existing: 40
  unresolved: 2

Movies:
  imported: 5
  existing: 8

Watch events:
  created: 1200
  duplicates: 75
  failed: 3
```

This is substantially more useful than:

```text
Import complete.
```

---

# Partial Failure

A large import can partially succeed.

Example:

```text
1200 watch events created
3 unresolved records
```

The user should not lose 1200 valid events because three records could not be resolved, unless transaction semantics explicitly require all-or-nothing for a particular operation.

---

# Transaction Boundaries

Transaction scope should reflect import semantics.

Potential strategy:

```text
validate whole file
-> process in controlled batches/items
-> commit valid work
-> record failures
```

A single giant transaction may create unnecessary rollback cost and poor partial-failure behavior.

---

# Retry

Retrying unresolved/failed import items should avoid re-importing successful items.

This reinforces the need for idempotency/provenance.

---

# Cancellation

If asynchronous imports become long-running, cancellation can be considered.

Cancellation semantics must define whether already committed data remains.

Do not expose a Cancel button without clear backend behavior.

---

# Export

Export reads canonical SofaWatch application data and serializes it into a portable documented format.

The export should not simply dump internal SQL tables.

---

# Why Not Raw SQL Tables

Database schema is an implementation detail.

A portable export should survive reasonable internal schema evolution.

Conceptually:

```text
Database models
-> export service
-> versioned export schema
-> file
```

---

# Export Ownership

A normal user export should contain that user's personal application data.

It should not expose another user's:

- History;
- Library;
- ratings;
- preferences;
- sessions.

---

# Administrator Export

A full-installation administrative export, if introduced, is a separate privileged concept.

It should not be confused with normal user portability.

---

# Export Contents

A user export can eventually include:

```text
profile-safe identity
Library
Episode watch events
Movie watch events
ratings
selected preferences
provider identifiers required for matching
```

Do not export authentication secrets.

---

# Authentication Data

Never include in a portable export:

```text
password hash
session cookies
access credentials
refresh credentials
recovery secrets
handoff secrets
server secret keys
provider API tokens
```

---

# Provider IDs in Export

Provider identifiers are useful for deterministic re-import.

Example:

```text
SofaWatch internal media reference
TMDB ID
future TVDB ID
IMDb ID where known
```

The export should contain enough stable external identity to resolve media on another installation without treating those IDs as SofaWatch primary IDs.

---

# Internal IDs in Export

Internal SofaWatch IDs can be included as export-local references if useful, but another installation must not assume they have the same database identity.

Example:

```text
export show ref = 42
```

can connect records inside the export.

On import:

```text
export ref 42
-> resolve/create local Show
-> new/local internal ID
```

---

# Export Format

A versioned JSON format is a natural candidate for SofaWatch application exports because it supports structured nested data and future additive evolution.

The exact format should be finalized during implementation.

---

# Export Version

The export should contain explicit format/version metadata.

Conceptually:

```json
{
  "format": "sofawatch-export",
  "version": 1
}
```

This lets import reject or migrate unsupported formats intentionally.

---

# Application Version

The export can also record the SofaWatch application version that produced it.

This is useful for diagnostics but should not replace the export-format version.

```text
application version
!=
export schema version
```

---

# Export Metadata

Useful safe metadata can include:

```text
format
format version
created_at
application version
language/locale if relevant
```

Avoid machine-specific paths or secrets.

---

# Deterministic Serialization

Where practical, export ordering should be stable.

This improves:

- testing;
- diffability;
- debugging;
- reproducibility.

For example, histories can use a documented chronological order.

---

# Export Timestamps

Timestamps should use an unambiguous standard representation such as ISO 8601.

Timezone semantics must be preserved.

Do not export locale-formatted timestamps such as:

```text
26/09/26 15:30
```

as the canonical machine representation.

---

# Export Download

The backend can generate an export and provide it through an authenticated download flow.

For small exports, direct response generation may be sufficient.

Large exports can use temporary artifacts/background generation if needed.

---

# Temporary Export Files

If exports are written temporarily to disk:

- filenames must be safe;
- access must remain authorized;
- files should expire/clean up;
- paths should not be user-controlled;
- secrets should not be included.

---

# Export Filename

A human-friendly filename can include:

```text
sofawatch-export-YYYY-MM-DD.json
```

without embedding sensitive personal information.

---

# Export Progress

For normal personal SofaWatch datasets, export may be fast enough not to need detailed progress.

Only add asynchronous progress infrastructure if real dataset sizes justify it.

---

# Backup vs Export

This distinction should be visible in UI/documentation.

## Export

Purpose:

```text
portability
migration
user data ownership
interchange
```

## Backup

Purpose:

```text
disaster recovery
installation restoration
database recovery
```

See [Server Administration](server-administration.md).

---

# SQLite Backup

A proper SQLite backup should use a SQLite-safe backup mechanism.

It can preserve application state more completely than a portable export.

The backup format may intentionally remain tied to SofaWatch/database versions.

---

# Restore

Database Restore belongs to Server Administration/backup workflows, not normal Import.

Import should not replace the live SQLite database file.

---

# API Design

The final API should separate stages where useful.

Conceptually:

```text
POST /imports/preview
POST /imports
GET  /imports/{id}

POST /exports
GET  /exports/{id}
```

Exact routes should be designed when implemented and follow the `/api/v1` convention.

Do not treat these example paths as already implemented API contracts.

---

# Upload Security

Import endpoints require authentication.

Administrator-only import types require administrator authorization.

Uploaded files should not be made publicly accessible through predictable URLs.

---

# Content Type

The backend should validate expected content type/format but not trust headers alone.

The parser must still validate actual content.

---

# Error Handling

Import / Export uses the common safe error model.

Possible import errors include:

```text
unsupported format
unsupported version
invalid file
file too large
invalid timestamp
unknown media
ambiguous media
provider unavailable
validation failure
authorization failure
partial import failure
```

Possible export errors include:

```text
generation failure
storage failure
authorization failure
temporary artifact unavailable
```

See [API Errors](../api/errors.md).

---

# Provider Unavailable During Import

If import requires TMDB/TVDB resolution and the provider is unavailable:

```text
already resolvable local records
```

may still be processable depending on the implementation.

Unresolved provider-dependent records should be reported safely.

The importer should not incorrectly mark them as permanently invalid merely because a provider is temporarily down.

---

# Preview vs Commit Drift

Data can change between preview and final import.

Therefore preview is informational.

The commit phase must revalidate critical assumptions such as:

- ownership;
- duplicates;
- current media existence;
- current conflicts.

Do not trust a client-submitted preview result as authoritative.

---

# Frontend Flow

A future Flutter Import flow can use:

```text
Choose source
-> Select file
-> Upload/parse
-> Preview
-> Resolve warnings if supported
-> Confirm
-> Import
-> Results
```

Export:

```text
Choose Export
-> Generate
-> Download/share/save according to platform
```

---

# Web File Handling

Flutter Web uses browser file-selection/download behavior.

The browser should not need direct filesystem paths.

---

# Mobile File Handling

iOS/Android can use platform file pickers/share/save flows.

The backend contract remains platform-independent.

---

# Responsive Design

Desktop can provide richer import preview tables.

Mobile should use adaptive cards/sections rather than forcing wide tables.

The same normalized import result data should power both.

---

# Accessibility

Import/Export UI should include:

- accessible file-selection controls;
- clear validation errors;
- semantic progress;
- warnings not communicated only by color;
- keyboard-accessible confirmation;
- accessible result summaries;
- clear destructive/conflict choices.

---

# Localization

Future localization should cover:

- source names;
- validation;
- duplicate messages;
- unresolved media;
- import progress;
- result counts;
- warnings;
- export generation;
- dates;
- file-size formatting.

Machine-readable export field names should not change with UI language.

---

# Privacy

Exports can contain a detailed personal viewing history.

The UI should make clear that exported files may contain personal SofaWatch data.

SofaWatch should not automatically upload exports to third-party storage without explicit user configuration/action.

---

# Logging

Import logs can include:

```text
import execution ID
source type
counts
safe failure categories
```

Avoid logging entire imported files or complete viewing histories unnecessarily.

Never log authentication credentials.

---

# Auditability

Administrator imports and major destructive operations can benefit from operational audit events.

Audit information should remain proportional and privacy-aware.

---

# Performance

Large imports should avoid:

- loading unnecessary provider metadata repeatedly;
- N+1 database queries;
- resolving the same media repeatedly;
- one database transaction per trivial field;
- unbounded in-memory file parsing.

Caching resolution within one import execution can improve efficiency.

---

# Resolution Cache

Within a single import:

```text
same TMDB Show ID appears 500 times
```

should not require 500 identical resolution queries/provider calls.

Use execution-scoped mapping where appropriate.

---

# Batching

Watch-event insertion may benefit from controlled batching.

Batching must still respect:

- duplicate detection;
- user ownership;
- transaction semantics;
- error reporting.

---

# Testing

Backend tests should eventually cover:

```text
valid SofaWatch export import
unsupported export version
invalid file
oversized file
user ownership
media reuse
new media resolution
TMDB matching
future TVDB matching
Movie matching
Episode matching
ambiguous matching
unresolved media
historical timestamp preservation
rewatch preservation
duplicate media prevention
duplicate Library prevention
duplicate event prevention
same-day legitimate rewatches
rating mapping
Library status mapping
partial failure
retry/idempotency
provider unavailable
```

Export tests should cover:

```text
user-scoped export
History
rewatches
Library
ratings
timestamps
provider IDs
format version
deterministic structure
no authentication secrets
no provider tokens
re-import compatibility
```

Frontend tests should cover:

```text
source selection
file selection
validation loading
validation failure
preview
warnings
unresolved records
confirm
import loading
partial result
success
Retry
export generation
export failure
responsive mobile
responsive desktop
```

---

# Round-Trip Testing

A particularly valuable integration test is:

```text
User A data
-> SofaWatch export
-> clean SofaWatch test database
-> import export
-> compare normalized user data
```

The goal is semantic equivalence for supported exported fields.

Database primary-key equality is not required.

---

# Security Tests

Explicitly verify:

```text
cannot import into another user through forged user_id
cannot export another user's data
normal user cannot perform admin-only import
malformed files fail safely
oversized files rejected
archive traversal blocked if archives exist
exports contain no password hashes
exports contain no sessions/tokens
exports contain no provider secrets
```

---

# Edge Cases

## Same Import Uploaded Twice

Second import should not duplicate the entire History.

## Same Episode Watched Twice at Different Times

Both events remain legitimate rewatches.

## Same Episode Has Exact Duplicate Source Event

Duplicate handling should prevent double insertion where confidently identifiable.

## Imported Show Already Exists

Reuse the existing internal Show.

## Imported Movie Does Not Exist

Resolve/import metadata, then attach user data.

## TMDB Temporarily Unavailable

Provider-dependent records are reported/retryable rather than incorrectly matched.

## Ambiguous Movie Title

Do not silently choose an uncertain Movie.

## Episode Numbering Cannot Be Resolved

Record as unresolved rather than corrupting History.

## Watch Date Missing

Do not fabricate false historical precision.

## Export from Older SofaWatch Version

Use export schema version compatibility, not only application version.

## Import Partially Succeeds

Successful work remains and failed/unresolved records are clearly summarized according to transaction policy.

## User Logs Out During Long Import

Backend ownership remains tied to the authenticated execution/user established by the request/job; frontend state follows normal auth handling.

---

# Future Work

## Export Format

```text
[ ] define `sofawatch-export` schema
[ ] choose initial schema version
[ ] define timestamp format
[ ] define media references
[ ] define Library representation
[ ] define watch-event representation
[ ] define ratings representation
[ ] define preference scope
[ ] document compatibility policy
```

---

## Import Core

```text
[ ] normalized import models
[ ] source-adapter interface
[ ] validation service
[ ] media-resolution service
[ ] duplicate strategy
[ ] provenance/idempotency strategy
[ ] partial-failure model
[ ] structured result model
```

---

## SofaWatch Import

```text
[ ] import SofaWatch export
[ ] round-trip tests
[ ] older-format compatibility strategy
[ ] unresolved-provider fallback
```

---

## Third-Party Importers

Potential sources:

```text
[ ] Trakt
[ ] TV Time
[ ] additional source only when justified
```

Each importer should have its own documented mapping rules.

---

## Media Resolution

```text
[ ] TMDB exact matching
[ ] TVDB matching after integration
[ ] IMDb/external-ID matching where useful
[ ] controlled fallback matching
[ ] ambiguity reporting
[ ] episode-numbering strategy
```

---

## Import UI

```text
[ ] source selection
[ ] file picker
[ ] validation
[ ] preview
[ ] warnings
[ ] unresolved-item presentation
[ ] confirmation
[ ] progress
[ ] structured results
[ ] Retry
```

---

## Export UI

```text
[ ] user export action
[ ] generation state
[ ] download/save/share behavior
[ ] safe filename
[ ] error handling
[ ] privacy notice
```

---

## Administration

```text
[ ] administrator entry point
[ ] admin-assisted user import if needed
[ ] operational execution history
[ ] audit events where justified
[ ] separate backup/restore UI
```

---

## Production Hardening

```text
[ ] file-size limits
[ ] parser fuzz/invalid-input tests
[ ] archive safety if applicable
[ ] memory-use audit
[ ] large-history performance test
[ ] secret/privacy audit
[ ] idempotency stress test
[ ] round-trip migration test
```

---

# Notes

> Import / Export is application-level data portability, not database backup/restore.

> Imported files are untrusted input.

> SofaWatch internal media IDs remain canonical after import.

> TMDB, TVDB, IMDb, and other IDs are external/provider identifiers.

> Historical watch timestamps should be preserved when the source provides them.

> Missing timestamps must not be replaced with fabricated historical precision.

> Rewatches are individual watch events.

> Importing the same file twice should not duplicate the entire viewing History.

> Legitimate repeated watches must not be accidentally deduplicated.

> One unresolved record should not unnecessarily erase thousands of successful imported records.

> Export formats should be versioned independently from the SofaWatch application version.

> Portable exports must never contain passwords, password hashes, session credentials, refresh credentials, or provider API secrets.

> Import preview is informative; the backend must revalidate authoritative state during commit.

> Raw SQLite replacement belongs to Backup/Restore, not Import.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Viewing Progress](viewing-progress.md)
- [History](history.md)
- [Movies](movies.md)
- [Statistics](statistics.md)
- [Profile](profile.md)
- [Authentication](authentication.md)
- [Server Administration](server-administration.md)
- [Background Jobs](background-jobs.md)
- [Metadata Sync](metadata-sync.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)
