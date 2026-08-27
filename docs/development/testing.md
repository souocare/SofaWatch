# Testing

SofaWatch uses automated tests as a core part of its development workflow.

The objective is not only to keep the test suites green, but to use tests to protect domain behavior, API contracts, persistence rules, authentication, state management, and user-visible interactions while the application evolves.

The normal workflow is:

```text
Inspect current behavior
        |
        v
Make a focused change
        |
        v
Run focused tests
        |
        v
Run static analysis / linting
        |
        v
Run the relevant full suite
        |
        v
Fix regressions
        |
        v
Commit a coherent change
```

Do not modify a test merely to make it pass if the failure is revealing a real regression.

---

# 1. Test Suites

SofaWatch has independent backend and frontend test suites.

Backend:

```bash
pytest -q
```

Frontend:

```bash
flutter test
```

Run commands from the corresponding `backend/` or `frontend/` directory unless stated otherwise.

---

# 2. Stable Checkpoints

Test counts are useful as development checkpoints, but they are not permanent targets.

At one known stable project checkpoint:

```text
Backend:   1301 passed
Frontend:  1547 passed
```

These numbers will naturally change as tests are added, removed, consolidated, or refactored.

The important invariant is:

```text
expected behavior remains covered
+
the relevant suite is green
```

not a fixed number of tests.

---

# 3. Testing Philosophy

Tests should primarily protect behavior and contracts.

Prefer tests that answer questions such as:

- Does the service enforce the business rule?
- Does the API return the expected contract?
- Is user-scoped data isolated correctly?
- Does a rewatch create another viewing event?
- Does deleting a viewing event recalculate progress correctly?
- Does authentication reject invalid credentials?
- Does a Cubit transition through the correct states?
- Does a widget expose the correct action for the current state?
- Does a retry actually repeat the failed operation?

Avoid tests that exist only to mirror implementation details without protecting meaningful behavior.

---

# 4. Test Pyramid

SofaWatch does not need a rigid theoretical test pyramid, but tests should be placed at the lowest useful layer.

Conceptually:

```text
            Integration / Flow
                 /\
                /  \
               /    \
              / API  \
             /--------\
            / Services \
           /------------\
          / Repositories \
         /----------------\
        / Domain / Cubits   \
       /--------------------\
      / Widgets / Components \
     --------------------------
```

A business rule that can be tested directly in a service should not require a full UI test.

Likewise, important API authorization or serialization behavior should still have API-level coverage even if the underlying service is already tested.

---

# Backend Testing

# 5. Backend Test Stack

Backend testing primarily uses:

- pytest
- FastAPI test infrastructure
- SQLAlchemy-backed test databases
- fakes/mocks where external boundaries require them

The backend test structure generally follows the application structure.

Typical areas include:

```text
tests/
├── api/
├── services/
├── repositories/
├── providers/
├── jobs/
├── core/
└── ...
```

The exact repository structure is authoritative if it differs from this conceptual layout.

---

# 6. Run the Full Backend Suite

From `backend/`:

```bash
pytest -q
```

Use the full suite when completing a coherent backend change or before considering a backend task finished.

During implementation, prefer focused tests first.

---

# 7. Focused Backend Tests

Run the smallest useful test target while iterating.

A test file:

```bash
pytest -q tests/services/test_example_service.py
```

A test class:

```bash
pytest -q tests/services/test_example_service.py::TestExampleService
```

A single test:

```bash
pytest -q tests/services/test_example_service.py::test_example_behavior
```

Keyword filtering can also be useful:

```bash
pytest -q -k "watch_event"
```

Prefer explicit paths when you know exactly which behavior is under development.

---

# 8. Backend Test Progression

For a change spanning several backend layers, a useful progression is:

```text
service test
    |
    v
repository/provider test
    |
    v
API route test
    |
    v
related test directory
    |
    v
full backend suite
```

Not every change needs every layer.

Choose coverage based on the behavior being changed.

---

# 9. Service Tests

Services contain application/business orchestration and are an important testing boundary.

Service tests should verify behavior such as:

- business rules;
- state transitions;
- calculations;
- idempotency;
- ownership checks where service-level;
- provider orchestration;
- handling of partial failures;
- persistence orchestration.

Prefer injecting repositories/providers rather than patching deep internal implementation details.

---

# 10. Repository Tests

Repository tests should focus on persistence behavior.

Examples:

- correct filtering;
- user scoping;
- ordering;
- relationships;
- inserts/updates/deletes;
- uniqueness behavior;
- pagination;
- database constraints where relevant.

For SQLite-specific behavior, tests should reflect the actual SQLite configuration used by SofaWatch where practical.

SQLite foreign-key behavior is particularly important because SofaWatch explicitly enables:

```sql
PRAGMA foreign_keys=ON
```

---

# 11. API Tests

API tests should protect the HTTP contract.

Examples:

- route availability;
- status codes;
- request validation;
- response schemas;
- authentication requirements;
- administrator authorization;
- safe error responses;
- pagination contracts;
- user isolation.

Do not rely solely on frontend behavior to protect backend authorization.

Administrative endpoints must remain protected independently of whether the Flutter UI hides them.

---

# 12. Authentication Tests

Authentication is security-sensitive and should have explicit regression coverage.

Important behavior includes:

- login;
- invalid credentials;
- disabled/inactive users when implemented;
- access-token validation;
- Web session-cookie authentication;
- mobile refresh;
- refresh credential rotation;
- rejection of reused credentials;
- session revocation;
- logout;
- logout everywhere;
- first-run setup;
- first-user administrator creation;
- registration policy;
- password change;
- password recovery;
- recovery token expiry/single use;
- Mobile-to-Web handoff;
- Bearer precedence over cookie authentication.

When a Bearer credential is present but invalid, tests should ensure authentication does not silently fall back to a valid cookie.

---

# 13. User-Scoped Data Tests

SofaWatch is multi-user.

Tests for user-owned data should verify isolation where relevant.

Examples include:

- Library;
- watch progress;
- watch events;
- ratings;
- history;
- sessions.

A successful request for User A must not accidentally expose or mutate User B's data.

This should be treated as a backend invariant, not a frontend responsibility.

---

# 14. Viewing Event Tests

Watch history is event-based.

Tests should preserve the rule:

```text
first watch
    -> event A

rewatch
    -> event B

rewatch
    -> event C
```

and therefore:

```text
watch_count = 3
watched_at = timestamp(event C)
```

Removing an individual event should verify that derived state is recalculated correctly.

Do not rewrite tests to treat rewatch as replacing an earlier viewing.

---

# 15. Provider Tests

External provider behavior should be tested at the provider boundary.

Tests should avoid depending on live external APIs for the normal automated suite.

Use deterministic responses/fakes for:

- successful responses;
- provider errors;
- timeout behavior;
- malformed responses;
- missing metadata;
- pagination;
- mapping.

Provider-specific DTOs should not leak into domain tests.

---

# 16. TMDB Tests

TMDB is currently the active metadata provider.

Important coverage can include:

- search normalization;
- TV/movie mapping;
- genres;
- seasons;
- episodes;
- import behavior;
- metadata refresh;
- timeout/error mapping;
- health behavior.

Live TMDB availability should not determine whether the standard test suite passes.

---

# 17. Future Provider Tests

When TVDB or another provider is introduced, it should receive its own provider tests rather than modifying domain tests to become provider-specific.

The intended relationship is:

```text
Provider response
      |
      v
Provider adapter
      |
      v
Internal mapping
      |
      v
SofaWatch domain
```

Provider failure should be tested according to explicit precedence/fallback rules once those rules exist.

---

# 18. Background Job Tests

Background jobs should be tested independently from the infinite worker loop where possible.

Useful areas include:

- job registration;
- due-job selection;
- execution;
- run persistence;
- success;
- failure;
- partial failure;
- structured result data;
- last/next execution;
- Run Now;
- stale-running behavior where implemented.

Do not create tests that need to wait for real scheduler intervals.

Time should be controlled or injected where practical.

---

# 19. Time-Dependent Backend Tests

Avoid tests whose outcome changes depending on the real current date or time.

Prefer:

- injected clock/date providers;
- explicit timestamps;
- frozen/test-controlled time where the architecture supports it.

A known future cleanup area is import/export date testing that still contains fixed-date assumptions tied too closely to real time.

When touching those tests, prefer making the production boundary deterministic rather than continually updating expected dates.

---

# 20. Configuration Tests

Configuration tests should instantiate the actual settings model.

Test the real parsing/validation behavior rather than reproducing it manually.

Examples:

- required secret;
- secret length;
- access-token expiration;
- session expiration;
- provider timeout;
- metadata refresh interval;
- CORS parsing;
- supported-language parsing.

Because `get_settings()` is cached, tests changing environment values must avoid leaking cached settings between cases.

See [Configuration](configuration.md).

---

# 21. Migration Tests and Checks

Alembic correctness is partly verified operationally.

Useful commands include:

```bash
alembic current
alembic heads
alembic check
```

Before important releases, also test upgrades from representative older SofaWatch database snapshots.

Creating a brand-new database and migrating it to head does not prove that a real older installation upgrades correctly.

See [Database Migrations](migrations.md).

---

# 22. Backend Linting

Ruff is used for backend linting and formatting.

Check:

```bash
ruff check .
```

Format:

```bash
ruff format .
```

For a focused development loop, you may run Ruff against changed paths before running it repository-wide.

A task should not be considered complete if it introduces new relevant lint failures.

---

# Frontend Testing

# 23. Frontend Test Stack

Flutter tests protect:

- domain mapping where applicable;
- repositories;
- Cubits/BLoCs;
- widgets;
- pages;
- navigation interactions;
- responsive behavior where relevant;
- loading/error/empty/success states.

Tests should follow the same feature boundaries as production code where practical.

---

# 24. Run the Full Frontend Suite

From `frontend/`:

```bash
flutter test
```

Run the full suite after completing a coherent frontend change.

---

# 25. Focused Flutter Tests

Run a single file:

```bash
flutter test test/path/to/example_test.dart
```

Use name filtering when useful:

```bash
flutter test test/path/to/example_test.dart \
  --plain-name "expected test name"
```

Focused tests provide much faster feedback while iterating on a feature.

---

# 26. Flutter Static Analysis

Run:

```bash
flutter analyze
```

Static analysis should remain clean.

Fix real warnings/errors rather than suppressing them without a reason.

---

# 27. Cubit and BLoC Tests

Application-state tests should focus on observable transitions and behavior.

For example:

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

Useful cases include:

- initial load;
- retry;
- refresh;
- stale-response protection;
- pagination;
- mutation success;
- mutation failure;
- preservation of previous data;
- independent section failure.

Avoid asserting private implementation details that do not affect behavior.

---

# 28. Repository Tests on Flutter

Data-layer repository tests should verify:

- endpoint usage;
- request parameters;
- DTO parsing;
- mapping to domain models;
- error mapping;
- authentication-related request behavior where applicable.

The domain layer should not know about:

- Dio;
- JSON;
- HTTP response structures.

Tests should reinforce that boundary.

---

# 29. Widget Tests

Widget tests should verify meaningful UI behavior.

Examples:

- loading indicator/skeleton;
- empty state;
- failure state;
- Retry;
- content rendering;
- action availability;
- admin-only visibility;
- button loading state;
- navigation;
- responsive presentation changes.

Prefer stable semantic keys and `ValueKey`s when they represent real widget identity.

Do not add keys solely to expose internal implementation details unless they materially improve test stability.

---

# 30. Loading, Error, Empty, and Success States

Reusable UI features should normally have explicit coverage for their important states:

```text
Initial
Loading
Success
Empty
Failure
Retry
```

Not every feature needs a distinct class for every conceptual state, but user-visible behavior should be covered.

Partial failures should remain isolated when the product architecture requires section independence.

For example, a Server Health failure should not make Profile Statistics disappear.

---

# 31. Responsive Tests

SofaWatch supports Web and mobile.

Where layout behavior differs meaningfully, test representative viewport sizes rather than relying only on the default Flutter test surface.

Important responsive behavior can include:

- mobile vs desktop navigation;
- bottom sheet vs dialog;
- content width;
- action placement;
- long titles;
- overflow;
- compact rows;
- modal behavior.

Do not duplicate every widget test at every possible screen width.

Choose boundaries that protect actual adaptive behavior.

---

# 32. Navigation Tests

Navigation tests should focus on user-observable behavior.

Important cases may include:

- opening details;
- returning without losing relevant state;
- Search preview;
- History -> Episode/Movie Details;
- selected Shows tab preservation;
- authentication redirects;
- setup vs login;
- admin-only routes/features.

Avoid coupling navigation tests to incidental router internals unless those internals are themselves part of the contract.

---

# 33. Search Tests

Search has several important asynchronous behaviors.

Tests should protect:

- empty query;
- minimum query handling;
- debounce;
- normalization;
- filters;
- initial loading;
- pagination;
- pagination retry;
- no results;
- network errors;
- timeout;
- provider errors;
- invalid responses;
- stale/out-of-order response protection;
- preserving previous results where intended.

Deferred Search state synchronization after Library mutations should not be accidentally "implemented" only in tests before the product behavior is defined.

---

# 34. Watch List Tests

Important Watch List behavior includes:

- Watch Next;
- Haven't Watched in a While;
- Haven't Started;
- Watch History;
- ordering;
- caught-up behavior;
- ended-but-incomplete shows;
- no known next episode;
- rewatch;
- mutation refresh behavior.

Tests should avoid encoding the incorrect assumption:

```text
Ended == Completed
```

because that is not a SofaWatch rule.

---

# 35. Authentication UI Tests

Frontend authentication tests should verify presentation/orchestration behavior without pretending UI hiding is authorization.

Useful cases include:

- setup shown when required;
- login shown otherwise;
- Sign Up hidden when registration is closed;
- session restoration;
- logout;
- auth failure;
- password recovery flows;
- admin-only controls hidden from non-admin users.

Backend tests remain responsible for actual authorization enforcement.

---

# 36. Admin UI Tests

For administrator-only sections, test both visibility and side effects.

A useful pattern is:

```text
Admin
  -> section visible
  -> repository may load

Non-admin
  -> section hidden
  -> admin repository must not be called
```

This avoids unnecessary forbidden requests and protects UI behavior while the backend independently protects the endpoint.

---

# 37. Test Doubles

Use the simplest test double that accurately represents the boundary:

- fake;
- stub;
- mock.

Prefer small deterministic fakes for repositories/services when they make tests clearer.

Avoid mocking long chains of internal methods.

If a test requires extensive knowledge of private implementation structure, consider whether the production abstraction boundary is wrong or the test is placed too high.

---

# 38. Network Calls in Tests

Normal automated tests should not depend on:

- live SofaWatch production servers;
- live TMDB;
- future live TVDB;
- internet availability.

Network boundaries should be controlled.

This makes tests:

- deterministic;
- fast;
- repeatable;
- runnable offline;
- suitable for CI.

---

# 39. Database Isolation

Backend tests must not mutate the developer's real SofaWatch database.

Test database state should be isolated and disposable.

Each test should receive the state it needs rather than depending on execution order.

Avoid tests that only pass because another test inserted required data first.

---

# 40. Test Independence

A test should be able to run:

```text
alone
```

and:

```text
as part of the full suite
```

with the same result.

Common sources of accidental coupling include:

- global caches;
- environment variables;
- database state;
- current time;
- singleton configuration;
- mutable fakes;
- test ordering.

Clean these boundaries when discovered rather than relying on suite ordering.

---

# 41. Regression Tests

When fixing a bug:

1. reproduce the behavior;
2. add or identify a test that fails for the bug;
3. implement the fix;
4. verify the focused test;
5. run related tests;
6. run the relevant full suite.

A regression test should describe the behavior being protected, not the accidental code structure of the fix.

---

# 42. Changing Existing Tests

Changing a test is appropriate when:

- the intended product behavior deliberately changed;
- the API contract deliberately changed;
- an implementation-independent expectation was wrong;
- the test itself was flaky or invalid;
- architecture was refactored while preserving behavior and the old test was coupled to internals.

Changing a test is not appropriate merely because new production code made it fail.

First determine whether the failure represents a regression.

---

# 43. Removing Tests

Remove a test only when:

- the behavior no longer exists by deliberate decision;
- equivalent or stronger coverage exists elsewhere;
- the test is testing obsolete implementation detail;
- the feature was intentionally removed.

Do not remove difficult tests simply to reduce maintenance cost without understanding what protection is being lost.

---

# 44. Test Naming

Test names should describe behavior.

Prefer:

```text
test_rewatch_creates_new_watch_event
test_non_admin_cannot_access_server_health
test_retry_reloads_failed_section
```

over names such as:

```text
test_method_1
test_case_a
test_button
```

A failing test name should quickly communicate what contract broke.

---

# 45. Arrange / Act / Assert

Use a clear structure when it improves readability:

```text
Arrange
  prepare state and dependencies

Act
  perform the behavior

Assert
  verify observable result
```

Comments such as `# Arrange` are optional.

The important part is conceptual separation, not ceremonial formatting.

---

# 46. One Behavior per Test

Prefer each test to have one primary reason to fail.

This does not mean one assertion per test.

Several assertions can verify one coherent result.

For example, a successful rewatch test may reasonably verify:

- a new event exists;
- watch count increased;
- latest watched timestamp changed.

Those assertions describe one behavior.

---

# 47. Error Testing

Do not test only successful paths.

Important boundaries should include failures such as:

- validation error;
- unauthorized;
- forbidden;
- not found;
- provider timeout;
- provider unavailable;
- invalid provider response;
- database failure where meaningfully handled;
- pagination failure;
- partial failure.

Errors exposed through the API/UI should remain safe and should not leak implementation secrets.

---

# 48. Security Regression Testing

Security-sensitive changes deserve explicit negative tests.

Examples:

```text
Can User A access User B's object?
Can a non-admin call the admin endpoint?
Can an expired recovery token be reused?
Can a rotated refresh credential be reused?
Can first-run setup be executed again?
Can registration bypass Open Registration?
Can an invalid Bearer silently fall back to a cookie?
```

The expected answer should be enforced by the backend.

---

# 49. Import / Export Tests

Import/export tests should cover:

- format version;
- validation;
- Library data;
- viewing history;
- ratings where included;
- duplicate handling;
- conflicts;
- partial failures;
- summary/result information.

Date-sensitive tests should eventually use a controlled clock/date boundary rather than assumptions tied to the actual current date.

---

# 50. Statistics Tests

Statistics should be tested as an independent feature.

Important invariants include:

- every viewing event counts toward viewing activity;
- rewatches count again;
- unique media counts remain distinct from total viewings;
- Episode and Movie metrics remain correctly separated;
- user scoping is preserved.

Do not duplicate Statistics business rules inside Home/Profile tests.

Those screens should test consumption/presentation of Statistics results.

---

# 51. Test Data

Use small, intentional fixtures.

Prefer data that makes the expected behavior obvious.

For example, when testing ordering:

```text
event A -> 10:00
event B -> 12:00
event C -> 11:00
```

is easier to reason about than large realistic fixture dumps.

Use realistic complexity only where the behavior requires it.

---

# 52. IDs in Tests

SofaWatch uses internal IDs after import.

Tests should distinguish:

```text
SofaWatch internal ID
```

from:

```text
TMDB ID
TVDB ID
IMDb ID
```

Do not accidentally encode provider IDs as domain identity.

This becomes increasingly important as additional metadata providers are introduced.

---

# 53. Provider Independence

Tests should reinforce the architecture:

```text
Domain
  != TMDB model

Domain
  != TVDB model

Domain
  != raw JSON
```

Provider mapping belongs at the external boundary.

A future TVDB implementation should not require rewriting core viewing-history or Library tests to know what TVDB is.

---

# 54. Running Tests Before Commit

For a small backend-only change:

```bash
pytest -q <focused-path>
ruff check <changed-paths>
pytest -q
```

For a small frontend-only change:

```bash
flutter test <focused-test>
flutter analyze
flutter test
```

For a cross-stack change:

```text
Backend focused tests
Frontend focused tests
Backend lint
Frontend analyze
Backend full suite
Frontend full suite
```

Use judgment for documentation-only changes or changes that genuinely cannot affect a particular suite.

---

# 55. Documentation-Only Changes

Pure Markdown/documentation changes do not require running thousands of application tests unless the change also modifies code/configuration.

However, verify:

- paths;
- commands;
- links;
- filenames;
- examples;
- documented behavior.

Documentation that confidently describes behavior that does not exist is still a defect.

---

# 56. CI

Continuous integration can automate:

```text
backend tests
backend linting
frontend tests
frontend analysis
migration checks
```

The exact CI policy may evolve as SofaWatch approaches stable releases.

Local development should not rely on CI as the first place regressions are discovered.

---

# 57. Coverage

Code-coverage percentage is not currently treated as the primary quality metric.

A high percentage does not guarantee useful tests.

Prioritize coverage of:

- business invariants;
- security boundaries;
- persistence rules;
- API contracts;
- state transitions;
- important UI interactions;
- regression-prone behavior.

Coverage tooling may still be useful diagnostically when looking for important untested paths.

---

# 58. Performance Tests

Performance-specific automated testing is not currently a central part of the standard suite.

Before adding benchmarks or performance infrastructure, identify a real performance-sensitive behavior.

Potential future areas include:

- large watch histories;
- large libraries;
- Search pagination/cache behavior;
- Statistics aggregation;
- metadata synchronization;
- import/export.

Do not add benchmark infrastructure solely for completeness.

---

# 59. Integration Tests

Broader integration testing is part of the final-quality roadmap.

Useful future end-to-end flows include:

```text
fresh install
  -> setup
  -> login
  -> search
  -> import
  -> add to Library
  -> mark watched
  -> history/statistics update
```

and:

```text
existing installation
  -> migration
  -> authentication
  -> preserved Library/history
```

Integration tests should complement, not replace, focused lower-layer tests.

---

# 60. Legacy Database Upgrade Testing

Before stable releases, test migration against a representative older SofaWatch SQLite database.

Verify preservation of:

- user IDs;
- users;
- Library;
- Episode progress;
- Episode watch history;
- Movie watch history;
- ratings;
- other user-scoped relationships.

This is different from testing only:

```text
empty database -> latest schema
```

Both paths matter.

---

# 61. Final Quality Gate

Before a significant release, the testing/quality pass should include at least:

Backend:

```bash
ruff check .
pytest -q
alembic current
alembic check
```

Frontend:

```bash
flutter analyze
flutter test
```

plus:

- representative manual smoke testing;
- migration testing;
- authentication flows;
- responsive validation;
- important Web/mobile flows;
- integration/regression testing appropriate to the release.

---

# 62. What "Done" Means

A development point is not complete merely because the code compiles.

For a normal implementation task, "done" means:

```text
behavior is defined
+
implementation is coherent
+
focused tests pass
+
lint/analyzer is clean where relevant
+
related regressions are resolved
+
relevant full suite passes
```

Documentation can then be updated to reflect the implemented behavior.

---

## Related Documentation

- [Development Setup](setup.md)
- [Configuration](configuration.md)
- [Database Migrations](migrations.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Database Architecture](../architecture/database.md)
- [Authentication Architecture](../architecture/authentication.md)
- [Background Jobs](../architecture/background-jobs.md)
- [Implementation Status](../features/implementation-status.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
