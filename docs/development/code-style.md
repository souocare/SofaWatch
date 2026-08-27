# Code Style

This document defines the coding conventions for SofaWatch.

It is intentionally prescriptive. Its purpose is to keep the codebase predictable, readable, testable, and easy to maintain as the project grows.

> **Rule of thumb:** prefer clear, boring, explicit code over clever code.

The conventions here apply to new code and to code being substantially modified. Do not create large unrelated refactors merely to make old code conform to a style rule.

---

# 1. Core principles

SofaWatch follows these general engineering principles:

- **Clean Architecture** — dependencies should point toward stable domain/application concepts.
- **SOLID** — especially single responsibility and dependency inversion.
- **DRY** — avoid meaningful duplication, but do not create abstractions prematurely.
- **KISS** — choose the simplest design that correctly solves the problem.
- **Explicit over implicit** — important behavior should be visible from the code.
- **Backend as source of truth** — business rules and persisted state belong in the backend rather than being independently reinvented by clients.
- **Feature-first frontend organization** — Flutter code is grouped around product features.
- **Small, focused units** — functions, classes, widgets, services, repositories, and Cubits should have clear responsibilities.
- **Test behavior, not implementation details**.
- **No technical details leaked to users** — internal failures are logged; UI/API-facing errors remain safe and understandable.

A style rule must never be used as justification for making the design worse.

---

# 2. Repository-level conventions

## 2.1 Keep responsibilities separated

Backend responsibilities should normally follow this direction:

```text
API route
   │
   ▼
Service / application logic
   │
   ▼
Repository
   │
   ▼
SQLAlchemy model / database
```

External providers are separate dependencies:

```text
Service
   │
   ├────────► Repository ────────► Database
   │
   └────────► Provider client ───► TMDB / future TVDB / other provider
```

Routes should not become business-logic containers.

Repositories should not become application services.

Provider clients should not know about HTTP routes or Flutter concerns.

Frontend responsibilities should normally follow:

```text
Presentation
    │
    ▼
Cubit / application state
    │
    ▼
Domain repository contract
    │
    ▼
Data repository implementation
    │
    ├────► DTO parsing
    └────► ApiClient
```

---

## 2.2 Prefer existing patterns

Before introducing:

- a new base class;
- a new result wrapper;
- a new exception hierarchy;
- a new repository pattern;
- a new state-management mechanism;
- a new UI primitive;

first check whether SofaWatch already has an established equivalent.

Consistency across the project is normally more valuable than a locally “perfect” abstraction.

---

# 3. Python

## 3.1 Supported syntax

Use modern Python syntax supported by the project.

Prefer built-in generic types:

```python
items: list[Show]
mapping: dict[str, int]
show_ids: set[UUID]
```

Do not use legacy typing aliases unnecessarily:

```python
# Avoid
from typing import Dict, List

items: List[Show]
mapping: Dict[str, int]
```

Use PEP 604 unions:

```python
def find_show(show_id: UUID) -> Show | None:
    ...
```

rather than:

```python
from typing import Optional

def find_show(show_id: UUID) -> Optional[Show]:
    ...
```

For generic classes, use the modern type-parameter syntax when supported by the configured Python/Ruff target:

```python
class PaginatedResponse[T](BaseModel):
    items: list[T]
```

---

# 4. Python formatting and Ruff

Ruff is the canonical Python linter and formatter for SofaWatch.

Do not manually fight the formatter.

The required quality gates are:

```bash
ruff check .
ruff format --check .
```

To apply safe automatic lint fixes:

```bash
ruff check . --fix
```

To format:

```bash
ruff format .
```

Do **not** routinely use:

```bash
ruff check . --unsafe-fixes
```

Unsafe fixes require deliberate review because they may change behavior.

After broad automated fixes, always run the test suite.

---

## 4.1 Imports

Imports belong at module level unless there is a concrete technical reason for a local import.

Ruff determines canonical ordering.

Typical grouping:

```python
from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user import UserRepository
from app.services.user import UserService
```

Do not manually maintain duplicate imports.

Bad:

```python
from app.repositories.movie import MovieRepository
from app.repositories.show import ShowRepository
from app.repositories.movie import MovieRepository
```

Good:

```python
from app.repositories.movie import MovieRepository
from app.repositories.show import ShowRepository
```

Unused imports must be removed.

Do not add imports in the middle of a test module because new tests were appended there. Merge them into the import block at the top.

---

## 4.2 Line length

Respect the Ruff configuration.

Prefer formatting expressions structurally rather than disabling `E501`.

Good:

```python
result = repository.get_daily_statistics_for_period(
    user_id=user_id,
    start_at=start_at,
    end_at=end_at,
)
```

Avoid arbitrary `# noqa: E501` comments merely to preserve a long line.

---

# 5. Naming

## 5.1 Python

Use:

- `snake_case` for functions, methods, variables, modules;
- `PascalCase` for classes and enums;
- `UPPER_SNAKE_CASE` for true constants.

Examples:

```python
class EpisodeProgressService:
    ...

def get_show_progress(...):
    ...

DEFAULT_PAGE_SIZE = 20
```

Names should describe domain meaning.

Prefer:

```python
watched_episode_count
```

over:

```python
count
```

when the broader context does not already make the meaning obvious.

---

## 5.2 Boolean names

Boolean values should read naturally as predicates.

Good:

```python
is_admin
is_watched
has_next
caught_up
configured
```

Avoid ambiguous names such as:

```python
admin
watch
next
config
```

when the value is specifically boolean.

---

## 5.3 Identifiers

Include the entity in identifier names where ambiguity is possible:

```python
user_id
show_id
season_id
episode_id
movie_id
tmdb_id
```

Do not use generic `id` variables across code that handles several entities simultaneously.

---

# 6. Type hints

Backend application code should be typed.

Public service and repository methods should declare argument and return types.

Good:

```python
def get_by_id(self, show_id: UUID) -> Show | None:
    ...
```

Avoid:

```python
def get_by_id(self, show_id):
    ...
```

Use concrete domain types where practical.

Do not use `Any` simply to avoid understanding the type.

`Any` is acceptable at genuine untyped boundaries, for example when decoding arbitrary external/provider payloads before validation.

---

# 7. Dataclasses, Pydantic models, and SQLAlchemy models

These structures have different responsibilities and should not be treated interchangeably.

```text
SQLAlchemy model
    persisted database representation

Pydantic schema / DTO
    validated boundary representation

Dataclass / domain structure
    internal typed value where appropriate
```

Do not return arbitrary SQLAlchemy objects from public APIs merely because serialization happens to work.

---

# 8. Pydantic schemas

Schemas should describe API contracts clearly.

Use constraints where the contract has meaningful constraints:

```python
class PaginationRequest(BaseModel):
    offset: int = Field(ge=0)
    limit: int = Field(gt=0)
```

Prefer explicit response schemas over raw dictionaries.

Good:

```python
class ServerDatabaseHealthResponse(BaseModel):
    status: ServerComponentStatus
    latency_ms: float | None
```

Avoid:

```python
return {
    "status": "healthy",
    "latency": latency,
}
```

when this is part of a stable API contract.

Validation belongs at the boundary when it describes the shape or basic validity of incoming data.

Business policy belongs in services.

---

# 9. SQLAlchemy models

SQLAlchemy models represent persistence.

Keep model declarations declarative and predictable.

Relationships should describe persistence relationships, not application workflows.

Do not put provider calls, HTTP behavior, or complex application orchestration inside SQLAlchemy models.

Use explicit database constraints for invariants that the database can and should protect.

For example, the polymorphic Library model should not rely solely on application code to ensure that an entry targets exactly one media type.

Database constraints and service validation can complement each other.

---

# 10. Repositories

Repositories encapsulate persistence queries and persistence operations.

A repository may:

- retrieve entities;
- list/filter entities;
- count records;
- persist entities;
- delete entities;
- perform database-oriented aggregate queries.

A repository should generally not:

- construct HTTP responses;
- decide UI messages;
- call FastAPI dependencies;
- orchestrate several unrelated business workflows;
- call Flutter;
- contain TMDB-specific HTTP transport logic.

Example:

```python
class UserRepository:
    def get_by_id(
        self,
        user_id: UUID,
    ) -> User | None:
        ...
```

Use domain-specific repository method names.

Good:

```python
get_next_unwatched_for_show(...)
count_watched_aired_for_show(...)
list_by_season_id(...)
```

Less useful:

```python
query(...)
do_lookup(...)
get_data(...)
```

---

# 11. Services

Services own application/business behavior.

Examples include:

- importing a show;
- synchronizing metadata;
- marking an episode watched;
- calculating progress;
- determining Watch Next;
- registration;
- authentication;
- password recovery;
- server health;
- statistics aggregation.

A service should receive dependencies rather than create global infrastructure internally whenever practical.

Good:

```python
class RegistrationService:
    def __init__(
        self,
        user_repository: UserRepository,
        authentication_settings_repository: AuthenticationSettingsRepository,
    ) -> None:
        self._user_repository = user_repository
        self._authentication_settings_repository = (
            authentication_settings_repository
        )
```

This improves testability and makes dependencies explicit.

---

## 11.1 Avoid duplicate business rules

If “is this episode watchable?” is a backend rule, do not implement subtly different versions in:

- route A;
- service B;
- Flutter screen C.

Centralize the authoritative rule.

The frontend may mirror a rule for UX, but the backend must still enforce it.

---

# 12. FastAPI routes

Routes are transport adapters.

They should normally:

1. receive and validate HTTP input;
2. resolve dependencies;
3. call an application service;
4. map expected application outcomes to API responses/errors;
5. return a typed response.

Keep them thin.

Good conceptual shape:

```python
@router.get("/{show_id}", response_model=ShowResponse)
def get_show(
    show_id: UUID,
    service: ShowServiceDependency,
) -> ShowResponse:
    show = service.get_show(show_id)

    if show is None:
        raise APIError(...)

    return ShowResponse.model_validate(show)
```

Avoid embedding a large SQLAlchemy query or provider workflow directly inside the route.

---

# 13. FastAPI dependencies

Dependency functions wire infrastructure together.

They are not a second service layer.

Use dependencies for things such as:

- database sessions;
- current user;
- administrator authorization;
- repositories;
- services;
- configured provider clients.

Authorization must be enforced server-side.

For admin-only endpoints, UI visibility is not sufficient. The route must independently require the appropriate admin dependency.

---

# 14. Exceptions and API errors

Expected domain/application failures should be represented explicitly.

Do not expose provider exceptions, stack traces, SQL messages, tokens, credentials, or internal implementation details to clients.

Conceptually:

```text
low-level exception
       │
       ▼
service/domain interpretation
       │
       ▼
safe API error
       │
       ▼
safe frontend message
```

Use existing project exception/error infrastructure instead of returning ad-hoc error dictionaries.

Do not write:

```python
except Exception:
    return {"error": "something failed"}
```

unless this is part of a deliberate boundary with correct logging and error handling.

Avoid broad exception swallowing.

---

# 15. Logging

Use Python `logging`.

```python
import logging

logger = logging.getLogger(__name__)
```

Log technical details useful for diagnosis, but never secrets.

Do not log:

- passwords;
- password hashes;
- access/session credentials;
- reset credentials;
- provider API tokens;
- authorization headers.

Prefer contextual logs:

```python
logger.warning(
    "TMDB metadata refresh failed for show_id=%s",
    show_id,
)
```

over vague messages:

```python
logger.warning("Error")
```

Use exception logging when a traceback is genuinely useful:

```python
logger.exception(
    "Unexpected metadata refresh failure for show_id=%s",
    show_id,
)
```

---

# 16. External providers

Provider-specific transport and schemas belong under the provider layer.

For TMDB:

```text
app/providers/tmdb/
├── client.py
├── schemas.py
└── exceptions.py
```

Do not spread raw TMDB response dictionaries through application code.

Parse and validate provider responses at the provider boundary.

Application services should work with validated provider structures.

Provider-specific failures should be mapped to meaningful internal outcomes.

This becomes especially important as SofaWatch adds other metadata sources such as TVDB.

---

# 17. Dates and time

Be explicit about timezone behavior.

Use timezone-aware timestamps for persisted events.

Prefer UTC internally:

```python
from datetime import UTC, datetime

now = datetime.now(UTC)
```

Do not mix naive and aware datetimes without a deliberate conversion boundary.

For domain concepts that are dates rather than moments in time, use `date`.

Examples:

- episode air date → `date`;
- watch event timestamp → timezone-aware `datetime`;
- server health checked-at → timezone-aware `datetime`.

---

# 18. Watch events and derived progress

Do not collapse event history and current/derived state into one concept.

A watch event records that viewing occurred.

```text
EpisodeWatchEvent
MovieWatchEvent
```

Progress summarizes the user's current state.

For rewatches, create another event rather than overwriting the original viewing event.

Conceptually:

```text
Episode
   │
   ├── WatchEvent #1 ── 2026-07-01
   ├── WatchEvent #2 ── 2026-08-10
   └── WatchEvent #3 ── 2026-08-27

Derived:
watch_count = 3
watched_at  = latest relevant timestamp
is_watched  = true
```

Code touching watch history must preserve this distinction.

---

# 19. Alembic migrations

Migrations describe database evolution.

They must be deterministic and reviewable.

Never casually edit an already-applied migration merely to make current model code look cleaner.

When schema behavior changes after a migration has become part of project history, normally create a new migration.

Migration workflow should include:

```bash
alembic upgrade head
```

and the backend tests.

Generated migrations must be reviewed. Autogeneration is a starting point, not proof that a migration is correct.

Pay particular attention to:

- foreign keys;
- cascade behavior;
- unique constraints;
- check constraints;
- indexes;
- nullable transitions;
- data backfills;
- SQLite batch operations.

Ruff formatting is allowed on migration Python code provided it does not alter migration semantics.

---

# 20. pytest

pytest is the backend test framework.

Tests should describe observable behavior.

Prefer descriptive names:

```python
def test_mark_watched_allows_episode_airing_today(...):
    ...
```

over:

```python
def test_episode_1(...):
    ...
```

A test name should communicate:

```text
operation + condition + expected outcome
```

Examples:

```python
test_get_show_progress_returns_none_when_show_does_not_exist
test_registration_rejects_request_when_open_registration_is_disabled
test_server_health_requires_administrator
```

---

## 20.1 Arrange / Act / Assert

Tests should generally be easy to read as:

```python
# Arrange
...

# Act
result = service.do_something(...)

# Assert
assert result...
```

Comments are optional when the structure is already obvious.

Do not mechanically add section comments to every tiny test.

---

## 20.2 Test isolation

Tests must not depend on execution order.

Do not rely on state created by another test.

Use fixtures and explicit setup.

Mock external boundaries when the test is not specifically testing the real integration.

---

## 20.3 Duplicate tests

Test function names must be unique within a module.

A duplicate function definition silently replaces the previous function at Python module load time, which means one intended test may never run.

Ruff `F811` protects against this.

When two tests have similar names, determine whether:

- one is an accidental duplicate;
- both test different behavior and need distinct names;
- one supersedes the other.

Do not blindly delete one solely to silence Ruff.

---

# 21. Backend quality gate

Before considering backend work complete, run:

```bash
ruff check .
ruff format --check .
pytest -q
```

Expected result:

```text
ruff check .
→ All checks passed!

ruff format --check .
→ all files already formatted

pytest -q
→ all tests passed
```

When making a focused change, targeted tests are useful during development, but the full suite should be run before the final validation of substantial work.

---

# 22. Dart and Flutter

Flutter code should prioritize:

- readability;
- immutable state;
- small widgets;
- clear feature boundaries;
- predictable Cubit behavior;
- responsive UI;
- reuse of SofaWatch design tokens.

Use Dart's standard formatter. Do not manually align code against `dart format`.

---

# 23. Flutter project organization

Prefer feature-first organization.

Typical feature:

```text
lib/features/profile/
├── application/
│   └── cubit/
├── data/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── pages/
    └── widgets/
```

The exact subfolders should reflect actual complexity. Do not create empty architectural layers merely for symmetry.

---

# 24. Flutter domain layer

Domain models should represent concepts the UI/application understands, not raw JSON.

Good:

```dart
class ServerHealth {
  const ServerHealth({
    required this.status,
    required this.checkedAt,
    required this.uptimeSeconds,
    required this.database,
    required this.tmdb,
  });

  final ServerHealthStatus status;
  final DateTime checkedAt;
  final int uptimeSeconds;
  final ServerDatabaseHealth database;
  final ServerTmdbHealth tmdb;
}
```

Do not pass `Map<String, dynamic>` throughout presentation code.

---

# 25. Flutter data layer

DTOs parse API representations.

Repository implementations translate data-layer structures into domain structures.

Conceptually:

```text
JSON
 │
 ▼
DTO
 │
 ▼
Domain model
 │
 ▼
Cubit/UI
```

Keep JSON field names at the data boundary.

For example, the backend may expose:

```json
{
  "is_admin": true
}
```

while Dart code uses:

```dart
isAdmin
```

The mapping belongs in DTO/repository code, not scattered through widgets.

---

# 26. Repository contracts in Flutter

Presentation/application code should depend on domain repository contracts rather than concrete API implementations.

Conceptually:

```dart
abstract interface class ServerRepository {
  Future<ServerHealth> getHealth();
}
```

Implementation:

```dart
final class ApiServerRepository implements ServerRepository {
  ...
}
```

This keeps Cubits testable and isolates HTTP concerns.

---

# 27. Cubits

Cubits coordinate application state and user-triggered operations.

They should not contain widget-building logic.

A simple async Cubit typically has states representing:

```text
Initial
  │
  ▼
Loading
  │
  ├────► Success
  │
  └────► Failure
```

State should be explicit enough that the UI does not need to infer important lifecycle information from unrelated fields.

---

## 27.1 Errors in Cubits

Use the project's application exception model.

Do not expose raw HTTP library exceptions directly to widgets.

The repository/data boundary should map technical failures into `AppException` or the project's appropriate error abstraction.

The UI then maps those errors to safe user-facing messages.

---

## 27.2 Retry

Retry behavior belongs in the Cubit/application flow rather than duplicating network calls inside widgets.

Good:

```dart
onPressed: context.read<ServerHealthCubit>().retry,
```

rather than manually reconstructing the API request in the button callback.

---

# 28. Lazy feature loading

Do not trigger requests for features the user cannot access.

For example, a non-admin user must not call the admin-only server-health endpoint.

Correct flow:

```text
Profile loaded
     │
     ▼
isAdmin?
  │       │
 no      yes
  │       │
hide    create/load
section ServerHealthCubit
```

Backend authorization remains mandatory even when the frontend prevents the request.

---

# 29. Flutter widgets

Prefer `StatelessWidget` unless local mutable widget state is genuinely required.

Extract private widgets when they:

- make the parent substantially easier to read;
- represent a meaningful UI unit;
- have reusable or independently testable behavior.

Example:

```dart
class _ServerHealthSection extends StatelessWidget {
  const _ServerHealthSection();

  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

Do not extract every `Padding` or `Text` into a class purely to reduce line count.

---

# 30. `const`

Use `const` wherever the expression is compile-time constant and doing so remains natural.

Good:

```dart
const SizedBox(height: AppSpacing.md)
```

Good:

```dart
const Icon(Icons.refresh)
```

This supports Flutter's immutable widget model and avoids unnecessary object recreation.

Do not distort APIs merely to chase additional `const` usage.

---

# 31. Widget keys

Use stable keys where widget identity matters, especially in:

- repeated rows;
- tests;
- stateful list items;
- actions that need precise test targeting.

Prefer descriptive keys:

```dart
ValueKey(
  'show-details-episode-watch-history-${episode.id}',
)
```

rather than:

```dart
const ValueKey('button1')
```

Keys form part of the testability contract. Avoid renaming established test keys casually.

---

# 32. Design tokens

Do not scatter arbitrary UI constants when a SofaWatch design token exists.

Prefer:

```dart
AppSpacing.md
AppRadius.lg
AppColors...
AppBreakpoints...
```

over:

```dart
const EdgeInsets.all(13)
BorderRadius.circular(11)
```

unless the value is genuinely unique to the component and has a clear design reason.

Using tokens keeps the visual language consistent and makes global design changes possible.

---

# 33. Responsive UI

Responsive behavior should use established breakpoints and patterns.

For interactions such as details/previews, SofaWatch generally prefers:

```text
width < 900
    → modal bottom sheet / mobile-oriented presentation

width >= 900
    → dialog / desktop-oriented presentation
```

Use the existing `AppBreakpoints` abstraction rather than scattering raw width checks.

Responsive does not mean merely shrinking desktop UI.

Consider:

- information hierarchy;
- available width;
- touch targets;
- scrolling;
- modal behavior;
- grid/list column counts.

---

# 34. UI state handling

Async UI should deliberately handle relevant states.

Depending on the feature:

```text
initial
loading
success
empty
failure
retrying
pagination loading
```

Do not accidentally render “no results” while the first request is still loading.

When refreshing/searching, decide explicitly whether previous data should remain visible.

For pagination, keep the existing list interactive and show progress at the end rather than replacing the entire screen with a loader.

---

# 35. User-facing errors

Users should receive useful, safe messages.

Do not display:

```text
SocketException...
SQLAlchemyError...
httpx.ConnectTimeout...
Traceback...
```

Map failures using the existing frontend error-message infrastructure.

A failure UI should usually answer:

- what broadly failed;
- whether retry is possible;
- what the user can do next.

Technical detail belongs in logs, not in the normal UI.

---

# 36. Flutter naming

Follow Dart conventions:

- `UpperCamelCase` for types;
- `lowerCamelCase` for variables, methods, fields;
- `snake_case.dart` for filenames;
- leading `_` for library-private members.

Examples:

```dart
class ProfileCubit extends Cubit<ProfileState> {}

final serverHealth = ...
Future<void> load() async {}
```

Files:

```text
server_health_cubit.dart
server_health_state.dart
api_server_repository.dart
profile_page.dart
```

---

# 37. Flutter state immutability

Cubit states and domain models should generally be immutable.

Prefer final fields and const constructors where possible.

Avoid mutating collections held by emitted states.

Create new state/data when state changes.

---

# 38. Build methods

Keep `build()` declarative.

Avoid performing network requests, repository mutations, or other uncontrolled side effects directly inside `build()`.

Bad:

```dart
@override
Widget build(BuildContext context) {
  repository.loadHealth();
  return ...
}
```

A build can run many times.

Trigger lifecycle/application actions through the appropriate Cubit/provider initialization or explicit user action.

---

# 39. Context access

Use the narrowest appropriate Bloc access mechanism.

Use `read` for one-time access/actions:

```dart
context.read<ProfileCubit>().load();
```

Use `BlocBuilder`, `BlocSelector`, or equivalent reactive mechanisms when the UI must rebuild in response to state.

Do not use broad state watching when only a small derived value is needed.

---

# 40. UI composition

Prefer semantic sections over enormous page widgets.

Conceptually:

```text
ProfilePage
  └── ProfileBody
      ├── StatisticsSection
      ├── LibrarySection
      ├── HistorySection
      └── ServerSection (admin only)
```

A page should communicate structure at a glance.

Private widgets are appropriate when they keep feature-specific implementation local.

---

# 41. Comments

Comments should explain **why**, constraints, or non-obvious behavior.

Good:

```python
# Today's episode is considered watchable because TMDB does not provide
# a reliable local air time for all episodes.
```

Less useful:

```python
# Get the show
show = repository.get_by_id(show_id)
```

Do not leave commented-out obsolete code in the repository.

Git already preserves history.

---

# 42. Docstrings

Use docstrings where they add useful contract/context, especially for:

- public services;
- non-obvious domain operations;
- complex helpers;
- tests where the scenario benefits from a short explanation.

Avoid docstrings that simply repeat the function name.

Good:

```python
def mark_watched(...):
    """Record a new watch event and update episode progress."""
```

Not useful:

```python
def get_user(...):
    """Get user."""
```

---

# 43. Functions and methods

Prefer small methods with one coherent responsibility.

Avoid boolean-flag APIs that substantially change a function's meaning.

Less clear:

```python
process_media(item, True, False, True)
```

Prefer named arguments or separate operations:

```python
process_media(
    item,
    refresh_metadata=True,
    update_library=False,
)
```

If the behaviors are fundamentally different, separate methods may be better.

---

# 44. Early returns

Use early returns when they reduce nesting.

Good:

```python
show = repository.get_by_id(show_id)

if show is None:
    return None

...
```

rather than:

```python
show = repository.get_by_id(show_id)

if show is not None:
    ...
    ...
    ...
    return result
else:
    return None
```

---

# 45. Collections and comprehensions

Use comprehensions when they remain immediately understandable.

Good:

```python
episodes_by_id = {
    episode.id: episode
    for episode in episodes
}
```

Do not compress complex business workflows into deeply nested comprehensions merely to save lines.

Readable loops are acceptable.

---

# 46. Avoid unused work

Do not calculate values that are not consumed.

Bad:

```python
statistics_by_day = {
    date.fromisoformat(row.day): row
    for row in rows
}

other_statistics_by_day = ...
# neither used
```

Unused assignments often indicate:

- an incomplete refactor;
- duplicate logic;
- stale code;
- a missing behavior.

Investigate rather than automatically prefixing variables with `_`.

---

# 47. Security-sensitive code

Security code should be especially explicit.

Never:

- log credentials;
- return password hashes;
- expose reset token hashes;
- trust frontend authorization;
- store plaintext passwords;
- compare password hashes manually when the security abstraction already exists;
- invent custom cryptography.

Use the project's password/session/token utilities.

Admin access must be checked on the backend.

Registration policy must be checked on the backend.

---

# 48. API compatibility

When changing an API field:

1. identify all backend producers;
2. identify schemas;
3. identify Flutter DTO parsing;
4. identify domain mapping;
5. identify Cubits/UI consumers;
6. update tests.

Think vertically through the stack:

```text
Database
   ↓
Model
   ↓
Repository
   ↓
Service
   ↓
Schema
   ↓
Route
   ↓
HTTP
   ↓
DTO
   ↓
Repository
   ↓
Domain
   ↓
Cubit
   ↓
UI
```

A feature is not complete merely because one layer compiles.

---

# 49. Backward compatibility and migrations

Do not assume local development data is disposable when designing migrations.

Prefer migration paths that preserve existing user data.

For self-hosted software, upgrades matter.

When a data backfill is necessary:

- make the transformation explicit;
- make assumptions clear;
- test representative existing data;
- avoid relying on current application code that may change later.

---

# 50. Performance

Optimize measured or structurally obvious problems, not hypothetical ones.

Good structural optimizations include:

- avoiding N+1 database access;
- using appropriate indexes;
- paginating large collections;
- caching expensive provider searches with deliberate TTL/invalidation behavior;
- not rebuilding large Flutter subtrees unnecessarily.

Do not sacrifice readability for micro-optimizations without evidence.

---

# 51. Search caching

Cache keys must include every input that changes the semantic result.

For example:

```text
query
+ filters
+ language
```

A cache that ignores language or filters can return valid-looking but incorrect results.

TTL, LRU limits, and expired-entry cleanup should remain explicit and tested.

Do not treat cache contents as authoritative persisted state.

---

# 52. Idempotency

Import/synchronization operations should be idempotent where appropriate.

Importing the same TMDB entity repeatedly should not create duplicate local entities.

Use provider identifiers and repository constraints deliberately.

Idempotency should be enforced at a robust layer, not only by a UI disabling a button.

---

# 53. Partial failures

Features that combine several independent data sources should define partial-failure behavior deliberately.

For example, a page with multiple sections should not necessarily become entirely unusable because one secondary section failed.

Prefer isolated state where that matches the product behavior.

Conceptually:

```text
Profile
 ├── profile data       ✓
 ├── statistics         ✓
 ├── library preview    ✗ → local retry/error
 └── history preview    ✓
```

Do not introduce global failure states unnecessarily.

---

# 54. Dependency injection

Constructor injection is preferred for services and repositories that have dependencies.

This:

```python
service = StatisticsService(
    episode_watch_event_repository=episode_repository,
    movie_watch_event_repository=movie_repository,
)
```

is easier to test than hidden construction inside the service.

FastAPI dependencies may construct the production dependency graph.

Flutter providers/repository injection should serve the same purpose.

---

# 55. Test doubles

Mock at meaningful boundaries.

For a service test, repository/provider mocks are usually appropriate.

For a repository test, use the test database rather than mocking SQLAlchemy internals.

For a Flutter Cubit test, mock the domain repository rather than the raw HTTP client.

For an API route test, override FastAPI dependencies where appropriate.

The closer the mock is to the unit's public dependency boundary, the less brittle the test tends to be.

---

# 56. Good refactoring discipline

When refactoring:

1. establish green tests;
2. make the smallest coherent change;
3. run focused tests;
4. run linters/formatters;
5. run the complete relevant suite;
6. inspect the diff.

Avoid mixing:

- behavior changes;
- huge formatting changes;
- renames;
- unrelated cleanup;

in one difficult-to-review change unless there is a strong reason.

A one-time repository-wide formatter adoption is an exception, but it should be deliberate and followed by the complete test suite.

---

# 57. Do not silence tooling casually

Avoid suppressions such as:

```python
# noqa
# type: ignore
```

or Dart analyzer ignores without understanding the warning.

A suppression is appropriate only when:

- the code is correct;
- the tool cannot reasonably infer that;
- restructuring would make the code worse;
- the suppression is as narrow as possible.

Prefer:

```python
# noqa: SPECIFIC_CODE
```

over disabling an entire category/file when possible.

---

# 58. Generated code

Do not manually style generated files unless they are intentionally committed and maintained as project source.

For Alembic-generated migrations, generated code becomes project history and should still pass the configured project quality gates after review/formatting.

For future generated Dart files, follow the generator's conventions and exclude them from manual rules if appropriate.

---

# 59. File size

There is no arbitrary maximum number of lines.

A large file is a signal to inspect responsibilities, not automatically a defect.

Split a file when doing so creates meaningful conceptual boundaries.

Do not split cohesive code into many tiny files solely to satisfy a line-count target.

---

# 60. API response naming

Backend JSON uses `snake_case`.

Example:

```json
{
  "display_name": "Gonçalo",
  "is_admin": true,
  "uptime_seconds": 12345
}
```

Dart uses `lowerCamelCase` internally:

```dart
displayName
isAdmin
uptimeSeconds
```

DTO mapping is the translation boundary.

---

# 61. Enums

Use enums for finite domain/API states instead of loosely validated strings.

Python example:

```python
from enum import StrEnum

class ServerHealthStatus(StrEnum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNAVAILABLE = "unavailable"
```

Dart should map these values explicitly and handle unknown provider/API values safely where forward compatibility matters.

Do not scatter string comparisons such as:

```python
if status == "healthy":
```

throughout application code when a domain enum already exists.

---

# 62. Pagination

Pagination contracts should be explicit.

A typical response contains:

```text
items
total
offset
limit
has_next
```

Do not infer `has_next` differently in multiple clients if the backend already provides the authoritative value.

Pagination loading should preserve existing results in the UI.

---

# 63. Nullability

Treat nullability as domain information, not an inconvenience.

If a field may genuinely be unavailable:

```python
latency_ms: float | None
```

or:

```dart
final double? latencyMs;
```

Do not invent fake sentinel values such as `-1` unless the API contract explicitly defines them.

Conversely, do not mark everything nullable “just in case.”

---

# 64. HTTP status codes

Use HTTP semantics consistently.

Examples:

- `200` successful retrieval/update;
- `201` successful creation when appropriate;
- `204` successful operation with no response body;
- `400` malformed/invalid operation when appropriate;
- `401` unauthenticated;
- `403` authenticated but not permitted;
- `404` resource not found;
- `409` conflict when applicable.

Use the project's established `APIError` conventions and stable error codes where available.

---

# 65. UI actions and double submission

Actions that create state, such as “Watched again,” should guard against accidental duplicate submission.

The loading state should be scoped appropriately.

For a per-row action:

```text
Row A → loading
Row B → remains usable
Row C → remains usable
```

Do not freeze an entire page when only one independent row operation is running unless required for consistency.

Backend correctness must not depend solely on frontend button disabling.

---

# 66. Accessibility and interaction

Interactive Flutter elements should:

- have reasonable touch targets;
- expose understandable labels/tooltips where icons are ambiguous;
- not rely solely on color to communicate critical state;
- preserve keyboard/desktop usability where applicable.

Use established Material widgets and semantics rather than recreating basic controls from raw gesture detectors without need.

---

# 67. Empty states

An empty state is not an error state.

Examples:

```text
No search query yet
No results for query
No watch history
No upcoming episodes
```

Each may require different copy and actions.

Do not display a generic error card for valid empty data.

---

# 68. Loading states

Choose loading behavior based on context.

Initial content load may use:

- skeletons;
- placeholders;
- progress indicators.

Refresh with existing data should generally preserve usable content and show subtler progress.

Pagination should append a loading indicator rather than replacing the list.

Consistency matters more than using one loader everywhere.

---

# 69. Source of truth

When deciding where logic belongs, ask:

> Which layer can enforce this correctly for every client?

Examples:

```text
Can a user mark a future episode watched?
→ backend business rule

Is a user an administrator?
→ backend identity/authorization source of truth

Should the Server section be visible?
→ frontend presentation based on backend-provided identity

How should a card be laid out at 700 px?
→ frontend presentation concern
```

---

# 70. Adding a new backend feature

Typical checklist:

```text
[ ] Determine domain behavior
[ ] Add/update model if persistence changes
[ ] Create Alembic migration if required
[ ] Add repository operations
[ ] Add service behavior
[ ] Add/update Pydantic schemas
[ ] Wire FastAPI dependency
[ ] Add route
[ ] Map errors safely
[ ] Add repository/service/API tests
[ ] ruff check .
[ ] ruff format --check .
[ ] pytest -q
```

Not every feature requires every layer.

Do not manufacture a repository or schema when the feature genuinely does not need one.

---

# 71. Adding a new Flutter feature

Typical checklist:

```text
[ ] Define/update domain model
[ ] Define repository contract
[ ] Add DTO if API data is involved
[ ] Implement API repository
[ ] Map API errors
[ ] Add Cubit/state
[ ] Build presentation
[ ] Handle loading/success/empty/failure
[ ] Add responsive behavior
[ ] Use design tokens
[ ] Add stable keys where useful
[ ] Add repository/Cubit/widget tests
[ ] dart format / flutter formatting
[ ] flutter analyze
[ ] flutter test
```

Again, use only the layers the feature needs.

---

# 72. Full-stack feature checklist

For a feature spanning backend and Flutter:

```text
BACKEND
  database/model
       ↓
  repository
       ↓
  service
       ↓
  schema
       ↓
  route
       ↓
     HTTP
       ↓
FRONTEND
  DTO
       ↓
  API repository
       ↓
  domain model
       ↓
  Cubit
       ↓
  widget/page
```

Verify the contract at every arrow.

---

# 73. Final quality checklist

Before considering a change complete, ask:

### Design

- Is the responsibility in the correct layer?
- Did I reuse an existing project pattern?
- Is the backend still the source of truth for business/security rules?
- Did I avoid unnecessary abstraction?

### Backend

- Are types explicit?
- Are imports clean?
- Are errors safe?
- Are secrets excluded from logs/responses?
- Are persistence constraints appropriate?
- Are migrations safe for existing data?
- Are tests behavioral and isolated?

### Flutter

- Is API JSON contained in the data layer?
- Are domain models clean?
- Is Cubit state explicit?
- Are widgets declarative?
- Are loading/empty/error/retry states handled?
- Is responsive behavior correct?
- Are design tokens used?
- Are stable keys present where identity/testing requires them?

### Verification

Run backend:

```bash
ruff check .
ruff format --check .
pytest -q
```

Run Flutter:

```bash
flutter analyze
flutter test
```

Formatting should also be clean according to the project's Dart/Flutter workflow.

---

# 74. The SofaWatch standard

Code added to SofaWatch should aim to be understandable by someone opening the file months later without remembering the implementation conversation that produced it.

The preferred code is:

```text
explicit
  + typed
  + testable
  + consistent
  + secure
  + boring in a good way
  + easy to change
```

If two approaches are equally correct, prefer the one that makes the architecture and intent easiest to understand.
