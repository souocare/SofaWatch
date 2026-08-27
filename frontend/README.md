# SofaWatch Frontend

The SofaWatch frontend is a Flutter application targeting Web, iOS, and Android.

It provides the user interface for the SofaWatch self-hosted backend while keeping presentation, application state, domain models, and data access separated through a Feature First architecture.

> [!NOTE]
> SofaWatch is under active development. UI structure, navigation, APIs, and responsive behavior may continue to evolve before the first stable release.

## Tech Stack

- Flutter
- Dart 3.12+
- Material
- go_router
- flutter_bloc
- bloc
- Dio
- shared_preferences
- google_fonts
- equatable
- flutter_test
- bloc_test
- http_mock_adapter
- flutter_lints

The application currently uses a dark theme across supported platforms.

---

## Architecture

The frontend follows a Feature First structure with a lightweight Clean Architecture approach.

```text
Presentation
     |
     v
Application
     |
     v
Domain
     |
     v
Data
     |
     v
Backend API
```

The main responsibilities are:

- **presentation** — pages, views, widgets, dialogs, sheets, responsive layouts, and user interaction.
- **application** — Cubits, BLoCs, states, orchestration, and UI-facing workflows.
- **domain** — entities, value objects, repository contracts, and domain-facing abstractions.
- **data** — DTOs, mappers, API repository implementations, local storage implementations, and provider-facing data handling.

The domain layer should not depend on Flutter widgets, Dio, or raw JSON.

Where possible, Web and mobile share the same domain and application layers and vary only in presentation.

---

## Project Structure

At a high level:

```text
frontend/
├── lib/
│   ├── app/
│   │   ├── router/
│   │   ├── theme/
│   │   ├── app.dart
│   │   ├── app_dependencies.dart
│   │   └── bootstrap.dart
│   │
│   ├── core/
│   │   ├── api/
│   │   ├── errors/
│   │   ├── logging/
│   │   ├── server/
│   │   ├── storage/
│   │   └── widgets/
│   │
│   ├── features/
│   │   └── <feature>/
│   │       ├── presentation/
│   │       ├── application/
│   │       ├── domain/
│   │       └── data/
│   │
│   └── main.dart
│
├── test/
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

Not every feature needs every layer if a layer would add no value, but feature boundaries should remain clear.

---

## Feature First Organization

Features are organized around product capabilities rather than technical file types.

Examples include areas such as:

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

A typical feature may look like:

```text
features/show_details/
├── presentation/
│   ├── pages/
│   └── widgets/
├── application/
│   └── cubit/
├── domain/
│   ├── models/
│   └── repositories/
└── data/
    ├── models/
    └── repositories/
```

This keeps feature-specific code together and prevents the application from turning into large global `widgets/`, `models/`, or `services/` folders.

---

## Application Bootstrap

The Flutter entry point is intentionally small:

```text
main.dart
    |
    v
bootstrap(...)
    |
    v
SofaWatchApp
```

Application bootstrap is responsible for initializing cross-cutting infrastructure before `runApp`.

Current bootstrap responsibilities include:

- Flutter binding initialization
- path-based Web URL strategy
- BLoC observer registration
- local key/value storage
- stored server configuration
- backend URL configuration
- `ApiClient`
- server connection testing
- Search repository and in-memory Search cache
- application dependency setup

Runtime Google Fonts fetching is disabled so typography does not depend on downloading fonts while the app is running.

---

## Dependencies

Cross-application dependencies are provided above the router using repository providers.

Core dependencies include:

- `ApiClient`
- `ServerConfigurationRepository`
- `ServerConnectionTester`

Feature-specific repositories and Cubits/BLoCs should normally be created closer to the feature that owns them rather than placing every dependency globally.

This keeps dependency lifetime and ownership explicit.

---

## Backend Connection

The Flutter application communicates with the SofaWatch backend through `ApiClient`, which wraps Dio.

The client automatically appends:

```text
/api/v1
```

to the configured server URL.

For example:

```text
http://127.0.0.1:8000
```

becomes:

```text
http://127.0.0.1:8000/api/v1
```

Default request headers include JSON `Accept` and `Content-Type` values.

Current API timeout values are:

```text
Connect: 10 seconds
Send:    15 seconds
Receive: 30 seconds
```

Dio failures are mapped into application exceptions instead of being exposed directly throughout presentation code.

---

## Server Configuration

The frontend supports persisted server configuration.

On startup, SofaWatch first attempts to load a previously stored server URL.

A compile-time server URL can also be supplied using:

```text
SOFAWATCH_SERVER_URL
```

through `--dart-define`.

The stored server configuration takes precedence when one exists.

### Web

For local Web development:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

### iOS Simulator

```bash
flutter run -d "<iPhone Simulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

### Android Emulator

Android Emulator uses `10.0.2.2` to access the host machine:

```bash
flutter run -d "<Android Emulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://10.0.2.2:8000
```

### Physical Devices

A physical iOS or Android device cannot use `127.0.0.1` to access the backend running on the development computer.

Run the backend on:

```text
0.0.0.0:8000
```

and use the computer's LAN IP:

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://<LAN-IP>:8000
```

The device and development machine must be able to communicate over the local network.

---

## Native Server Setup

Native clients support a Server Setup experience when no backend URL has been configured.

The router checks whether the `ApiClient` has a server URL configured.

On non-Web platforms:

```text
No server configured
        |
        v
/server-setup
        |
        v
connection test
        |
        v
persist server configuration
        |
        v
main application
```

Once configuration exists, navigating back to the setup route redirects to Home.

Web uses the configured Web/backend URL flow rather than this native redirect behavior.

---

## Navigation

Navigation is implemented with `go_router`.

The application uses:

```text
StatefulShellRoute.indexedStack
```

for the five primary application areas:

```text
Home
Shows
Movies
Explore
Profile
```

Each branch has its own `NavigatorState`.

This allows branch state and navigation context to remain available when switching between main sections.

### Main Shell

`AppShell` selects a platform-specific shell:

```text
AppShell
   |
   +-- Web App Shell
   |
   +-- Mobile App Shell
```

Web and mobile share the same navigation branches while presenting them differently.

### Root Navigation

Global destinations such as Search and media details are placed on the root navigator rather than inside a single tab branch where appropriate.

This prevents details or modal experiences from being unnecessarily tied to one navigation branch.

### Details

Show and Movie Details are routed through a common modal/page strategy.

The router can create the required feature Cubits close to the route that owns their lifetime.

This keeps details state isolated from unrelated screens.

---

## Web Navigation

Web uses a top navigation layout.

Primary navigation includes:

- Home
- Shows
- Movies
- Explore
- Profile

Global actions are exposed separately from the main navigation.

Search opens as a desktop modal-style route when the viewport is wide enough.

The Web layout aims to preserve content density and avoid stretching application content unnecessarily on large displays.

---

## Mobile Navigation

Mobile uses a custom bottom navigation experience.

Search is integrated into the mobile shell rather than being implemented as a second independent Search feature.

The current mobile shell contains the Dual-Pill Search/navigation experience.

Search temporarily overlays the active branch while preserving the originating navigation branch.

When Search closes, the application restores the original branch context.

The shell also adapts its dimensions and spacing for narrow and landscape layouts.

---

## Search Navigation Strategy

Search is a global feature.

There is one Search domain/application implementation shared by Web and mobile.

### Web / Larger Layouts

Search is opened from the global Web navigation and presented as a modal-style experience.

### Mobile

Search is integrated directly into the Dual-Pill navigation experience.

The mobile shell creates a `SearchBloc` for the active Search experience and owns its lifecycle until Search closes.

This avoids duplicating Search business logic inside Explore or another feature.

---

## State Management

SofaWatch uses `flutter_bloc`.

Depending on feature complexity, state is managed through:

- `Cubit`
- `Bloc`

### Cubits

Cubits are preferred where state transitions map cleanly to explicit application actions such as:

```text
load
retry
refresh
mark watched
remove
save
```

Typical state flow:

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

More complex features may preserve existing data during refresh or expose independent state per subsection.

### BLoCs

BLoC is used where event-driven coordination is useful.

Global Search uses `SearchBloc`, where behavior includes query changes, debounce, pagination, stale-response protection, retries, and filter updates.

### Scope

State objects should be scoped as close as practical to the part of the widget tree that owns them.

Avoid globally providing feature Cubits simply because they are convenient to access.

### Independent Failure Boundaries

Large pages such as Profile are composed from independent feature states.

A failure in one section should not unnecessarily break unrelated sections.

---

## Authentication

The frontend supports the backend's Web and native authentication models through a shared domain contract.

### Shared Auth State

`AuthCubit` manages high-level authentication state including:

- restoring an existing session
- authenticated state
- unauthenticated state
- authentication failure
- logout
- logout everywhere

The domain contract remains platform-independent.

### Web Authentication

Web login uses the standard authentication endpoint and persistent HttpOnly session cookie managed by the backend/browser.

Session restore uses the Web session endpoint.

The persistent Web credential is not stored in Flutter-accessible client storage.

A short-lived access token returned by the backend may still be used for authenticated API requests.

### Mobile Authentication

Native login uses the mobile authentication endpoint.

Mobile stores:

- the current short-lived access token
- the current rotating refresh credential

Session restoration uses the refresh credential.

When refresh succeeds, the new refresh credential replaces the old one.

### Logout

Logout behavior is platform-aware.

Web revokes the Web session.

Mobile revokes its persistent mobile session and clears local authentication credentials.

`Log out everywhere` revokes all user sessions and clears local credentials on the current device.

### Security

Authentication failures are represented through application-level exceptions.

Presentation code should not depend on Dio-specific failures or authentication transport details.

---

## Repositories

Feature domain layers define repository contracts.

Data layers provide concrete implementations.

For example:

```text
Domain
  SearchRepository
        ^
        |
Data
  ApiSearchRepository
```

Repositories may also be decorated when useful.

Search currently uses:

```text
SearchRepository
      ^
      |
CachedSearchRepository
      |
      +-- ApiSearchRepository
      |
      +-- InMemorySearchCache
```

This keeps caching outside the Search domain and avoids coupling UI state to transport details.

---

## DTOs and Mapping

Raw API responses belong in the data layer.

A typical flow is:

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
 |
 v
Application / Presentation
```

Domain objects should not expose raw JSON parsing responsibilities.

Provider/backend API response changes should normally be absorbed by DTO/mapping code rather than spread across widgets.

---

## Design System

SofaWatch uses centralized design tokens.

The main token exports are:

```text
AppBreakpoints
AppColors
AppDurations
AppRadius
AppSpacing
AppTypography
```

They are exported together through:

```text
app/theme/tokens/app_design_tokens.dart
```

### Colors

`AppColors` defines semantic application colors for areas including:

- brand
- backgrounds and surfaces
- text
- borders and dividers
- status states
- progress
- ratings
- overlays
- inverse content

Widgets should prefer semantic tokens instead of introducing arbitrary colors.

### Typography

Typography is centralized through `AppTypography`.

The current typeface is Manrope via `google_fonts`.

Typography tokens cover:

- headlines
- titles
- body text
- labels
- overlines
- mobile-specific sizing where needed

Runtime font fetching is disabled.

### Spacing

Reusable spacing values live in `AppSpacing`.

Layouts should use existing spacing tokens rather than accumulating unrelated magic numbers.

Platform/layout-specific constants can still exist when they represent a real component constraint rather than a general design token.

### Radius

Reusable border radius values live in `AppRadius`.

### Durations

Animation timing and shared animation curves live in `AppDurations`.

### Breakpoints

Shared responsive thresholds live in `AppBreakpoints`.

Presentation code should prefer shared breakpoints for application-wide responsive decisions.

---

## Theme

The application currently runs in dark mode:

```text
ThemeMode.dark
```

The central Flutter theme is exposed through:

```text
AppTheme.dark
```

Material theme configuration and custom SofaWatch design tokens should remain aligned so native Material components and custom widgets feel like part of the same UI.

---

## Responsive Strategy

SofaWatch targets both mobile and desktop/Web experiences from the same Flutter codebase.

The responsive strategy is not simply to scale one mobile layout to larger widths.

Instead:

```text
Shared domain/application logic
            |
            v
Responsive / adaptive presentation
       /                 \
      v                   v
 Mobile UI             Web/Desktop UI
```

### General Rules

- share business logic whenever possible
- adapt presentation when interaction models differ
- use `LayoutBuilder` and `MediaQuery` where the component owns the layout decision
- use `AppBreakpoints` for shared application breakpoints
- avoid extremely wide content on desktop
- preserve sensible density on large displays
- support small mobile widths
- consider portrait and landscape behavior
- avoid hardcoded pixel values where design tokens or layout constraints are more appropriate

### Modal vs Page/Sheet Behavior

Some experiences change presentation based on available width.

Search, for example, becomes a modal-style route at larger widths and a dedicated/mobile experience at smaller widths.

Media details similarly use responsive modal/page behavior.

The domain and application state should remain the same regardless of how the feature is presented.

---

## Widget Design

Preferred widget practices include:

- prefer `StatelessWidget` when there is no real local mutable state
- use private widgets to break large presentation files into meaningful components
- use `const` wherever practical
- use `ValueKey` where it improves state stability or testing
- avoid giant `build` methods
- avoid duplicating feature logic across Web and mobile
- keep business logic out of widgets
- keep API calls out of presentation widgets
- use design tokens consistently
- make loading, empty, error, and retry states explicit

Local `StatefulWidget` usage is appropriate for presentation-only concerns such as animation controllers, focus nodes, scroll controllers, or ephemeral interaction state.

---

## Error Handling

Network and data failures are mapped into application exceptions below the presentation layer.

UI should present safe, user-facing error messages rather than raw transport errors.

Features generally distinguish states such as:

```text
Initial
Loading
Success
Empty
Failure
Retrying
Pagination Loading
Pagination Failure
```

where appropriate.

A feature should preserve usable existing data during refresh when that produces a better experience.

---

## Local Persistence

`shared_preferences` is used behind application abstractions for small local configuration/state needs.

For example, server configuration is accessed through a repository rather than calling SharedPreferences directly from UI code.

Presentation and domain layers should not depend directly on storage implementation details.

---

## Search Cache

Search uses a bounded in-memory cache.

The cache is intentionally:

- non-persistent
- TTL-based
- LRU-bounded
- limited in size

It is a data-layer optimization and should not become part of Search business rules.

---

## Running the Frontend

Install Flutter dependencies:

```bash
flutter pub get
```

Check available devices:

```bash
flutter devices
```

### Web

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

### iOS Simulator

```bash
flutter run -d "<iPhone Simulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

### Android Emulator

```bash
flutter run -d "<Android Emulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://10.0.2.2:8000
```

### Physical Device

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://<LAN-IP>:8000
```

---

## Testing

The frontend uses Flutter's test framework together with `bloc_test` and `http_mock_adapter`.

Run the complete suite:

```bash
flutter test
```

Run a focused test file:

```bash
flutter test test/path/to/test_file.dart
```

Testing should cover behavior at the appropriate layer.

### Application Tests

Cubit/BLoC tests should validate:

- initial state
- loading
- success
- failure
- retry
- state preservation where required
- concurrent/stale request behavior where applicable
- action-specific transitions

### Data Tests

Repository and DTO tests should validate:

- request paths
- request payloads
- query parameters
- DTO parsing
- mapping
- malformed responses
- error mapping
- platform-specific auth behavior where relevant

### Widget Tests

Widget tests should validate user-visible behavior such as:

- loading states
- successful rendering
- empty states
- errors
- retry
- buttons/actions
- navigation
- responsive variants
- admin-only visibility
- accessibility/semantics where relevant

Tests should verify behavior rather than depend unnecessarily on implementation details.

---

## Static Analysis

Run the Dart/Flutter analyzer with:

```bash
flutter analyze
```

The project uses `flutter_lints` plus additional rules including:

- `always_declare_return_types`
- `avoid_dynamic_calls`
- `directives_ordering`
- `prefer_single_quotes`
- `sort_constructors_first`
- `sort_unnamed_constructors_first`
- `use_build_context_synchronously`

Generated `*.g.dart` and `*.freezed.dart` files are excluded from analyzer checks.

New code should keep the analyzer clean.

---

## Formatting

Use Dart formatting:

```bash
dart format .
```

Before committing a frontend change, the normal quality loop is:

```bash
dart format .
flutter analyze
flutter test
```

Focused tests should normally be run before the full suite while implementing a change.

---

## Development Workflow

The preferred workflow for frontend changes is:

1. Inspect the current feature implementation.
2. Identify which layer owns the change.
3. Make the smallest coherent change.
4. Add or update focused tests.
5. Run focused tests.
6. Run `flutter analyze`.
7. Run the relevant full frontend test suite.
8. Fix regressions before continuing.

Tests should not be weakened merely to make a regression green.

If an existing behavior has changed intentionally, both implementation and tests should reflect the new product decision.

---

## Development Principles

Frontend development follows the broader SofaWatch engineering principles:

- Clean Architecture
- SOLID
- DRY
- KISS
- Feature First organization
- explicit dependency direction
- backend as the source of truth
- thin presentation logic
- provider-independent domain models
- reusable domain/application layers across platforms
- responsive and adaptive presentation
- explicit loading/error/empty states
- incremental changes
- automated regression testing
- no unnecessary abstractions
- no premature optimization

---

## Adding a Feature

A new feature should normally start from the product responsibility rather than from a technical folder.

For example:

```text
features/example/
├── presentation/
├── application/
├── domain/
└── data/
```

A typical dependency direction is:

```text
Page / Widget
     |
     v
Cubit / Bloc
     |
     v
Repository Contract
     ^
     |
API Repository
     |
     v
ApiClient
```

Only add layers that solve a real responsibility.

Very small presentation-only functionality does not need artificial repository/domain abstractions.

---

## Platform-Specific Code

Platform differences should be isolated where possible.

Use platform-specific behavior when it represents a real UX or platform constraint, such as:

- Web navigation vs mobile navigation
- Web HttpOnly authentication sessions
- Mobile refresh credentials
- server configuration setup
- desktop modal vs mobile page/sheet
- keyboard/focus behavior
- safe areas
- narrow/landscape layouts

Avoid forking entire features into unrelated Web and mobile implementations when only presentation differs.

---

## Documentation

More detailed technical documentation lives under [`../docs`](../docs/).

Frontend-specific documentation can continue to be added there for areas such as:

- architecture
- navigation
- responsive behavior
- authentication
- testing
- design system
- feature implementation notes

---

## Related Documentation

- [Main SofaWatch README](../README.md)
- [Backend README](../backend/README.md)
- [Technical Documentation](../docs/README.md)
