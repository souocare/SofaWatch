# SofaWatch Implementation Status

This document is the detailed implementation tracker for SofaWatch.

It records what is implemented, what is still pending, what has deliberately been deferred, and which ideas remain exploratory. It is intentionally more detailed than the project README files.

The roadmap is not immutable. Product decisions may change as SofaWatch evolves, and an item should not be implemented merely because it appears here if the same goal has already been solved in a better way.

## Status Legend

- `[x]` Implemented
- `[ ]` Pending
- `[~]` In progress / partially implemented
- `[>]` Planned
- `[-]` Deferred
- `[?]` Exploratory / requires product or technical decision
- `[!]` Needs review or final validation

---

# 1. Product Foundation

## 1.1 Application Model

- [x] Self-hosted application model
- [x] Web client
- [x] iOS client
- [x] Android client
- [x] FastAPI backend
- [x] Flutter frontend
- [x] SQLite persistence
- [x] Versioned REST API under `/api/v1`
- [x] Backend as the source of truth for persisted state and business rules
- [x] Internal SofaWatch IDs after media import
- [x] External provider IDs kept conceptually separate from internal identity

## 1.2 Main Navigation

- [x] Home
- [x] Shows
- [x] Movies
- [x] Explore
- [x] Profile
- [x] Global Search
- [x] Mobile navigation experience
- [x] Web/Desktop navigation experience
- [x] Preserve branch/navigation context where appropriate

---

# 2. Backend Foundation

## 2.1 Core Infrastructure

- [x] FastAPI application
- [x] SQLAlchemy
- [x] Pydantic
- [x] pydantic-settings configuration
- [x] Alembic
- [x] SQLite
- [x] pytest
- [x] Ruff
- [x] HTTP client infrastructure
- [x] Application logging
- [x] Environment-based configuration
- [x] Configurable CORS
- [x] Explicit SQLite foreign-key enforcement
- [x] Dependency injection
- [x] Central API error handling

## 2.2 Backend Architecture

Current conceptual dependency direction:

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
Database
```

External APIs follow a separate provider boundary:

```text
Services
    |
    v
Providers
    |
    v
External APIs
```

- [x] Routes separated from business logic
- [x] Services used for application/business workflows
- [x] Repository layer
- [x] SQLAlchemy persistence models
- [x] Pydantic schemas
- [x] Provider-specific integration layer
- [x] User-scoped persistence where required
- [>] Continue reducing provider coupling as additional providers are introduced

## 2.3 Infrastructure Audit

- [ ] Audit direct vs transitive dependencies
- [ ] Review `pyproject.toml`
- [ ] Review version ranges
- [ ] Separate/confirm runtime vs development dependencies
- [ ] Review package metadata
- [?] Evaluate `uv.lock` or another reproducible dependency-locking strategy
- [ ] Strengthen configuration validation tests
- [ ] Review secret-key validation
- [ ] Review metadata refresh-days validation
- [ ] Review provider timeout validation
- [ ] Review API port validation
- [ ] Review supported-language parsing
- [ ] Review CORS parsing
- [ ] Run dependency security audit
- [?] Evaluate Bandit or equivalent static security tooling
- [ ] Search repository history/current tree for accidentally committed secrets
- [ ] Production debug/configuration audit
- [?] Evaluate mypy or pyright before introducing static type checking
- [ ] Final API contract consistency audit

---

# 3. Frontend Foundation

## 3.1 Flutter Architecture

- [x] Flutter Web
- [x] Flutter iOS
- [x] Flutter Android
- [x] Feature First organization
- [x] Presentation layer
- [x] Application layer
- [x] Domain layer
- [x] Data layer
- [x] Repository contracts
- [x] API repository implementations
- [x] DTO/domain mapping
- [x] Cubit/BLoC state management
- [x] `go_router`
- [x] Dio API client

Conceptual dependency direction:

```text
Presentation
     |
     v
Application
     |
     v
Domain
     ^
     |
Data
```

Domain code should remain independent from Flutter, Dio, and raw JSON.

## 3.2 Flutter Code Conventions

- [x] Prefer `StatelessWidget` where local mutable state is unnecessary
- [x] Use private widgets to split meaningful presentation components
- [x] Use `const` where practical
- [x] Use `ValueKey` where useful for state stability/testing
- [x] Responsive/adaptive presentation
- [x] Shared domain/application logic between Web and mobile where possible
- [x] Central design tokens
- [x] Explicit Loading/Error/Empty states
- [>] Continue removing unnecessary duplication as features mature

---

# 4. Design System

## 4.1 Tokens

- [x] `AppColors`
- [x] `AppTypography`
- [x] `AppSpacing`
- [x] `AppRadius`
- [x] `AppDurations`
- [x] `AppBreakpoints`
- [x] Shared token export
- [x] Dark application theme

## 4.2 Responsive Strategy

- [x] Mobile-specific application shell
- [x] Web/Desktop-specific application shell
- [x] Shared navigation branches
- [x] Responsive Search presentation
- [x] Responsive media-detail presentation
- [x] Mobile safe-area considerations
- [>] Continue final narrow-width validation
- [>] Continue desktop/ultrawide density validation
- [ ] Final responsive audit before stable release

---

# 5. Metadata and Provider Model

## 5.1 Current Provider

### TMDB

- [x] TMDB API integration
- [x] TV Search
- [x] Movie Search
- [x] Show metadata
- [x] Movie metadata
- [x] Season metadata
- [x] Episode metadata
- [x] Genres
- [x] Images
- [x] Trending
- [x] Popular/discovery data
- [x] Metadata refresh/synchronization
- [x] Provider error mapping
- [x] Provider timeout configuration
- [x] Provider health diagnostics

## 5.2 Internal Identity

- [x] SofaWatch uses internal IDs after import
- [x] TMDB IDs remain provider identifiers
- [x] Genre is an internal SofaWatch entity
- [x] Provider-specific genre mappings
- [>] Generalize external identifier architecture as new providers are added

## 5.3 TVDB

**Status:** Planned.

TVDB is intended to become a complementary provider, especially for TV metadata.

- [ ] Study current TVDB API
- [ ] Confirm authentication requirements
- [ ] Define provider abstraction changes
- [ ] Implement TVDB client
- [ ] Implement TVDB schemas/DTOs
- [ ] Implement TVDB error mapping
- [ ] Handle rate limits
- [ ] Handle provider timeouts
- [ ] Implement provider ID mappings
- [ ] Show mapping
- [ ] Season mapping
- [ ] Episode mapping
- [ ] Alias/alternative-title support
- [ ] Air-date support
- [?] Air-time support if reliable data is actually available
- [ ] TMDB ↔ TVDB matching
- [ ] Metadata precedence rules
- [ ] Metadata fallback rules
- [ ] Synchronization rules
- [ ] Configuration
- [ ] Health check
- [ ] Backend tests
- [ ] Frontend/provider diagnostics integration where appropriate

TVDB IDs should not be spread directly throughout business logic.

## 5.4 IMDb / External Ratings

**Status:** Exploratory.

- [?] Identify a legitimate and stable IMDb/API data source
- [?] Review licensing and terms
- [?] Review rate limits
- [?] Define update/cache strategy
- [ ] Add IMDb external identifier mapping if provider is approved
- [ ] External rating value
- [ ] External rating vote count
- [ ] External IMDb link
- [?] Evaluate IMDb as complementary Search/matching source

Personal SofaWatch ratings must remain separate from external ratings.

Conceptually:

```text
Personal Rating
    |
    +-- SofaWatch user rating

External Ratings
    |
    +-- TMDB
    +-- IMDb
    +-- future providers
```

---

# 6. Genres

- [x] Internal Genre entity
- [x] Genre persistence
- [x] TV genre mapping
- [x] Movie genre mapping
- [x] Genre use in discovery
- [>] Add TVDB genre mappings if/when required
- [>] Keep provider-specific IDs outside core Genre identity

---

# 7. Global Search

## 7.1 Product Model

Search is a single global application feature.

Explore is discovery and must not contain a second independent Search implementation.

Supported media:

- [x] All
- [x] TV Shows
- [x] Movies
- [x] People filtered from normalized media results

## 7.2 Backend

- [x] Search API
- [x] TMDB integration
- [x] Common normalized media result contract
- [x] Media-type contract
- [x] Pagination
- [x] Language-aware requests
- [x] Safe provider error mapping

## 7.3 Frontend

- [x] `SearchRepository`
- [x] `ApiSearchRepository`
- [x] Search DTOs/mappers
- [x] `SearchBloc`
- [x] Search states
- [x] Pagination model
- [x] Query normalization
- [x] Minimum query handling
- [x] Empty-query handling
- [x] Debounce
- [x] Out-of-order/stale response protection
- [x] Filters
- [x] Pagination
- [x] Pagination retry
- [x] Initial loading
- [x] Preserve previous results where appropriate
- [x] Empty results state
- [x] Network error state
- [x] Timeout state
- [x] Provider error state
- [x] Invalid-response state
- [x] Retry
- [x] Preserve Search context when opening previews

## 7.4 Mobile Search

- [x] Dual-Pill Search integration
- [x] Search integrated into main mobile experience
- [x] Preserve originating navigation branch
- [x] Close Search back into previous context

## 7.5 Web Search

- [x] Global Search action
- [x] Desktop/Web modal-style Search
- [x] Responsive behavior

## 7.6 Search Cache

- [x] In-memory cache
- [x] TTL
- [x] LRU eviction
- [x] Maximum entry count
- [x] Query/filter/language-aware keys
- [x] Page-aware cache where required
- [-] Persistent cache
- [-] Prefetch
- [-] Stale-while-revalidate
- [-] Search-specific analytics

Current intended limits:

```text
TTL: 5 minutes
Maximum entries: 100
```

## 7.7 Search State Synchronization

Deferred work:

- [ ] Update Search result row after Library mutation without repeating Search
- [ ] Preserve query
- [ ] Preserve selected filter
- [ ] Preserve pagination
- [ ] Preserve scroll position
- [ ] Ensure correct state when Search is reopened
- [ ] Add corresponding tests

---

# 8. Media Import and Local Identity

## 8.1 General Model

```text
External Provider Result
          |
          v
        Import
          |
          v
Local SofaWatch Entity
          |
          v
Optional User Library Entry
```

- [x] Import and Library membership are separate concepts
- [x] Imported media receives internal SofaWatch identity
- [x] Provider identity remains external metadata

## 8.2 Shows

- [x] TMDB Show import
- [x] Local Show persistence
- [x] Idempotent behavior where required
- [x] Metadata refresh support

## 8.3 Movies

- [x] TMDB Movie import
- [x] Local Movie persistence
- [x] Idempotent import endpoint

Current endpoint:

```text
POST /api/v1/movies/import/tmdb/{tmdb_id}
```

---

# 9. Library

## 9.1 General

- [x] User-scoped Library
- [x] Show entries
- [x] Movie entries
- [x] Show/Movie exclusivity constraints
- [x] Library actions independent from Search business logic

Conceptually:

```text
LibraryEntry
    |
    +-- show_id
    |
    OR
    |
    +-- movie_id
```

Never both and never neither.

## 9.2 Show Library

- [x] Watching
- [x] Planning / Watchlist
- [x] Completed
- [x] Dropped
- [-] Paused status deferred
- [~] Up to Date presentation/consistency
- [ ] Final status/ordering audit

## 9.3 Movie Library

- [x] Movie Watchlist
- [x] Watched state
- [x] Library integration
- [>] Final full Movies Library organization
- [>] Upcoming Movies organization where appropriate

---

# 10. Shows

## 10.1 Shows Main Area

- [x] Watch List
- [x] Upcoming
- [x] Selected-tab preservation
- [x] Responsive presentation
- [ ] Final responsive validation

---

# 11. Watch List

Watch List currently contains:

- [x] Watch Next
- [x] Haven't Watched in a While
- [x] Haven't Started
- [x] Watch History

## 11.1 Watch Next

Displays the next relevant episode for a Show.

- [x] Show
- [x] Next episode
- [x] Season/Episode number
- [x] Episode title
- [x] Air date
- [x] Progress
- [x] Mark Watched
- [x] Refresh affected progress after mutation
- [x] Advance to next episode after watch where appropriate
- [x] Caught-up Shows excluded
- [x] Ended Show may remain if unwatched episodes exist
- [x] No invented next episode

## 11.2 Haven't Watched in a While

- [x] Started-but-inactive Shows
- [x] Last watched episode/time
- [x] Next episode context
- [x] Inactivity threshold
- [x] Inactivity-based ordering
- [x] Avoid inappropriate duplication with Watch Next

## 11.3 Haven't Started

- [x] Planning/Library Shows not yet started
- [x] First available episode context
- [x] Start action

## 11.4 Watch History

- [x] Real viewing events
- [x] `watched_at DESC`
- [x] Show
- [x] Season/Episode number
- [x] Episode title
- [x] Watched timestamp
- [x] Viewing-event removal/correction where supported
- [x] Rewatch action

---

# 12. Episode Progress and Watch Events

## 12.1 Backend Source of Truth

Backend owns:

- [x] `is_watched`
- [x] `watch_count`
- [x] `watched_at`

## 12.2 Viewing Events

Each viewing is an individual event:

```text
First watch
    |
    +-- EpisodeWatchEvent A

Rewatch
    |
    +-- EpisodeWatchEvent B

Rewatch
    |
    +-- EpisodeWatchEvent C
```

Result:

```text
watch_count = 3
watched_at = newest event timestamp
```

- [x] First watch creates event
- [x] Rewatch creates additional event
- [x] Historical events are preserved
- [x] Individual viewing events can be removed
- [x] Derived watched state recalculated after removal
- [x] Watch history sorted newest-first

---

# 13. Rewatch

## 13.1 Episodes

- [x] Rewatch supported
- [x] New watch event created
- [x] Existing history preserved
- [x] Watch count updated
- [x] Latest watched time updated
- [x] Watch History refreshed
- [x] Progress refreshed
- [x] Watch Next/Haven't Watched in a While consistency refreshed
- [x] Per-row action/loading behavior
- [x] Double-submit protection
- [x] No date picker for normal "Watched again" action

## 13.2 Movies

- [x] `MovieWatchEvent`
- [x] Movie rewatch creates a new event
- [x] Movie history preserves individual viewings
- [x] Statistics count each movie viewing

---

# 14. Upcoming

## 14.1 Timeline

- [x] Today
- [x] Tomorrow
- [x] Next seven days
- [x] Later dates
- [x] Navigation into past ranges
- [x] Historical ranges
- [x] Already-aired episodes
- [x] Chronological ordering
- [x] Bidirectional temporal navigation/scroll behavior

## 14.2 Air Dates and Times

- [x] Air date support
- [-] Do not invent air time
- [>] Add air time only when a provider supplies reliable data

## 14.3 Pending Upcoming Interactions

- [ ] Allow marking an eligible historical/aired Episode as watched if still pending
- [ ] Immediately update progress/Watch Next after that mutation
- [ ] Block Mark Watched for Episodes that have not aired yet
- [ ] Add corresponding tests

---

# 15. Show Details

## 15.1 General Information

- [x] Metadata
- [x] Backdrop
- [x] Poster
- [x] Title
- [x] Overview
- [x] Genres
- [x] Dates
- [x] Additional information
- [x] Library state

## 15.2 Seasons

- [x] Season list
- [x] Accordion behavior
- [x] Independent Season state
- [x] Independent loading
- [x] Independent errors
- [x] Independent Retry
- [x] Lazy Episode synchronization
- [x] Reuse locally persisted Episodes
- [x] Batch/progress infrastructure without requiring all Episodes up front

## 15.3 Episodes

- [x] Episode list
- [x] Watched state
- [x] Watched timestamp
- [x] Watch count
- [x] Mark Watched
- [x] Mark Unwatched where supported
- [x] Rewatch
- [x] Episode watch history
- [x] Remove individual watch event
- [x] Refresh Episode/Season progress after history changes


## 15.4 Bulk Watched Actions

- [x] Mark all aired/watchable Episodes in a Season as watched
- [x] Do not create duplicate watch events for Episodes already watched
- [x] Do not mark future Episodes as watched
- [x] Exclude Specials from Show-level bulk watched by default
- [x] Mark all aired/watchable regular Episodes in a Show as watched
- [x] Confirmation before bulk mutation
- [x] Refresh Episode state after mutation
- [x] Refresh Season progress after mutation
- [x] Refresh Show progress after mutation
- [x] Refresh Watch Next / Haven't Watched in a While where affected
- [x] Refresh Watch History where loaded
- [x] Backend tests
- [x] Frontend Cubit/widget tests

## 15.5 Previous Unwatched Episodes Suggestion

- [x] Detect earlier regular Episodes that remain unwatched when marking a later Episode watched
- [x] Offer to mark those earlier Episodes as watched
- [x] Allow user to decline and mark only the selected Episode
- [x] Never infer additional rewatches for Episodes already watched
- [x] Exclude future Episodes
- [x] Preserve chronological viewing-history semantics
- [x] Refresh dependent progress/Watch List state after bulk mutation
- [x] Backend tests
- [x] Frontend interaction tests

## 15.4 Remaining Work

- [ ] Final remaining Seasons/Episodes functionality tests
- [?] Separate Season Details page only if a real product need appears

---

# 16. Show Status Rules

Relevant statuses:

- [x] Watching
- [x] Planning
- [x] Completed
- [x] Dropped
- [-] Paused deferred

Business rules:

- [x] Caught-up Show does not appear in Watch Next
- [x] New Episode can return a caught-up Show to Watch Next
- [x] No next Episode is invented
- [x] Ended does not automatically mean Completed
- [x] Ended Show with unwatched Episodes can remain actionable
- [x] Avoid inappropriate Watch Next / inactive duplication
- [ ] Centralize provider/status variants such as `Ended`, `Canceled`, and `Cancelled`

A rigid DB enum is not required solely for normalization.

---

# 17. Shows Refresh

A coordinated refresh should be able to update:

- [ ] Library
- [ ] Watch Next
- [ ] Haven't Watched in a While
- [ ] Progress / Up to Date
- [ ] Upcoming
- [ ] Watch History when loaded

Context to preserve:

- [ ] Selected tab
- [ ] Previous data while refreshing
- [ ] Watch List scroll
- [ ] Upcoming scroll
- [ ] Loaded historical range

Planned work:

- [ ] Mobile refresh
- [ ] Desktop refresh
- [ ] Coordinated refresh orchestration
- [ ] Context preservation tests

---

# 18. Shows Responsive Validation

## 18.1 Mobile

- [ ] Final Watch List validation
- [ ] Final Upcoming validation
- [ ] Long-title validation
- [ ] Small-width validation
- [ ] Mark Watched action validation
- [ ] Haven't Started Start-button validation
- [ ] Watch History action validation
- [ ] Keyboard/safe-area validation where relevant

## 18.2 Desktop

- [ ] Avoid excessively wide rows
- [ ] Limit content appropriately on ultrawide screens
- [ ] Validate desktop information density

---

# 19. Movies

## 19.1 Domain and Data

- [x] Movie model
- [x] Movie repository
- [x] Movie DTOs
- [x] Movie import
- [x] Movie Library support
- [x] Movie watch events

## 19.2 Movie Details

- [x] Movie Details infrastructure
- [x] Metadata
- [x] Library/Watchlist state
- [x] Watched state
- [x] Watch history
- [x] Rewatch support
- [x] Personal-rating concept
- [>] External ratings kept separately when implemented

## 19.3 Future Movie Work

- [>] More advanced movie discovery
- [>] Coming Soon
- [>] Recommendation improvements
- [>] Because You Watched...
- [>] More Like This
- [>] Final Movies Library organization

---

# 20. Explore

Explore is discovery, not Search.

## 20.1 Implemented

- [x] Trending
- [x] Popular Shows
- [x] Popular Movies
- [x] Genre filters
- [x] Reusable discovery media cards
- [x] Library actions
- [x] Preview
- [x] Loading states
- [x] Error states
- [x] Today/Week trending concepts
- [x] Media-type filtering where supported
- [x] Independent Show/Movie genre filters
- [x] Preserve state when opening/closing preview
- [x] Preserve vertical scroll where applicable
- [x] Preserve horizontal section state where applicable

## 20.2 Advanced Discovery

Deferred until there is a real recommendation/discovery strategy:

- [-] Top Shows For You
- [-] Top Movies For You
- [-] Hidden Gems
- [-] Editorial Coming Soon sections
- [-] Advanced personalized recommendations

Do not hardcode editorial content without a real source or rule.

---

# 21. Home

Home is the personal viewing dashboard.

## 21.1 Header

- [x] Time-of-day greeting
- [x] Current date
- [x] Avatar/account access
- [x] Settings/account menu integration

## 21.2 Your Week

Uses Statistics rather than duplicating statistics business logic.

- [x] Episodes watched
- [x] Movies watched
- [x] Watch time
- [x] Rewatches counted as additional viewings

## 21.3 Continue Watching

- [x] Reuses Watch Next concepts/data
- [x] Does not duplicate the full Shows page

## 21.4 Premiering Today

- [x] Episodes with `air_date == today`
- [x] Watching Shows
- [x] Planning Shows where appropriate
- [x] Visual distinction for Planning content

## 21.5 Upcoming

- [x] Starts tomorrow
- [x] Initial seven-day window
- [x] Avoid duplication with Today

## 21.6 Missed Recently

- [x] Recent aired Episodes
- [x] 14-day concept
- [x] Watching only
- [x] Unwatched only
- [x] Excludes Today
- [x] Newest first
- [x] Planning content excluded from "missed"

## 21.7 Recent Activity

- [x] Reuses Watch History
- [x] Small dashboard-oriented result set
- [x] Does not duplicate the complete History timeline

## 21.8 Deferred Home Features

- [-] Quick Actions
- [-] Home recommendations

Recommendations should remain primarily in discovery-oriented areas unless real usage justifies duplication.

---

# 22. Statistics

Statistics is an independent feature and can be reused by Home and Profile.

## 22.1 Viewing Overview

- [x] Total watch time
- [x] Rewatch time
- [x] Episodes watched
- [x] Unique Episodes
- [x] Episode rewatches
- [x] Movies watched
- [x] Unique Movies
- [x] Movie rewatches
- [x] Shows vs Movies time split

## 22.2 Activity Over Time

Periods:

- [x] 7D
- [x] 14D
- [x] 30D
- [x] 90D
- [x] 1Y
- [x] All

Insights:

- [x] Watch-time activity
- [x] Episode/Movie activity
- [x] Adaptive buckets
- [x] Activity heatmap

## 22.3 Watching Habits

- [x] Current streak
- [x] Longest streak
- [x] Biggest marathon by time
- [x] Longest binge by Episode count
- [x] Average active-day watch time
- [x] Most active weekday

## 22.4 Content Insights

- [x] Most watched Shows
- [x] Most rewatched Shows
- [x] Most rewatched Episodes
- [x] Most rewatched Movies
- [x] Top Show genres
- [x] Top Movie genres

## 22.5 Library Statistics

- [x] Shows added
- [x] Movies added
- [x] Shows completed

## 22.6 Future Statistics

- [>] Unwatched aired Episodes
- [>] Planned Movies
- [>] Estimated future watch time
- [>] Catch-up speed
- [>] Backlog growth/shrink rate
- [>] Additional long-term viewing insights

---

# 23. Profile

Profile is composed from independent feature sections.

A failure in one section should not unnecessarily break another.

## 23.1 Areas

- [x] Identity
- [x] Statistics
- [x] Library
- [x] History
- [x] Application-related sections
- [x] Server administration
- [x] Background Jobs
- [x] Logs
- [x] Import / Export
- [x] Security
- [x] Administrator-specific visibility

---

# 24. Profile History

## 24.1 Preview

- [x] Recent Episode watch events
- [x] Recent Movie watch events
- [x] Rewatches remain individual entries

## 24.2 Full History

- [x] All
- [x] Episodes
- [x] Movies
- [x] Global `watched_at DESC` ordering
- [x] Pagination/load-more behavior where required
- [x] Episode → Episode Details
- [x] Movie → Movie Details

---

# 25. Profile Library

## 25.1 Preview

- [x] Recent Shows
- [x] Recent Movies

## 25.2 Full Shows Library

Current/intended organization:

- [x] Watching
- [~] Up to Date
- [x] Haven't Started
- [x] Finished
- [ ] Final consistency/status audit

## 25.3 Full Movies Library

Current/intended organization:

- [x] Watchlist
- [>] Upcoming
- [x] Watched
- [ ] Final organization audit

## 25.4 Navigation

- [x] Show → Show Details
- [x] Movie → Movie Details

---

# 26. Authentication and Multi-user

## 26.1 User Model

- [x] Real persistent users
- [x] Multi-user application
- [x] Administrator flag
- [x] Active-user concept
- [x] Username
- [x] Email
- [x] Display name
- [x] Password hash
- [x] User-scoped application data

## 26.2 Passwords

- [x] Argon2
- [x] No plaintext password persistence
- [x] Password change with current-password verification

## 26.3 Access Tokens

- [x] Short-lived access tokens
- [x] Used for authenticated requests
- [x] Not used as long-lived persistence mechanism

## 26.4 Auth Sessions

- [x] Persistent `AuthSession`
- [x] Web sessions
- [x] Mobile sessions
- [x] Session creation
- [x] Renewal
- [x] Expiration
- [x] Revocation
- [x] Last-used tracking
- [x] Persistent credentials stored by hash

---

# 27. Web Authentication

- [x] Persistent Web session
- [x] HttpOnly cookie
- [x] `SameSite=Lax`
- [x] Cookie path `/`
- [x] Secure-cookie behavior for production/HTTPS
- [x] Browser session restoration
- [x] Persistent Web credential unavailable to JavaScript
- [x] Short-lived access-token support for API requests

---

# 28. Mobile Authentication

- [x] Short-lived access token
- [x] Rotating refresh credential
- [x] Refresh credential associated with AuthSession
- [x] Server stores credential hash only
- [x] Refresh rotation
- [x] Previous credential invalidated after rotation
- [x] Old credential reuse rejected
- [x] Native credential persistence through frontend abstraction

---

# 29. Unified Authentication

`CurrentUserDependency` supports:

- [x] Bearer access token
- [x] Web HttpOnly session cookie
- [x] Both resolve to the same User
- [x] Safe Bearer precedence
- [x] Invalid Bearer does not silently fall back to cookie

---

# 30. Logout

- [x] Logout current session
- [x] Clear local client credentials
- [x] Log out everywhere
- [x] Revoke all sessions belonging to current user
- [x] Other users remain unaffected

---

# 31. Initial Setup

## 31.1 Bootstrap

- [x] Detect installation with no users
- [x] `setup_required`
- [x] Frontend Setup instead of Login
- [x] First account is a real User
- [x] First User automatically becomes Administrator
- [x] Setup disabled after first User exists
- [x] Protection against concurrent first-admin creation

## 31.2 Registration After Setup

- [x] Public registration remains closed by default

---

# 32. Open Registration

Global security setting:

```text
Open Registration
```

- [x] Default `false`
- [x] Administrator-only configuration
- [x] Backend blocks registration when disabled
- [x] Frontend hides Sign Up when disabled
- [x] UI hiding is not relied on for security

---

# 33. Mobile-to-Web Authentication Handoff

Flow:

```text
Authenticated Mobile App
          |
          v
Create temporary handoff
          |
          v
Open SofaWatch Web
          |
          v
Exchange handoff
          |
          v
Create Web AuthSession
```

- [x] Temporary handoff credential
- [x] Short TTL
- [x] Single-use
- [x] User-bound
- [x] Not a permanent access token
- [x] Not a permanent refresh credential
- [x] Invalid token rejected
- [x] Expired token rejected
- [x] Already-used token rejected

---

# 34. Account Management

- [x] Change display name
- [x] Change password with current password
- [-] Username editing deliberately deferred
  - **Note:** This is a product decision, not a missing implementation or known bug.

Username editing is not considered a bug or missing requirement unless the product decision changes.

---

# 35. Password Recovery

## 35.1 Regular User Recovery

- [x] Administrator can initiate recovery for a regular user
- [x] Random recovery credential
- [x] Temporary
- [x] User-bound
- [x] Hashed server-side
- [x] Expiration
- [x] Single-use
- [x] Recovery link
- [x] User chooses a new password
- [x] Credential invalidated after use
- [x] Existing sessions revoked after successful recovery

## 35.2 Administrator Recovery

- [x] Server-side recovery command
- [x] Username/email lookup
- [x] Password requested through `getpass`
- [x] Password not accepted as CLI argument
- [x] Password not logged/stdout
- [x] Existing Administrator sessions revoked after reset

Command:

```bash
python -m app.admin.reset_password <username-or-email>
```

---

# 36. Legacy Local User Removal

The old local-user model has been removed.

Removed concepts include:

```text
is_local
isLocal
Local User
fixed local user
```

- [x] Existing development user converted into a real account
- [x] Existing `user_id` preserved
- [x] Library relationships preserved
- [x] Progress preserved
- [x] History preserved
- [x] Ratings preserved
- [x] Remaining user-scoped relationships preserved
- [x] Legacy code references removed
- [x] Do not reintroduce the local-user model

---

# 37. User Administration

Advanced Administrator User Management is intentionally future work.

## 37.1 User Management

- [>] List users
- [>] Username
- [>] Display name
- [>] Email
- [>] Active/Inactive state
- [>] Administrator identification
- [>] Administrative actions
- [>] Administrator-only access
- [>] Desktop/Web-only management UI

Existing user listing used for another feature does not automatically mean full User Management is implemented.

## 37.2 Activate / Deactivate Users

- [>] Deactivate normal user
- [>] Prevent deactivated user Login
- [>] Revoke active sessions on deactivation
- [>] Reactivate user
- [>] Ensure previous sessions remain invalid
- [>] Prevent Administrator self-deactivation
- [>] Confirmation UI
- [>] Update only affected user in UI
- [>] Error/retry handling

---

# 38. Server Administration

Administrator functionality is visible only for Administrators, but backend authorization remains mandatory.

## 38.1 Server Health

- [x] Overall status
- [x] Checked-at timestamp
- [x] Uptime
- [x] Database health
- [x] TMDB health
- [-] Backend Version intentionally not required for now
- [>] Environment information may be added later
- [-] TVDB health until TVDB actually exists

## 38.2 Database Diagnostics

Current/intended diagnostics include:

- [x] Database engine
- [x] Database size
- [x] WAL size
- [x] Connectivity
- [x] Integrity check
- [x] Foreign-key check
- [x] Alembic revision

## 38.3 Storage Diagnostics

Current/intended diagnostics include:

- [x] Data directory
- [x] Writable state
- [x] Total space
- [x] Used space
- [x] Free space
- [x] Usage percentage
- [x] Image cache size
- [x] Image cache file count
- [x] Storage breakdown where supported
- [-] Backup-storage status until a real backup strategy exists

## 38.4 Runtime

- [x] Python version
- [x] Platform
- [x] Process uptime
- [x] Start time
- [x] Current server time

## 38.5 Providers

### TMDB

- [x] Configured
- [x] Reachable
- [x] Latency

### TVDB

- [-] Not exposed until TVDB integration exists

---

# 39. Background Jobs

## 39.1 Infrastructure

- [x] `BackgroundJob`
- [x] `BackgroundJobRun`
- [x] Job registry
- [x] Executor
- [x] Worker/scheduler
- [x] Persistent execution history
- [x] Status
- [x] Last run
- [x] Next run
- [x] Duration
- [x] Structured results
- [x] Manual Run Now

## 39.2 Metadata Sync Job

- [x] Registered metadata synchronization job
- [x] Periodic execution
- [x] Refresh policy
- [x] Checked/refreshed/skipped/failed result concepts
- [x] Partial-failure recording
- [x] Execution history

## 39.3 Future Improvements

Not blockers for the current self-hosted single-worker model:

- [ ] Make checked/refreshed/skipped/failed accounting more rigorous
- [ ] Remove any undesirable GET-side effects
- [>] Atomic job claim/locking if multiple workers are ever supported
- [>] Async Run Now returning `202`
- [>] Configurable stale timeout per job

---

# 40. Logs

- [x] Administrator-only access
- [x] Backend authorization
- [x] Independent UI from Server Health
- [x] Timestamp
- [x] Level
- [x] Logger/source
- [x] Safe message
- [x] Level filtering
- [x] Pagination/limit
- [x] Refresh
- [x] Independent loading/error state
- [x] Sensitive information must not be exposed

---

# 41. Import / Export

## 41.1 Export

Infrastructure supports or is intended to support portable user data including:

- [x] Library
- [x] Watch History
- [x] Ratings
- [x] Relevant configuration/user data
- [x] Versioned format

## 41.2 Import

- [x] File selection
- [x] Version validation
- [x] Preview/summary
- [x] Library import
- [x] History import
- [x] Ratings import
- [x] Duplicate avoidance
- [x] Conflict handling
- [x] Progress
- [x] Final summary
- [x] Partial-failure support

## 41.3 Remaining Work

- [ ] Make date-sensitive tests independent from the real clock
- [>] Review partial-import UX as real usage reveals issues

---

# 42. Localization

Localization is a future coherent workstream rather than a collection of isolated string replacements.

- [ ] Define localization strategy
- [ ] Flutter i18n infrastructure
- [ ] Define backend translation scope
- [ ] Extract hardcoded strings
- [ ] English
- [ ] Portuguese
- [ ] Language selector
- [ ] Persist language
- [ ] Send language to TMDB
- [ ] Future TVDB language behavior
- [ ] Future IMDb/provider language behavior
- [ ] Fallback strategy
- [ ] Localized dates
- [ ] Localized numbers
- [ ] Localization tests

---

# 43. Backups

A real SofaWatch backup strategy has not yet been implemented.

Future work:

- [>] SQLite backup strategy
- [>] Backup target configuration
- [>] Backup scheduling
- [>] Backup history
- [>] Last successful backup
- [>] Backup failure state
- [>] Backup storage availability
- [>] Backup storage free space
- [>] Restore workflow
- [>] Restore documentation
- [>] Server/Storage diagnostics integration

Do not expose fictional backup diagnostics before the feature exists.

---

# 44. Database and Alembic Quality

## 44.1 Current

- [x] SQLite
- [x] SQLAlchemy
- [x] Alembic migrations
- [x] Foreign keys enabled
- [x] Development database upgrade path through Alembic

## 44.2 Release Validation

Before important releases:

```bash
alembic current
alembic check
```

- [ ] Review complete revision chain
- [ ] Test migration from an older real SofaWatch database snapshot
- [ ] Confirm user ID preservation
- [ ] Confirm Library preservation
- [ ] Confirm progress preservation
- [ ] Confirm Episode history preservation
- [ ] Confirm Movie history preservation
- [ ] Confirm ratings preservation
- [ ] Confirm remaining user-scoped relationships

PostgreSQL is not currently part of the SofaWatch roadmap.

---

# 45. Self-hosting and Production

SofaWatch's intended production model remains self-hosted with SQLite.

## 45.1 Production Configuration

- [>] Production FastAPI configuration audit
- [>] Environment-variable documentation
- [>] HTTPS strategy
- [>] Reverse proxy guidance
- [>] Production logging
- [>] Secret management guidance
- [>] Data-directory permissions
- [>] Image-cache management

## 45.2 SQLite Production Operations

- [>] Backup strategy
- [>] WAL handling/recovery guidance
- [>] Migration process
- [>] Upgrade process
- [>] Restore process

## 45.3 Worker

- [>] Production background-worker deployment
- [>] Process supervision/service configuration

## 45.4 Frontend Releases

- [>] Flutter Web release build
- [>] iOS release build
- [>] Android release build
- [>] Production server URL/configuration strategy

---

# 46. Testing

## 46.1 Backend

- [x] pytest
- [x] Route tests
- [x] Service tests
- [x] Repository tests
- [x] Authentication tests
- [x] Authorization tests
- [x] Provider tests
- [x] Background-job tests
- [x] Statistics tests
- [x] Viewing/history tests

Standard full suite:

```bash
pytest -q
```

## 46.2 Frontend

- [x] Flutter tests
- [x] Cubit/BLoC tests
- [x] Repository tests
- [x] DTO/mapping tests
- [x] Widget tests
- [x] Navigation/interaction tests
- [x] Error-state tests
- [x] Responsive behavior tests where implemented

Standard full suite:

```bash
flutter test
```

## 46.3 Quality Workflow

Preferred workflow:

1. Inspect current implementation.
2. Make a focused change.
3. Run focused tests.
4. Run analyzer/linting where relevant.
5. Run the relevant full suite.
6. Fix regressions before continuing.

Tests should not be modified merely to hide a real regression.

---

# 47. Current Stable Test Checkpoint

Stable checkpoint recorded on **26 August 2026**:

```text
Backend:  1301 passed
Frontend: 1547 passed
```

At that checkpoint:

- [x] Backend suite green
- [x] Frontend suite green
- [x] Authentication/Multi-user functional
- [x] Legacy local-user concept removed
- [x] Project stable for continued development

Future test counts will naturally change as features and tests are added.

---

# 48. Final Quality Phase

Before the first stable release:

## 48.1 Architecture

- [ ] Global architecture audit
- [ ] Dependency-direction audit
- [ ] Provider-coupling audit
- [ ] Dead-code cleanup
- [ ] Temporary TODO cleanup
- [ ] Remove obsolete compatibility code

## 48.2 UI/UX

- [ ] Loading-state consistency audit
- [ ] Error-state consistency audit
- [ ] Empty-state consistency audit
- [ ] Navigation/context preservation audit
- [ ] Responsive audit
- [ ] Accessibility/semantics audit

## 48.3 Performance

- [ ] Backend performance audit
- [ ] Flutter rendering/performance audit
- [ ] Search/cache review using real usage
- [ ] Provider-call review
- [ ] Database-query review where required

## 48.4 Final Testing

- [ ] Backend full regression
- [ ] Frontend full regression
- [ ] Integration tests
- [ ] Authentication regression
- [ ] Migration regression
- [ ] Legacy database upgrade test
- [ ] Production configuration validation
- [ ] Release smoke test

---

# 49. Product Decisions

The following decisions are already established and should not be reopened without a new product or technical reason.

1. Backend is the source of truth.
2. SofaWatch uses internal IDs after import.
3. TMDB, TVDB, IMDb, and other provider IDs are external identifiers.
4. Library mutations do not belong inside `SearchBloc`.
5. Search is global and unique.
6. Explore is discovery, not a second Search.
7. Administrative endpoints are protected by the backend.
8. Hiding Administrator UI is not authorization.
9. Advanced User Administration is Desktop/Web only.
10. The legacy local-user model has been removed.
11. `is_local` / `isLocal` must not be reintroduced.
12. A new installation creates a real account.
13. The first User becomes Administrator.
14. Open Registration defaults to `false`.
15. Web persistence uses an HttpOnly session cookie.
16. Mobile uses a short-lived access token plus rotating refresh credential.
17. Persistent authentication credentials are stored server-side only as hashes.
18. Passwords use Argon2.
19. Recovery credentials are temporary, hashed, expiring, and single-use.
20. Administrator recovery is available server-side.
21. Username editing is deliberately deferred.
22. Every rewatch is a separate viewing event.
23. Statistics count rewatches.
24. An Ended Show is not automatically Completed.
25. A caught-up Show should not appear in Watch Next.
26. Episode air times must not be invented.
27. TVDB health should not exist before a real TVDB integration exists.
28. IMDb should only use a legitimate/stable source, not fragile scraping.
29. Personal ratings and external ratings are separate concepts.
30. Tooling, caching, and abstractions should solve real problems rather than be added preemptively.
31. Home, Shows, Movies, Explore, Search, and Profile should not duplicate the same feature independently.
32. SQLite remains the intended SofaWatch database; PostgreSQL is not part of the current roadmap.

---

# 50. Maintenance of This Document

This file is intended to evolve with the implementation.

When completing a roadmap item:

1. Verify the actual implementation.
2. Update its status here.
3. Add important behavior or architectural decisions if they affect future work.
4. Avoid documenting implementation details that are no longer true.
5. Link to a dedicated feature document when the implementation becomes too large for this tracker.

For large features, detailed documentation may live in separate files such as:

```text
docs/features/search.md
docs/features/shows.md
docs/features/movies.md
docs/features/authentication.md
docs/features/statistics.md
```

This document should remain the master implementation-status index even when deeper feature documentation is split into separate files.

---

## Related Documentation

- [Project README](../../README.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
- [Technical Documentation](../README.md)
