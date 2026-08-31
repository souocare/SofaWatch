# Frontend API Contract

This document defines the main contract between the SofaWatch Flutter application and the FastAPI backend.

It focuses on behavior that the frontend can rely on: identity, authentication, authorization, resource ownership, media imports, Library mutations, viewing events, pagination, errors, dates, provider boundaries, and state synchronization.

For the exact route and schema surface of a running backend, use FastAPI's generated OpenAPI documentation.

---

## 1. Core Contract

The backend is the source of truth for persisted application state and business rules.

The frontend is responsible for:

- presentation;
- local interaction state;
- loading/error/empty states;
- navigation;
- responsive behavior;
- client-side orchestration;
- safe optimistic UI only where explicitly appropriate.

The frontend must not independently redefine backend business rules.

Conceptually:

```text
Flutter
   |
   | HTTP API
   v
FastAPI
   |
   v
Application business rules
   |
   +--> SQLite
   +--> Metadata providers
```

---

## 2. API Base URL

The Flutter client receives the server URL through:

```text
SOFAWATCH_SERVER_URL
```

Example for Flutter Web on the development Mac:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

The API itself is versioned under:

```text
/api/v1
```

Frontend API clients should centralize base URL handling rather than hardcoding server URLs throughout repositories.

---

## 3. Platform-Specific Development URLs

Typical development values:

| Client | Server URL |
| --- | --- |
| Flutter Web on Mac | `http://127.0.0.1:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Physical device | `http://<Mac-LAN-IP>:8000` |

`127.0.0.1` on a physical phone refers to the phone itself.

This is transport configuration, not an API contract difference.

---

## 4. One API Across Platforms

Web, iOS, and Android consume the same application resources.

Do not create separate domain/repository implementations merely because authentication transport differs.

Conceptually:

```text
Web -------------------+
                       |
iOS -------------------+--> /api/v1
                       |
Android ---------------+
```

Platform-specific differences should remain primarily in:

- credential persistence;
- Web cookie behavior;
- navigation/presentation;
- platform integration.

---

# Authentication

## 5. Authentication Bootstrap

Before deciding whether to show Setup, Login, or the authenticated application, the frontend should ask the backend for the current authentication/bootstrap state through the appropriate auth contract.

The backend determines whether:

```text
setup is required
registration is available
an authenticated session exists
```

The frontend must not infer first-run setup from local storage.

---

## 6. First-Run Setup

When the backend reports:

```text
setup_required = true
```

the frontend shows the Setup flow.

The first successfully created account becomes the initial Administrator.

After setup succeeds:

```text
setup_required = false
```

and the normal authentication flow applies.

The frontend must not decide which account becomes Administrator.

---

## 7. Setup Race Handling

The backend protects against concurrent creation of multiple first administrators.

If another client completes setup first, a second setup attempt may fail because setup is no longer available.

The frontend should:

1. map the backend error safely;
2. refresh bootstrap/auth state;
3. transition to Login or the appropriate authenticated state.

Do not attempt to force the second account to become Administrator client-side.

---

## 8. Open Registration

Public registration is controlled by the backend global setting:

```text
Open Registration
```

Default:

```text
false
```

When registration is closed:

- backend rejects public registration;
- frontend should not show Sign Up.

When open:

- frontend may expose registration.

UI visibility is convenience only; backend enforcement remains authoritative.

---

## 9. Web Authentication

Web uses a persistent server-managed session through an HttpOnly cookie.

The frontend should treat the raw Web session credential as inaccessible.

Do not attempt to:

- read it from JavaScript;
- copy it into localStorage;
- persist it through Flutter storage;
- manually attach it as a Bearer token.

The browser manages the cookie.

---

## 10. Web Requests and Credentials

Web API requests must allow the browser to send the session cookie according to the configured client/CORS behavior.

If Web session restoration fails, inspect:

- cookie presence;
- credential-enabled requests;
- CORS;
- session validity;

rather than introducing client-side persistent tokens.

---

## 11. Native Authentication

Native clients use:

```text
short-lived access token
+
rotating refresh credential
```

The access token authenticates normal API requests.

The refresh credential is used to obtain fresh authentication material when required.

Persistent native credentials must be stored using the application's secure credential-storage abstraction.

---

## 12. Refresh Rotation

Refresh credentials rotate.

Conceptually:

```text
Refresh A
   |
   v
refresh request
   |
   +--> new access token
   +--> Refresh B

Refresh A
   |
   v
invalid from now on
```

After a successful refresh, the frontend must atomically replace its stored refresh credential with the newly returned one.

Continuing to store A after receiving B will break the next refresh.

---

## 13. Refresh Failure

If refresh fails because the session/credential is:

- expired;
- revoked;
- invalid;
- already rotated/consumed;

the frontend should clear the unusable native authenticated state and return to the unauthenticated flow where appropriate.

Do not retry a known-invalid refresh credential indefinitely.

---

## 14. Unified Current User

Whether authentication originated through:

```text
Web cookie
```

or:

```text
Bearer access token
```

protected application endpoints resolve to the same backend `User`.

Frontend domain models should therefore represent one user concept.

Do not reintroduce:

```text
Local User
isLocal
is_local
```

These concepts have been removed.

---

## 15. Bearer Precedence

If a request contains an explicit Bearer token, the backend gives it precedence.

An invalid Bearer token must not silently fall back to a valid Web cookie.

This is intentional.

The frontend should avoid attaching stale Bearer headers to Web requests that are intended to use cookie authentication.

---

## 16. Current User Contract

The authenticated current-user response exposes safe account/profile information.

Conceptually it includes fields such as:

```json
{
  "id": 1,
  "username": "goncalo",
  "email": "user@example.com",
  "display_name": "Gonçalo",
  "is_admin": true
}
```

The exact schema is defined by OpenAPI.

Frontend mapping should convert transport naming such as:

```text
is_admin
```

into the domain naming convention where appropriate:

```text
isAdmin
```

---

## 17. Administrator State

`is_admin` is backend-owned state.

The frontend uses it to decide whether to render Administrator-only sections.

Example:

```text
isAdmin == false
-> do not render Server administration
-> do not make Server admin requests
```

However, the backend independently checks Administrator authorization.

---

## 18. Logout

Logout revokes the current authenticated session.

After success, the frontend should clear relevant local auth state.

Web:

- session is revoked;
- cookie is cleared/invalidated by the auth response flow.

Native:

- session is revoked;
- access-token state is cleared;
- stored refresh credential is cleared.

---

## 19. Log Out Everywhere

Log out everywhere revokes all sessions belonging to the current user.

After invoking it, the current client should also transition to unauthenticated state.

Other users' sessions are unaffected.

---

## 20. Password Change

Authenticated users can change their password using the current-password flow.

The backend validates the current password and owns password-policy/hash behavior.

The frontend should never receive or display password hashes.

---

## 21. Password Recovery

Regular-user recovery may be initiated administratively.

Recovery links/tokens are:

- temporary;
- user-bound;
- single-use.

The frontend recovery flow submits the token and new password to the backend.

After successful recovery, existing sessions for that user are revoked.

Do not treat a recovery token as an authenticated session credential.

---

## 22. Administrator Recovery

Administrator self-recovery is available through a server-side command rather than depending on the authenticated Web UI.

This is not a Flutter API flow.

Do not build a hidden client-side Administrator bypass.

---

## 23. Mobile-to-Web Handoff

Native clients can initiate a temporary authentication handoff for opening SofaWatch Web.

Conceptually:

```text
Mobile authenticated user
        |
        v
request temporary handoff
        |
        v
open browser URL
        |
        v
Web exchanges handoff
        |
        v
Web AuthSession created
```

The handoff credential is:

- short-lived;
- single-use;
- user-bound.

It is not a permanent access or refresh token.

---

# Errors

## 24. Error Shape

Expected application errors use a stable, safe structured contract.

Conceptually:

```json
{
  "error": {
    "code": "example_error",
    "message": "Safe human-readable message."
  }
}
```

Some validation errors may additionally contain structured details.

The frontend data layer should map API errors into application exceptions rather than exposing raw Dio errors to widgets.

---

## 25. Error Codes vs Messages

Frontend behavior should depend on stable error codes where possible.

Do:

```text
code == "admin_required"
-> render/handle authorization failure
```

Avoid:

```text
message.contains("Administrator")
```

Human-readable messages may change or eventually be localized.

---

## 26. HTTP Status Meaning

Important distinctions:

```text
401
-> authentication missing or invalid

403
-> authenticated but not permitted

404
-> resource does not exist or is not accessible

409
-> state conflict

422
-> request validation failure
```

Do not map every non-2xx response to the same generic behavior before the repository/error layer has classified it.

---

## 27. Safe Error Presentation

Raw backend/provider exceptions must not be displayed directly.

Expected flow:

```text
DioException
    |
    v
API error parsing
    |
    v
AppException
    |
    v
AppErrorMessageMapper
    |
    v
safe UI message
```

Widgets should not parse JSON error bodies themselves.

---

## 28. Retry

Retry belongs to the failed operation.

Examples:

```text
initial Search failure
-> retry Search

pagination failure
-> retry pagination

Server section failure
-> retry Server section

one Season failure
-> retry that Season
```

Do not use a global page reload for every isolated failure.

---

# Resource Identity

## 29. Internal IDs

Once a media entity has been imported, SofaWatch internal IDs are authoritative for application operations.

Example:

```text
TMDB ID 1396
    |
    v
import
    |
    v
SofaWatch Show ID 42
```

After import, Show Details/Library/progress routes should use:

```text
42
```

where the endpoint expects a local Show ID.

---

## 30. Provider IDs

Provider IDs are only used where the route explicitly expects provider identity.

Examples include provider-backed:

- Search results;
- import operations;
- metadata mapping.

Do not pass a TMDB ID to an endpoint that expects a local SofaWatch ID merely because both are integers.

---

## 31. Future External Identifiers

Future TVDB/IMDb support should remain transport/domain mapping data.

The frontend should not assume every media entity has:

```text
tmdbId
tvdbId
imdbId
```

as required top-level identity fields.

External identifiers may be absent.

---

# Search

## 32. Search Is Global

SofaWatch has one global Search capability.

Supported media:

```text
All
TV Shows
Movies
```

Explore is not a second Search implementation.

Web/Desktop and Mobile may present Search differently while sharing the same domain/application behavior.

---

## 33. Search Result Contract

The backend normalizes provider media into a common Search result contract.

The frontend should not parse raw TMDB `media_type` payloads directly inside presentation widgets.

A normalized result should provide enough information for presentation such as:

```text
provider identity
media type
title
year/date where available
poster/image
rating where available
overview/preview metadata where applicable
local/import/library state where contractually exposed
```

Exact fields are defined by OpenAPI/current DTOs.

---

## 34. Search Media Types

Frontend domain code should use the shared media-type abstraction rather than string comparisons scattered through widgets.

Provider-specific values should be normalized in the data layer.

People are intentionally excluded from the current Search media contract.

---

## 35. Search Query Behavior

The Search application layer owns client interaction behavior such as:

- debounce;
- minimum query handling;
- empty-query behavior;
- stale/out-of-order response protection;
- preserving previous results during appropriate loading states.

The backend owns provider querying, normalization, and server-side caching.

---

## 36. Search Pagination

Search pagination is page-based where defined by the provider-backed contract.

Conceptually:

```json
{
  "page": 1,
  "results": [],
  "total_pages": 10,
  "total_results": 194
}
```

The frontend should:

- append successful next pages;
- preserve existing results during pagination;
- expose pagination failure separately;
- prevent duplicate concurrent page loads.

---

## 37. Search Filters

The active Search filter is part of Search state.

Changing filter may require a new first-page request.

The frontend should not combine results from incompatible query/filter combinations.

---

## 38. Search State Preservation

Opening a media preview should not unnecessarily destroy:

- query;
- filter;
- loaded pages;
- result list;
- scroll position.

Search context preservation is a frontend navigation/state responsibility.

---

## 39. Search Library Mutation Synchronization

Immediate mutation of already-rendered Search rows after Library actions without rerunning Search remains an area for future refinement.

Do not introduce duplicate Search ownership into Library Cubits to patch this superficially.

---

# Import and Library

## 40. Search Result Is Not a Local Entity

A provider Search result may not yet exist locally.

Therefore:

```text
SearchResult
!=
Show
!=
Movie
```

until import has resolved/created the local entity.

---

## 41. Import Is Separate from Library Membership

The frontend must preserve this distinction:

```text
provider media
    |
    v
import
    |
    v
local media
    |
    v
optional Library mutation
```

Do not assume successful import automatically means the media is in the user's Library.

---

## 42. Import Idempotency

Provider import endpoints intended as idempotent may safely be called again for the same provider identity without intentionally creating duplicate local entities.

The frontend should still avoid unnecessary duplicate requests.

Idempotent import does not mean every mutation endpoint is idempotent.

---

## 43. Library Is User-Scoped

Library state belongs to the authenticated user.

The frontend must not supply arbitrary user IDs to normal Library operations.

The backend derives ownership from the authenticated identity.

---

## 44. Library Media Types

A Library entry references either:

```text
Show
```

or:

```text
Movie
```

The frontend should map this explicitly.

Do not construct an impossible Library entry containing both media identities.

---

## 45. Library State Mutations

After a successful Library mutation, update affected UI state through the owning feature/application layer.

Examples:

- Show Details Library button;
- Movie Details Watchlist state;
- Explore card;
- Library page.

Avoid having `SearchBloc` become the owner of Library business mutations.

---

# Shows, Seasons, and Episodes

## 46. Show Details

Show Details consumes local SofaWatch Show identity.

The response/domain may include:

- metadata;
- Library state;
- progress;
- Seasons;
- image information;
- provider-derived metadata.

Do not make presentation widgets perform independent TMDB requests.

---

## 47. Lazy Season/Episode Loading

Episodes are not necessarily synchronized for every Season during initial Show import.

Expected frontend flow:

```text
open Show
    |
    v
render Seasons
    |
    v
expand Season
    |
    v
load/synchronize that Season's Episodes
```

Each Season can therefore have independent loading/error state.

---

## 48. Independent Season Failures

One Season failing must not imply that every Season failed.

The frontend should support:

```text
Season A -> success
Season B -> failure + Retry
Season C -> success
```

Do not replace the entire Show Details page with an error because one Season request failed.

---

## 49. Episode Watched State

The backend is authoritative for:

```text
is_watched
watch_count
watched_at
```

Frontend code should not derive authoritative watch count from locally remembered button taps.

---

## 50. Mark Watched

Mark Watched creates a viewing event according to backend rules.

After success, affected frontend state may need coordinated refresh/update:

- Episode row;
- Season progress;
- Show progress;
- Watch Next;
- Haven't Watched in a While;
- Watch History;
- Statistics when next loaded/refreshed.

The mutation response/backend state remains authoritative.

---

## 51. Rewatch

A rewatch creates a new viewing event.

Do not call an "update watched date" behavior as a substitute.

Example:

```text
watch_count = 2

Watched Again
    |
    v
new event

watch_count = 3
```

---

## 52. Episode Watch History

Episode history exposes individual viewing events ordered by:

```text
watched_at DESC
```

Each row is a distinct event.

Two entries for the same Episode are not duplicates if they represent two viewings.

---

## 53. Removing an Episode Watch Event

Deleting one watch event removes only that viewing.

The backend recalculates Episode derived state from remaining events.

The frontend should use the returned/refreshed backend state rather than guessing the new `watched_at`.

---

## 54. Unwatched vs Removing One Event

These concepts must remain distinct.

If an Episode has three watch events, removing one should not necessarily make it unwatched.

Do not implement UI logic that assumes:

```text
delete event
==
mark completely unwatched
```

---

## 55. Watch Next

Watch Next is backend-derived application state.

Frontend should display the returned ordering/inclusion rather than independently reproducing the entire business rule.

Important backend semantics include:

- caught-up Shows do not appear;
- Ended does not automatically mean Completed;
- Shows with unwatched eligible Episodes may remain;
- no fake next Episode is invented.

---

## 56. Haven't Watched in a While

This collection is also backend-derived.

The frontend should not independently calculate inactivity thresholds from raw watch history unless the contract explicitly moves that responsibility client-side.

---

## 57. Haven't Started

The backend identifies appropriate not-started Library Shows.

The frontend may render a Start action using the eligible first Episode returned/resolved by the contract.

---

## 58. Upcoming

Upcoming is date-based.

The frontend can group/present returned Episodes into:

- Today;
- Tomorrow;
- later dates;
- historical ranges;

according to the feature contract.

Do not invent an Episode air time when only `air_date` exists.

---

## 59. Future Episode Mutations

If Mark Watched-before-air-date is prohibited by backend rules, the frontend should also disable/hide the action for good UX.

Backend validation remains required.

Never rely only on disabled UI.

---

# Movies

## 60. Movie Details

Movie Details uses a local SofaWatch Movie ID after import.

The domain should keep distinct:

- metadata;
- Library/watchlist state;
- watched state;
- watch history;
- personal rating;
- future external ratings.

Do not merge these into one ambiguous `rating`/`status` concept.

---

## 61. Movie Watch Events

Movie viewing history is event-based just like Episode history.

Rewatch:

```text
new MovieWatchEvent
```

not replacement of the previous event.

Statistics therefore count repeated Movie viewings.

---

## 62. Movie Library State

A Movie may exist locally without being in the user's Library/watchlist.

The frontend must not infer Library membership from local existence.

---

# Explore

## 63. Explore Contract

Explore consumes discovery-oriented backend resources.

Examples:

- Trending;
- Popular TV;
- Popular Movies;
- Genre filters.

Explore state should remain separate from global Search state.

---

## 64. Explore Filters

TV and Movie genre filters may be independent.

The frontend should preserve the filter state associated with each section rather than forcing one global Genre filter where the product behavior does not call for it.

---

## 65. Explore Context Preservation

Opening/closing previews should preserve:

- active filters;
- vertical scroll;
- horizontal section position where practical;
- already loaded discovery state.

This is a presentation/application-state responsibility.

---

# Statistics and History

## 66. Statistics Are Backend-Derived

The backend calculates viewing statistics from persisted user data.

The frontend should render returned metrics rather than recomputing totals from whatever subset of History happens to be loaded.

---

## 67. Rewatch Statistics

Rewatches count as additional viewings.

Therefore:

```text
total viewings
```

and:

```text
unique media
```

are intentionally different metrics.

Do not deduplicate viewing events in frontend Statistics.

---

## 68. History

Combined History is ordered globally by:

```text
watched_at DESC
```

and can contain:

- Episode events;
- Movie events.

The media type should be explicit enough for the frontend to navigate to the correct detail experience.


Full History supports an optional server-side media filter:

```text
    media_type=episode
    media_type=movie
```
When omitted, History returns the combined Episode/Movie timeline.

Filtering must happen before pagination on the backend. The frontend must
not request a combined page and discard items of the unwanted media type,
because doing so would produce incomplete pages and incorrect pagination.

---

## 69. History Pagination

When full History is paginated, the frontend should:

- preserve existing items while loading more;
- append successful pages;
- avoid duplicate requests;
- surface pagination errors separately;
- retain current filters such as All/Episodes/Movies.

History pagination is cursor-based.

The frontend must treat `next_cursor` as opaque and send it back unchanged
for the same History media scope.

A cursor obtained for Episode-only History must not be reused for Movie-only
History, and vice versa.

Changing History media scope starts a new first-page request.

---

# Home and Profile

## 70. Home Reuses Domain Capabilities

Home should consume existing backend/application capabilities such as:

- Statistics;
- Watch Next;
- Upcoming;
- recent History.

Do not create separate frontend business rules merely because the same data appears on Home.

---

## 71. Profile Section Isolation

Profile sections should be independently loadable where possible.

For example:

```text
Statistics -> success
Library    -> success
History    -> failure
Server     -> success
```

The frontend should not convert one section failure into a full Profile failure unless the failed resource is essential to the whole page.

---

## 72. Administrator Profile Sections

Administrator-only Profile sections should only instantiate/load their repositories/Cubits when:

```text
currentUser.isAdmin == true
```

This avoids unnecessary forbidden requests.

Backend authorization still protects every Admin endpoint.

---

# Background Jobs

## 73. Background Job API

Background-job data is Administrator-only.

The frontend may consume:

- job identity;
- status;
- schedule;
- last run;
- next run;
- duration;
- structured result;
- execution history.

Do not derive scheduler truth from local timers.

---

## 74. Run Now

A manual Run Now action should use the backend operation and then refresh/reconcile job state.

The frontend should prevent accidental duplicate submission while the request is in progress where appropriate.

Future backend execution semantics may evolve toward asynchronous `202` behavior; clients should not assume this unless the current route contract states it.

---

## 75. Job Partial Failures

A metadata job may finish after some items fail.

The frontend should preserve distinctions such as:

```text
checked
refreshed
skipped
failed
```

when exposed.

Do not reduce every non-zero failure count to "the whole job failed" unless backend status says so.

---

# Server Administration

## 76. Server Health

Server Health is Administrator-only.

The frontend should represent component health independently where returned.

Conceptually:

```text
overall
database
TMDB
```

A degraded provider does not necessarily mean the whole application is unavailable.

---

## 77. Provider Configuration Status

Diagnostics should expose safe state such as:

```json
{
  "configured": true,
  "status": "healthy",
  "latency_ms": 42
}
```

The frontend must never expect provider secrets from diagnostics.

---

## 78. TVDB Health

Do not render fake TVDB health as if the integration exists.

TVDB diagnostics should only become part of the contract when the TVDB provider is actually implemented.

---

## 79. Storage/Database Diagnostics

Administrative diagnostics may expose safe operational data such as:

- database engine;
- database size;
- WAL size;
- integrity state;
- foreign-key state;
- Alembic revision;
- storage capacity;
- cache size.

Do not treat these diagnostics as normal user-facing domain data.

---

# Dates, Times, and Localization

## 80. Date-Only Fields

A field such as:

```json
{
  "air_date": "2026-09-26"
}
```

is a calendar date.

The frontend should parse it as a date concept and format it according to UI locale.

Do not interpret it as midnight UTC and accidentally shift the displayed calendar day.

---

## 81. Timestamps

A timestamp such as:

```json
{
  "watched_at": "2026-09-26T22:15:00+00:00"
}
```

represents an instant.

The frontend may convert it to local time for presentation.

---

## 82. Missing Air Time

If the backend/provider does not know an air time, the API should not invent one.

Frontend should render date-only UI rather than displaying a fabricated `00:00`.

---

## 83. Localized Presentation

Backend should return structured values.

Frontend owns localized display of:

- dates;
- times;
- durations;
- numbers.

Future application localization may also influence metadata language requested from providers, but display localization and provider metadata language remain distinct concerns.

---

# Nullability and Collections

## 84. Optional Metadata

Provider metadata can be incomplete.

Frontend DTOs must correctly handle fields that are legitimately nullable.

Examples:

- poster;
- backdrop;
- overview;
- air date;
- release date;
- rating;
- network/provider metadata.

Do not convert missing data into misleading defaults.

---

## 85. Empty Collections

Collections should normally map to empty Dart collections rather than nullable collections when the API schema defines them as arrays.

Prefer:

```dart
[]
```

semantics over requiring every widget to distinguish:

```text
null
vs
empty
```

when there is no semantic difference.

---

# DTO and Domain Mapping

## 86. DTOs Belong in the Data Layer

JSON decoding belongs in:

```text
data/
```

not:

```text
domain/
presentation/
```

Typical flow:

```text
JSON
  |
  v
DTO
  |
  v
Mapper
  |
  v
Domain Model
```

Domain models should not import Dio or depend on JSON keys.

---

## 87. Snake Case vs Dart Naming

Backend transport naming may use:

```text
watched_at
is_admin
total_results
```

Dart domain naming should follow Dart conventions:

```text
watchedAt
isAdmin
totalResults
```

Mapping belongs in the data layer.

---

## 88. Enum Mapping

Transport enums should be mapped explicitly.

Do not scatter string comparisons such as:

```dart
if (json['status'] == 'healthy')
```

through presentation code.

Unknown enum values should be handled according to the feature's compatibility strategy rather than causing obscure widget crashes.

---

## 89. Invalid Response Handling

If the backend response violates the expected DTO contract:

```text
JSON decode/DTO mapping
    |
    v
AppException / invalid response
```

The frontend should surface a safe generic error and retain technical details only for debugging/logging.

Do not silently construct partially invalid domain entities.

---

# Pagination

## 90. Local Pagination

Local resources may use offset/limit-style pagination.

Conceptually:

```json
{
  "items": [],
  "total": 42,
  "offset": 0,
  "limit": 20,
  "has_next": true
}
```

Frontend pagination models should preserve these semantics.

---

## 91. Provider Pagination

Provider-backed Search/discovery may use page-based pagination.

Conceptually:

```text
page
totalPages
totalResults
```

Do not force offset/limit and page pagination into one abstraction if that makes the code less clear.

---

## 92. Pagination Loading State

Pagination loading should not replace the existing list with a full-page loader.

Expected UX:

```text
existing results remain interactive
+
loading indicator at end
```

Pagination failure should similarly preserve existing data.

---

# Images

## 93. Image URLs

The frontend should consume SofaWatch-provided image URLs/paths rather than construct TMDB URLs throughout presentation code.

This allows the backend to evolve:

- image caching;
- provider selection;
- fallback;
- future TVDB support.

---

## 94. Missing Images

A missing image is valid metadata state.

Frontend should render an appropriate placeholder.

Do not treat every missing poster/backdrop as a failed API request.

---

# State Synchronization

## 95. Mutation Ownership

The feature that owns a mutation should perform it through its repository/application layer.

Examples:

```text
Library mutation
-> Library/application capability

Watch mutation
-> viewing/progress capability
```

Other screens may refresh or reconcile afterward.

Do not put unrelated mutations into `SearchBloc` simply because Search currently displays the button.

---

## 96. Backend Response Wins

After a mutation, if local optimistic state conflicts with the backend response, the backend state wins.

This is especially important for:

- watch counts;
- watched timestamps;
- Library status;
- progress;
- Administrator/security state.

---

## 97. Coordinated Refresh

Some mutations affect several derived views.

Example:

```text
Mark Episode Watched
    |
    +--> Episode
    +--> Season progress
    +--> Show progress
    +--> Watch Next
    +--> inactivity collection
    +--> History
```

The frontend should coordinate affected state without turning every feature into one global mutable store.

---

## 98. Partial Refresh Failure

If one secondary refresh fails after the primary mutation succeeded, do not falsely tell the user that the mutation failed.

Example:

```text
watch event creation -> success
Watch Next refresh    -> success
History refresh       -> failure
```

The viewing event still exists.

The UI should preserve correct primary state and handle the secondary failure independently where possible.

---

# Responsive and Navigation Contract

## 99. API Is Presentation-Agnostic

The backend should not return different business data because the client is:

```text
mobile
desktop
Web
```

unless a route explicitly has a justified platform-specific purpose.

Responsive differences belong primarily to Flutter presentation.

---

## 100. Detail Navigation

When a list/history/search result navigates to Details, use local SofaWatch IDs when the entity is already imported.

Provider preview flows may still operate on provider identity until import occurs.

Keep these two navigation cases distinct.

---

## 101. Modal vs Page Presentation

The same domain capability may render as:

```text
mobile bottom sheet
desktop dialog/modal
full page
```

without requiring a separate backend API.

---

# Security

## 102. Never Persist Web Session Secrets Client-Side

Do not copy Web session credentials into:

- localStorage;
- SharedPreferences;
- visible Dart state;
- logs.

The HttpOnly cookie model is deliberate.

---

## 103. Never Log Credentials

Frontend logging must not expose:

- passwords;
- access tokens;
- refresh credentials;
- recovery tokens;
- handoff tokens;
- cookies.

Error logging should redact sensitive headers/data.

---

## 104. Do Not Send User IDs for Ownership

Normal user-scoped operations should derive user identity from authentication.

Avoid API designs such as:

```text
GET /users/{arbitrary_user_id}/library
```

for ordinary self-service operations unless the endpoint is explicitly an authorized administrative capability.

---

## 105. Administrator UI Is Not Security

Even if a non-admin never sees the button, assume they can manually call the URL.

Backend authorization is mandatory.

Frontend's responsibility is to avoid presenting/loading inaccessible capabilities unnecessarily.

---

# Testing the Contract

## 106. Backend Contract Tests

Backend tests should verify:

- expected status;
- response schema;
- error code;
- authentication;
- authorization;
- user isolation;
- validation;
- mutation semantics.

---

## 107. Repository Tests

Frontend repository tests should verify:

- HTTP method;
- endpoint path;
- query parameters;
- request body;
- response DTO mapping;
- error mapping.

Mocking should happen at a boundary appropriate to the test.

---

## 108. Cubit/BLoC Tests

Application tests should verify state transitions.

Example:

```text
Initial
-> Loading
-> Success
```

and:

```text
Success with old items
-> pagination loading
-> pagination failure
```

without requiring a real HTTP server.

---

## 109. Widget Tests

Widget tests should focus on presentation behavior derived from application state.

Examples:

- loading;
- empty;
- success;
- failure;
- Retry;
- Administrator visibility;
- responsive behavior.

Do not duplicate repository JSON-mapping tests in widgets.

---

# Contract Evolution

## 110. Changing an Existing Field

Changing:

```text
field name
type
nullability
meaning
```

requires coordinated backend/frontend work.

Typical update surface:

```text
Pydantic schema
route/service behavior
backend tests
Flutter DTO
mapper
domain model if required
Cubit/application behavior
widget tests
documentation
```

---

## 111. Adding an Optional Field

Adding an optional field is generally easier to evolve, but the frontend must still decide whether:

- it belongs only in DTO;
- it belongs in domain;
- it affects presentation;
- older/missing values are valid.

Do not add fields to domain models merely because the provider happens to return them.

---

## 112. Removing a Field

Before removing an API field, search the Flutter codebase for consumers.

Do not rely only on compilation if dynamic JSON access exists.

Prefer explicit DTOs so contract breakage is visible.

---

## 113. Future TVDB Contract

When TVDB is added, avoid making frontend business logic provider-aware unless provenance is genuinely user-visible.

Preferred:

```text
Show metadata
Episode metadata
External identifiers
```

Backend provider adapters decide where metadata comes from.

Provider-specific diagnostic/admin screens may expose provider identity explicitly.

---

## 114. Future External Ratings

Personal and external ratings remain separate.

Conceptually:

```text
personalRating
externalRatings:
    TMDB
    IMDb
```

Do not overload one `rating` field with changing provenance.

---

# Adding a New Frontend API Integration

## 115. Recommended Workflow

For a new API capability:

```text
1. inspect current backend route/schema
2. define/update domain model if needed
3. define repository contract
4. implement DTO
5. implement mapper
6. implement API repository
7. map errors
8. implement Cubit/BLoC orchestration
9. implement presentation
10. focused tests
11. flutter analyze
12. relevant/full flutter test
```

Do not begin by decoding raw JSON directly inside a widget.

---

## 116. Before Adding a New Endpoint

Ask whether the backend already exposes the underlying capability.

Do not create:

```text
/home/watch-next
/profile/watch-history
/shows/watch-next-copy
```

if reusable resource endpoints already provide the same domain data.

UI composition should not automatically create duplicate API concepts.

---

# Debugging Contract Problems

## 117. When Flutter and Backend Disagree

Inspect in this order:

```text
1. OpenAPI/current backend schema
2. actual HTTP request
3. actual HTTP response
4. frontend DTO
5. mapper
6. domain model
7. Cubit/BLoC
8. widget
```

This usually identifies the first broken boundary quickly.

---

## 118. Do Not Work Around Backend Bugs in Presentation

If backend returns:

```text
watch_count = 1
```

when the database has three watch events, do not make the widget count local History rows.

Fix the backend invariant.

Similarly, if frontend DTO maps `watch_count` incorrectly, fix the mapper rather than changing backend semantics.

---

# Contract Checklist

Before considering an integration complete:

```text
[ ] correct API route is used
[ ] auth mechanism is correct for platform
[ ] user ownership remains backend-scoped
[ ] Administrator authorization is backend-enforced
[ ] provider IDs and local IDs are not confused
[ ] DTO matches response
[ ] nullability is handled
[ ] enums are mapped
[ ] dates and timestamps retain correct semantics
[ ] API errors map to AppException
[ ] loading/error/empty states are represented
[ ] mutation response is treated as authoritative
[ ] affected derived state is reconciled
[ ] focused backend tests pass
[ ] focused frontend tests pass
[ ] analyzer/lint passes
[ ] relevant full suites pass
```

---

## Related Documentation

- [API Overview](overview.md)
- [Architecture Overview](../architecture/overview.md)
- [Data Flow](../architecture/data-flow.md)
- [Authentication Architecture](../architecture/authentication.md)
- [Provider Architecture](../architecture/provider-architecture.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Development Setup](../development/setup.md)
- [Debugging](../development/debugging.md)
- [Testing](../development/testing.md)
- [Implementation Status](../features/implementation-status.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
