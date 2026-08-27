# Frontend Architecture

This document describes the architecture of the SofaWatch Flutter frontend.

It focuses on application boundaries, dependency direction, navigation, state management, responsive behavior, platform-specific authentication, data mapping, dependency injection, design-system usage, and the rules that should guide future frontend development.

> [!NOTE]
> SofaWatch is under active development. This document describes the intended current architecture and should evolve alongside meaningful frontend architectural changes.

---

## Overview

SofaWatch uses Flutter for Web, iOS, and Android.

The frontend is structured around a Feature First organization with a lightweight Clean Architecture approach.

At a high level:

```text
User Interaction
       |
       v
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
       |
       v
Backend API
```

The frontend owns:

- presentation
- navigation
- interaction state
- loading/error/empty states
- responsive behavior
- platform-specific UI behavior
- local client configuration
- transport orchestration

The backend remains the source of truth for persisted application state and business rules.

---

# 1. Core Principles

## 1.1 Feature First

Frontend code should be organized around product capabilities rather than global technical categories.

A typical feature looks like:

```text
features/<feature>/
├── presentation/
├── application/
├── domain/
└── data/
```

Examples include:

- Home
- Shows
- Show Details
- Movies
- Movie Details
- Search
- Explore
- Library
- History
- Statistics
- Profile
- Authentication
- Server Setup
- Server Administration
- Background Jobs
- Logs
- Import / Export
- Security

Not every feature requires all four layers. Small presentation-only behavior should not gain artificial domain/data layers without a real responsibility.

---

## 1.2 Backend as Source of Truth

The frontend should not independently redefine backend-owned business rules.

Examples of backend-owned state include:

- Library membership
- watched/unwatched state
- watch count
- watched-at timestamps
- rewatches
- registration availability
- Administrator authorization
- viewing history
- statistics source data

The frontend may optimistically represent a pending action, but the backend remains authoritative.

---

## 1.3 Shared Logic Across Platforms

Web, iOS, and Android should share:

- domain models
- repository contracts
- application state
- Cubits/BLoCs
- API repositories

when possible.

Platform-specific behavior should normally be isolated to presentation or transport/session details.

Conceptually:

```text
Shared Domain / Application
           |
           v
Adaptive Presentation
      /           \
     v             v
 Mobile         Web/Desktop
```

---

# 2. Project Structure

At a high level:

```text
lib/
├── app/
│   ├── router/
│   ├── theme/
│   ├── app.dart
│   ├── app_dependencies.dart
│   └── bootstrap.dart
│
├── core/
│   ├── api/
│   ├── errors/
│   ├── logging/
│   ├── server/
│   ├── storage/
│   └── widgets/
│
├── features/
│   └── <feature>/
│       ├── presentation/
│       ├── application/
│       ├── domain/
│       └── data/
│
└── main.dart
```

The exact folder set may vary as features evolve, but responsibilities should remain clear.

---

# 3. Application Bootstrap

The Flutter entry point should remain minimal.

Conceptually:

```text
main.dart
   |
   v
bootstrap(...)
   |
   v
SofaWatchApp
```

Bootstrap is responsible for initializing cross-cutting infrastructure before `runApp`.

Current responsibilities include:

- Flutter binding initialization
- Web URL strategy
- BLoC observer setup
- local key/value storage
- persisted server configuration
- backend URL resolution
- API client initialization
- server connection infrastructure
- Search repository setup
- in-memory Search cache
- application dependency composition

Application startup should avoid unnecessary feature loading before the relevant route or screen needs it.

---

# 4. Dependency Injection

Shared dependencies are provided above feature routes through repository providers or route-level composition.

Examples of cross-cutting dependencies include:

- `ApiClient`
- server configuration repository
- server connection tester
- authentication repository
- Search repository

Feature-specific dependencies should be created as close as practical to the part of the widget tree that owns their lifetime.

Avoid a single giant global provider tree containing every feature Cubit.

---

## 4.1 Ownership and Lifetime

Dependency lifetime should match feature lifetime.

Examples:

```text
App-wide dependency
    |
    +-- ApiClient

Route-owned dependency
    |
    +-- ShowDetailsCubit

Modal-owned dependency
    |
    +-- SearchBloc
```

This makes disposal behavior explicit and reduces hidden coupling.

---

# 5. Presentation Layer

The presentation layer contains:

- pages
- views
- widgets
- dialogs
- modal surfaces
- bottom sheets
- responsive layouts
- navigation actions
- local ephemeral interaction state

Presentation should not:

- parse raw JSON
- call Dio directly
- contain SQL/backend rules
- own provider-specific mapping
- duplicate domain rules from the backend

---

## 5.1 Widget Design

Preferred conventions:

- use `StatelessWidget` when no real mutable local state exists
- use private widgets to split large UI files
- use `const` whenever practical
- use `ValueKey` when it improves state stability or tests
- keep `build` methods readable
- use shared design tokens
- keep business logic out of widgets
- make Loading/Error/Empty states explicit

`StatefulWidget` is appropriate for local presentation-only concerns such as:

- animation controllers
- focus nodes
- scroll controllers
- text controllers
- temporary interaction state

---

# 6. Application Layer

The application layer contains Cubits, BLoCs, states, and orchestration.

It coordinates user actions with repositories without knowing transport details.

Examples:

```text
load()
retry()
refresh()
markWatched()
removeWatchEvent()
save()
```

Application state should describe what the UI needs to render rather than expose Dio responses or raw backend payloads.

---

# 7. State Management

SofaWatch uses `flutter_bloc`.

## 7.1 Cubit

Cubit is preferred where actions map directly to state transitions.

Typical flow:

```text
Initial
   |
   v
Loading
   |
   +----> Success
   |
   +----> Failure
```

Some features may preserve previous successful data during refresh:

```text
Success
   |
   v
Refreshing(previousData)
   |
   +----> Success(updatedData)
   |
   +----> Failure(previousData retained)
```

---

## 7.2 BLoC

BLoC is useful where event-driven coordination is more complex.

Global Search is a good example because it handles:

- query changes
- debounce
- filters
- pagination
- retry
- stale-response protection
- out-of-order responses
- state preservation

BLoC should be chosen for real event complexity, not as a default requirement.

---

## 7.3 Independent Failure Boundaries

Large pages should compose smaller feature states.

Examples:

- Profile statistics may succeed while Server diagnostics fail
- one Season may fail while others remain available
- History failure should not block Library

A page should not necessarily have one giant all-or-nothing state.

---

# 8. Domain Layer

The domain layer contains:

- entities
- repository contracts
- value/domain objects where useful

The domain layer should remain independent from:

- Flutter UI
- Dio
- raw JSON
- provider response formats

Example:

```text
domain/repositories/search_repository.dart
```

defines the contract.

The data layer supplies:

```text
data/repositories/api_search_repository.dart
```

---

# 9. Data Layer

The data layer handles transport and persistence implementation details.

Responsibilities include:

- API repositories
- DTOs
- JSON parsing
- mapping
- local-storage adapters
- caching decorators
- transport-specific authentication behavior

Typical flow:

```text
Backend JSON
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

Widgets should consume domain/application data rather than raw DTOs.

---

# 10. API Client

SofaWatch uses Dio behind an `ApiClient` abstraction.

The API client centralizes:

- base URL
- `/api/v1` handling
- request headers
- timeouts
- authentication headers/session behavior
- transport error mapping

Application features should normally depend on repositories rather than directly on `ApiClient`.

---

## 10.1 Error Mapping

Dio errors should be translated into application exceptions below the presentation layer.

The UI should receive meaningful application failures such as:

- network unavailable
- timeout
- authentication failure
- provider failure
- invalid response
- generic server failure

Raw Dio exceptions should not spread through widgets.

---

# 11. Server Configuration

The frontend supports a persisted backend URL.

Configuration may come from:

- previously stored server configuration
- compile-time `SOFAWATCH_SERVER_URL`

Stored configuration takes precedence when present.

Conceptually:

```text
Startup
   |
   +-- stored server URL?
   |       |
   |       +-- yes --> use it
   |
   +-- otherwise --dart-define URL?
           |
           +-- yes --> use it
```

Native clients may expose a Server Setup flow when no URL exists.

---

# 12. Platform Configuration

## 12.1 Web

Local Web development typically uses:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

## 12.2 iOS Simulator

```bash
flutter run -d "<iPhone Simulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

## 12.3 Android Emulator

```bash
flutter run -d "<Android Emulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://10.0.2.2:8000
```

## 12.4 Physical Device

Physical devices must use the development machine's LAN address.

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://<LAN-IP>:8000
```

---

# 13. Native Server Setup

Native clients support a server-configuration flow.

Conceptually:

```text
No configured server
       |
       v
Server Setup
       |
       v
Test connection
       |
       v
Persist URL
       |
       v
Continue to app
```

Server-connection logic should remain behind repository/service abstractions instead of living directly inside page widgets.

---

# 14. Navigation

SofaWatch uses `go_router`.

The main product areas are hosted through:

```text
StatefulShellRoute.indexedStack
```

Primary branches:

```text
Home
Shows
Movies
Explore
Profile
```

Each branch keeps its own navigation state.

This helps preserve context while switching between main sections.

---

## 14.1 Root Navigator

Global experiences should be placed on the root navigator when they should not belong exclusively to one branch.

Examples:

- Search
- Show Details
- Movie Details
- global dialogs/modals where appropriate

This prevents details from inheriting an incorrect tab-specific navigation lifecycle.

---

# 15. Application Shells

SofaWatch uses a platform-adaptive shell.

Conceptually:

```text
AppShell
   |
   +-- Web/Desktop shell
   |
   +-- Mobile shell
```

The branches are shared, but presentation differs.

---

## 15.1 Web/Desktop Shell

Web uses a top-navigation pattern.

Responsibilities include:

- main section navigation
- global Search action
- desktop content layout
- modal-style presentation where appropriate

Desktop layout should avoid excessively wide content and preserve usable density on ultrawide displays.

---

## 15.2 Mobile Shell

Mobile uses a dedicated bottom navigation experience.

Search is integrated into the Dual-Pill experience.

Search should preserve the originating branch and return the user to that context when closed.

Mobile layout must account for:

- safe areas
- small widths
- landscape
- keyboard overlap where relevant

---

# 16. Search Architecture

Search is one global feature.

It is not implemented separately inside Explore.

Shared components include:

- domain model
- repository contract
- API repository
- SearchBloc
- pagination state
- query/filter state

Presentation differs by platform.

## Web

Search uses a modal-style experience on larger layouts.

## Mobile

Search is integrated into the Dual-Pill shell.

The SearchBloc lifecycle belongs to the active Search experience.

---

# 17. Search Cache

Search uses a data-layer cache.

Architecture:

```text
SearchBloc
    |
    v
SearchRepository
    |
    v
CachedSearchRepository
   /             \
  v               v
API Repository   In-memory Cache
```

The cache is intentionally:

- bounded
- in-memory
- TTL-based
- LRU-based
- non-persistent

Caching should remain an implementation detail of the data layer.

---

# 18. Authentication

The frontend exposes a shared authentication model while adapting persistent-session behavior to platform.

---

## 18.1 Shared Authentication State

`AuthCubit` is responsible for high-level authentication state such as:

- restore session
- authenticated
- unauthenticated
- authentication failure
- logout
- logout everywhere

Presentation should not need to understand persistent credential mechanics.

---

## 18.2 Web Authentication

Web uses backend-managed persistent sessions via HttpOnly cookies.

The persistent session credential is unavailable to Flutter/JavaScript.

The frontend may receive and use a short-lived access token for authenticated API requests, but session persistence belongs to the browser/backend cookie flow.

Session restoration is handled through the Web session endpoint.

---

## 18.3 Mobile Authentication

Native clients use:

```text
short-lived access token
        +
rotating refresh credential
```

The client stores the current refresh credential using the frontend's storage abstraction.

After refresh:

```text
old refresh credential
        |
        v
new refresh credential
```

The new credential replaces the previous one.

---

## 18.4 Logout

Platform-specific logout behavior remains behind the auth repository/application layer.

Web revokes its Web session.

Mobile revokes its mobile session and clears stored credentials.

`Log out everywhere` clears current-device state after the backend revokes all sessions owned by the user.

---

# 19. Authentication Routing

Authentication-aware navigation should reflect backend state rather than hardcoded assumptions.

Important flows include:

```text
No users
   |
   v
Setup

Users exist, unauthenticated
   |
   v
Login

Authenticated
   |
   v
Application shell
```

Registration availability is server-driven.

The frontend should not show Sign Up when registration is closed, but backend enforcement remains authoritative.

---

# 20. Mobile-to-Web Handoff

The frontend supports an authenticated mobile user opening SofaWatch Web through a temporary handoff.

Conceptually:

```text
Mobile
  |
  v
Request handoff
  |
  v
Open browser URL
  |
  v
Web exchanges handoff
  |
  v
Authenticated Web session
```

The frontend should treat the handoff as a short-lived exchange mechanism rather than as a persistent token.

---

# 21. DTO and Domain Separation

The frontend should preserve an explicit mapping boundary.

Example:

```text
{
  "is_admin": true
}
      |
      v
ProfileUserDto
      |
      v
ProfileUser(isAdmin: true)
```

Backend naming conventions should not leak unnecessarily into domain objects.

DTO parsing should handle malformed/invalid responses safely and map failures into application exceptions.

---

# 22. Repository Pattern

Repository contracts belong in the domain layer.

Implementations belong in the data layer.

Example:

```text
Domain
  ServerRepository
       ^
       |
Data
  ApiServerRepository
```

This allows:

- Cubit tests with fakes/mocks
- API changes isolated to the data layer
- local storage implementations behind contracts
- decorators such as caching without changing application logic

---

# 23. Profile Composition

Profile is a good example of feature composition.

It may include independently loaded areas such as:

- Statistics
- Library
- History
- Server
- Jobs
- Logs
- Security

The page should compose these capabilities rather than own all their data-fetching logic itself.

Administrator-only sections should not create/load administrative data for non-Administrator users.

---

# 24. Lazy Administrative Loading

Administrative sections should be created only when the authenticated Profile/User state confirms Administrator access.

Conceptually:

```text
Profile loaded
     |
     +-- normal user --> no admin feature construction
     |
     +-- admin -------> create/load admin feature
```

This avoids unnecessary 403 requests and keeps feature ownership clear.

The backend still enforces authorization independently.

---

# 25. Show Details Composition

Show Details contains multiple responsibilities, but they should remain decomposed.

Examples:

- metadata
- Library state
- Seasons
- Episode progress
- watch history
- watched actions

Season state can fail independently.

Episode synchronization should remain feature/application/data logic rather than page-level networking.

---

# 26. Responsive Detail Presentation

Media details should share the same domain/application state while presentation adapts.

Conceptually:

```text
ShowDetailsCubit
       |
       v
ShowDetailsContent
    /           \
   v             v
Mobile Sheet   Desktop Dialog/Page
```

Presentation containers may differ, but business behavior should not.

---

# 27. Design System

Shared design tokens are exported through the application theme layer.

Core tokens include:

```text
AppColors
AppTypography
AppSpacing
AppRadius
AppDurations
AppBreakpoints
```

Widgets should prefer these values over arbitrary styling constants.

---

## 27.1 Colors

Use semantic application colors for:

- surfaces
- text
- borders
- status
- progress
- ratings
- overlays

Avoid feature-local hardcoded color palettes unless they represent a real feature-specific semantic requirement.

---

## 27.2 Typography

Typography is centralized through `AppTypography`.

Manrope is currently used through `google_fonts`.

Runtime font fetching is disabled.

Typography should be semantic rather than manually recreating font size/weight combinations in each widget.

---

## 27.3 Spacing and Radius

Use:

- `AppSpacing`
- `AppRadius`

for reusable layout values.

A component may still have a local fixed dimension if it represents a genuine component constraint rather than a missing global token.

---

## 27.4 Breakpoints

`AppBreakpoints` owns reusable responsive thresholds.

Use local `LayoutBuilder` decisions when the component itself owns the constraint.

Use shared breakpoints when the decision reflects global application behavior.

---

# 28. Responsive Strategy

Responsive design should consider behavior, not only width.

Potential adaptations include:

- navigation model
- content width
- information density
- modal vs sheet
- horizontal vs vertical arrangement
- action placement
- touch vs pointer ergonomics

Avoid using one large collection of width checks scattered throughout unrelated widgets.

---

# 29. Error States

UI failures should be explicit and safe.

Common states include:

```text
Initial
Loading
Success
Empty
Failure
Retrying
PaginationLoading
PaginationFailure
```

A raw exception string should not automatically become user-facing copy.

Use application error mapping to produce safe messages.

---

# 30. Refresh Behavior

Refresh should preserve useful context when practical.

Potential context includes:

- previous loaded data
- selected tab
- scroll position
- filters
- pagination state
- historical ranges

Do not replace usable content with a full-screen loading state when a subtle refresh state is more appropriate.

---

# 31. Local Storage

Small client-side persisted values should be accessed through abstractions.

Examples:

- server URL
- mobile auth credentials
- lightweight preferences

UI code should not call `SharedPreferences` directly if the value represents a domain/application responsibility.

---

# 32. Logging

Frontend logging should help diagnose state and transport failures without exposing:

- passwords
- access tokens unnecessarily
- refresh credentials
- handoff credentials
- sensitive backend data

Debug logging should not become part of user-facing UI.

---

# 33. Testing Strategy

Frontend tests should target behavior at the correct layer.

---

## 33.1 Cubit/BLoC Tests

Validate:

- initial state
- loading
- success
- failure
- retry
- refresh
- stale-response handling
- action-specific transitions
- state preservation

Use `bloc_test` where helpful.

---

## 33.2 Repository Tests

Validate:

- endpoint paths
- request payloads
- query parameters
- response parsing
- mapping
- platform-specific behavior
- error mapping

Use transport mocks instead of live backend/provider dependencies.

---

## 33.3 DTO Tests

Validate:

- valid parsing
- optional values
- malformed data
- enum mapping
- naming conversion

---

## 33.4 Widget Tests

Validate user-visible behavior such as:

- Loading
- Empty
- Error
- Retry
- Success
- actions
- navigation
- Administrator visibility
- responsive variants
- semantics where relevant

Tests should avoid depending on implementation details that are not part of the user-visible contract.

---

# 34. Static Analysis

Run:

```bash
flutter analyze
```

The project uses `flutter_lints` plus additional lint rules.

New code should keep analyzer output clean.

---

# 35. Formatting

Run:

```bash
dart format .
```

Typical quality loop:

```bash
dart format .
flutter analyze
flutter test
```

Focused tests should normally come before the full suite while implementing a change.

---

# 36. Dependency Direction Rules

The intended dependency direction is:

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

Rules:

- presentation may depend on application/domain
- application may depend on domain contracts
- data implements domain contracts
- domain should not import presentation/data transport implementation
- widgets should not call Dio directly
- DTOs should not become UI models
- `ApiClient` should remain below repositories

---

# 37. When to Create a Cubit

Create a Cubit when a feature has meaningful application state such as:

- loading
- retry
- save/action state
- refresh
- independent failure state
- interaction with a repository

Do not create a Cubit merely to store one local boolean that belongs to a widget.

---

# 38. When to Create a Repository

Create a repository contract when the feature needs an external/data source behind a stable domain-facing abstraction.

Examples:

- backend API
- local persisted configuration
- authentication storage
- cached remote data

Do not add repository abstractions to static presentation-only content.

---

# 39. When to Split Widgets

Split a widget when doing so improves one or more of:

- readability
- responsibility
- reusability
- independent testing
- responsive adaptation

Avoid splitting every few lines solely to reduce file length.

---

# 40. Platform-Specific Code

Platform differences should be explicit and justified.

Good reasons include:

- Web session cookies
- mobile refresh credentials
- server setup
- navigation model
- safe areas
- keyboard behavior
- modal/sheet presentation

Avoid separate Web and mobile feature implementations when only layout differs.

---

# 41. Accessibility

Accessibility is part of the final quality roadmap.

Frontend architecture should make it possible to add and maintain:

- semantics
- labels
- keyboard interaction
- focus behavior
- sufficient hit targets
- responsive text handling

Accessibility should be validated systematically before stable release rather than treated only as isolated fixes.

---

# 42. Performance

Performance work should be evidence-driven.

Potential review areas include:

- unnecessary rebuilds
- excessive provider/API requests
- image rendering/cache behavior
- large list performance
- state scope
- desktop overdraw
- Search/cache effectiveness

Avoid introducing complex optimization layers without measured need.

---

# 43. Architectural Anti-Patterns to Avoid

Avoid:

- API calls directly inside widgets
- raw JSON parsing in presentation
- Dio exceptions leaking into UI
- giant global Cubit provider trees
- duplicated Web/mobile business logic
- one massive page Cubit controlling unrelated subsections
- design values scattered as magic numbers
- Search logic duplicated inside Explore
- frontend-only recreation of backend business rules
- loading admin-only data for non-admin users
- persistent secrets in frontend source code
- abstractions added solely for theoretical future flexibility

---

# 44. Future Architectural Work

Known future areas include:

- full localization architecture
- additional provider-driven UI
- external ratings presentation
- complete Administrator user-management UI
- coordinated Shows refresh
- deeper accessibility validation
- final responsive/ultrawide audit
- performance audit
- release configuration
- production Web/mobile build guidance

These should be introduced incrementally and only when the product requirement is clear.

---

## Related Documentation

- [Architecture Overview](overview.md)
- [Backend Architecture](backend.md)
- [Implementation Status](../features/implementation-status.md)
- [Frontend README](../../frontend/README.md)
- [Backend README](../../backend/README.md)
- [Development Setup](../development/setup.md)
- [Testing](../development/testing.md)
