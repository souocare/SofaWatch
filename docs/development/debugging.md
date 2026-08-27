# Debugging

This guide describes a practical debugging workflow for SofaWatch during development.

The goal is to diagnose problems systematically across the backend, Flutter clients, authentication, metadata providers, background jobs, database state, and local network configuration.

Avoid fixing symptoms with ad-hoc changes before identifying which layer actually owns the failure.

---

## 1. Start by Locating the Failure

A useful first question is:

```text
Where does the failure first become observable?
```

Typical layers are:

```text
Flutter UI
    |
    v
Cubit / Bloc
    |
    v
Repository / ApiClient
    |
    v
HTTP / CORS / Network
    |
    v
FastAPI Route
    |
    v
Service
    |
    v
Repository / Provider
    |
    v
SQLite / External API
```

The fastest debugging path is usually to identify the first broken boundary rather than inspect the entire stack at once.

---

# 2. Recommended Debugging Order

When a feature fails end-to-end, use this order:

1. reproduce the issue consistently;
2. identify the affected client/platform;
3. verify the backend is reachable;
4. verify the HTTP request/response;
5. inspect backend logs;
6. inspect the route/service boundary;
7. inspect provider/database behavior;
8. inspect Cubit/BLoC state transitions;
9. inspect presentation only after the underlying state is understood;
10. add or update a regression test once the cause is known.

Avoid starting with UI changes when the backend is returning the wrong state.

---

# 3. Backend Is Not Reachable

Verify that FastAPI is running:

```bash
curl http://127.0.0.1:8000/docs
```

or open:

```text
http://127.0.0.1:8000/docs
```

If this fails, check the backend process first.

Start it from `backend/`:

```bash
uvicorn app.main:app \
  --reload \
  --host 0.0.0.0 \
  --port 8000
```

Common causes include:

- virtual environment not activated;
- missing dependencies;
- invalid `.env`;
- failed settings validation;
- database migration error;
- port already in use.

---

# 4. Port Already in Use

On macOS/Linux, inspect port `8000`:

```bash
lsof -i :8000
```

If another process owns the port, either stop it or start SofaWatch on another port.

If you change the backend port, remember to update the Flutter `SOFAWATCH_SERVER_URL`.

Example:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8001
```

---

# 5. Configuration Errors

SofaWatch validates backend settings at startup.

If startup fails, inspect the root `.env`.

Useful checks include:

- `SOFAWATCH_SECRET_KEY` exists;
- secret is at least 32 characters;
- numeric values are valid;
- provider settings are correctly formatted;
- paths are valid/writable.

See [Configuration](configuration.md).

Do not bypass validation by weakening configuration rules unless the rule itself is incorrect.

---

# 6. Verify Which `.env` Is Being Used

The backend reads the repository-level `.env`.

Expected structure:

```text
SofaWatch/
├── .env
├── backend/
└── frontend/
```

If you accidentally create:

```text
backend/.env
```

instead, the application may not use it.

When debugging configuration, verify the file location before changing code.

---

# 7. Flutter Cannot Reach the Backend

Use the correct URL for the client platform.

| Client | Backend URL |
| --- | --- |
| Flutter Web on Mac | `http://127.0.0.1:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Physical device | `http://<Mac-LAN-IP>:8000` |

A common mistake is using:

```text
127.0.0.1
```

from a physical phone.

On the phone, that address refers to the phone itself.

---

# 8. Find the Mac LAN Address

For a typical Wi-Fi connection:

```bash
ipconfig getifaddr en0
```

Example:

```text
192.168.1.50
```

Then run Flutter with:

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://192.168.1.50:8000
```

The backend must be listening on:

```text
0.0.0.0
```

not only `127.0.0.1`.

---

# 9. Physical Device Still Cannot Connect

Check:

- Mac and phone are on compatible networks;
- backend uses `--host 0.0.0.0`;
- LAN IP has not changed;
- local firewall is not blocking connections;
- Wi-Fi client isolation is disabled;
- VPNs are not interfering;
- the device browser can open the backend URL.

Try from the phone browser:

```text
http://<Mac-LAN-IP>:8000/docs
```

If that does not work, the issue is below Flutter.

---

# 10. Flutter Web CORS Errors

CORS only affects browser-based clients.

For local development, SofaWatch accepts:

```text
http://localhost:<port>
http://127.0.0.1:<port>
```

on arbitrary ports.

If Flutter Web is accessed through a LAN IP or custom hostname, configure that origin explicitly.

Example:

```dotenv
SOFAWATCH_CORS_ORIGINS=http://192.168.1.50:54000
```

or, for production:

```dotenv
SOFAWATCH_CORS_ORIGINS=https://sofawatch.example.com
```

Do not use permissive production CORS merely to hide configuration mistakes.

---

# 11. CORS vs Network Failure

These are different problems.

Network failure:

```text
browser/device cannot reach backend
```

CORS failure:

```text
browser reaches backend
but browser blocks the response due to origin policy
```

If the request never reaches FastAPI logs, suspect network/routing first.

If FastAPI receives it but the browser blocks access, inspect CORS.

---

# 12. Inspecting HTTP Behavior

Before debugging Flutter rendering, verify what the backend actually returns.

Useful tools:

- FastAPI `/docs`;
- browser DevTools Network tab;
- `curl`;
- backend logs.

Example:

```bash
curl -i http://127.0.0.1:8000/api/v1/...
```

For authenticated endpoints, use the correct auth mechanism rather than temporarily removing authorization.

---

# 13. Backend Logs

Backend logs are often the fastest way to locate a failing boundary.

Look for:

- route/path;
- status code;
- exception type;
- provider timeout;
- database constraint failure;
- authentication rejection;
- worker/job failure.

Logs should not contain secrets.

Do not add logging that prints passwords, tokens, refresh credentials, cookies, or provider credentials.

---

# 14. FastAPI 422 Errors

`422 Unprocessable Entity` usually means request validation failed before the service logic executed.

Check:

- request body field names;
- required fields;
- enum values;
- query parameters;
- path parameter types.

Use `/docs` to compare the expected request contract with what Flutter sends.

---

# 15. FastAPI 401 vs 403

Use the distinction diagnostically.

```text
401
-> authentication missing/invalid

403
-> authenticated user lacks permission
```

If an Admin endpoint returns `403`, do not disable the Admin dependency.

First confirm the current user is actually an Administrator.

---

# 16. Authentication Looks Broken on Web

Web persistent authentication uses an HttpOnly session cookie.

Important debugging boundaries:

```text
browser cookie
backend AuthSession
short-lived access token
Flutter AuthCubit state
```

Check whether the browser is actually sending the cookie.

Use browser DevTools:

```text
Network
-> request
-> Cookies / Request Headers
```

Because the cookie is HttpOnly, Flutter/JavaScript should not be able to read its raw value directly.

---

# 17. Web Session Does Not Restore

Check:

- Web session cookie exists;
- cookie domain/path are correct;
- CORS allows credentials;
- backend session exists;
- session is not revoked/expired;
- user is still active;
- restore endpoint returns the expected result.

Do not store the persistent Web session token in localStorage as a workaround.

---

# 18. Invalid Bearer with Valid Cookie

SofaWatch intentionally gives an explicit Bearer credential precedence.

This means:

```text
invalid Bearer
+
valid Web cookie
```

should still fail.

Do not "fix" this by silently falling back to the cookie.

That behavior is intentional and security-sensitive.

---

# 19. Mobile Session Does Not Restore

Native authentication uses:

```text
access token
+
rotating refresh credential
```

Check:

- refresh credential exists in client storage;
- backend AuthSession exists;
- session is not revoked/expired;
- refresh credential matches current server-side hash;
- client correctly stores the newly rotated credential after refresh.

A common bug is successfully refreshing but failing to replace the previous stored refresh credential.

---

# 20. Refresh Credential Reuse

If an old refresh credential is reused after rotation, rejection is expected.

This is not a session bug.

Flow:

```text
credential A
   |
   v
refresh succeeds
   |
   v
credential B issued

credential A used again
   |
   v
reject
```

---

# 21. Logout Appears Not to Work

Distinguish between:

```text
client state
server AuthSession
browser cookie
native refresh credential
access token
```

For Web logout:

- backend should revoke current Web session;
- cookie should be cleared/invalidated;
- AuthCubit should become unauthenticated.

For Mobile logout:

- backend session should be revoked;
- local refresh credential should be cleared;
- access token state should be cleared.

---

# 22. Log Out Everywhere

If only one device logs out, verify the request used the intended "everywhere" operation.

The backend should revoke all sessions owned by the user.

Do not expect other users to be affected.

---

# 23. Setup Screen Appears Unexpectedly

First-run setup depends on backend user state, not frontend storage.

If Setup appears unexpectedly, verify:

- frontend is pointing to the intended backend;
- SQLite DB path is correct;
- database file exists;
- migrations are applied;
- users exist in the intended database.

A wrong `SOFAWATCH_DATABASE_URL` can make the backend appear like a new installation.

---

# 24. Setup Screen Does Not Appear

If you expected a fresh installation but see Login:

- confirm the backend DB already has users;
- confirm Flutter is connecting to the expected backend;
- verify you did not reuse an older development database.

Deleting the frontend app does not delete backend users.

---

# 25. iOS Simulator State Is Stale

To completely uninstall SofaWatch from the booted simulator:

```bash
xcrun simctl uninstall booted com.souocare.sofawatch
```

This is useful when testing:

- first install;
- local storage;
- mobile auth credentials;
- setup-related client state.

It does not reset the backend database.

---

# 26. Android Emulator State Is Stale

Use the emulator/app settings or Flutter/ADB tooling to clear app data when required.

The principle is the same as iOS:

```text
client reset
!=
backend reset
```

Do not delete the SQLite database just to reset mobile client state.

---

# 27. Database Migration Errors

Start with:

```bash
alembic current
alembic heads
alembic history --verbose
```

Then:

```bash
alembic upgrade head
```

If a migration fails, inspect the exact revision and operation.

Do not manually edit the database schema as the first response.

See [Database Migrations](migrations.md).

---

# 28. Multiple Alembic Heads

If:

```bash
alembic heads
```

returns multiple unexpected heads, stop and inspect the migration graph.

Do not simply run migrations until one appears to work.

Determine whether the correct solution is:

- rebase/recreate an unpublished migration;
- or create an Alembic merge revision.

---

# 29. `alembic check` Reports Differences

Run:

```bash
alembic check
```

If differences are reported, determine whether:

- a SQLAlchemy model changed without a migration;
- a migration is incomplete;
- metadata differs intentionally;
- test/development DB is not at head.

Do not automatically autogenerate and commit every reported difference without review.

---

# 30. Foreign-Key Errors

SofaWatch explicitly enables:

```sql
PRAGMA foreign_keys=ON;
```

A foreign-key failure may reveal a real integrity bug.

Check:

- insert/delete ordering;
- ownership IDs;
- cascade behavior;
- stale references;
- migration assumptions.

Do not disable foreign keys to make the operation succeed.

---

# 31. SQLite Database Appears Empty

Check the configured URL:

```dotenv
SOFAWATCH_DATABASE_URL=sqlite:///./data/sofawatch.db
```

Relative SQLite paths depend on the process working directory.

Run backend commands consistently from `backend/` unless using absolute paths.

Also verify you did not accidentally create a second database in another directory.

Useful command:

```bash
find .. -name "sofawatch.db" -print
```

---

# 32. Database Integrity Debugging

For a suspected SQLite integrity issue:

```sql
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

Use these deliberately.

They are diagnostics, not normal request-time operations.

Preserve a copy of valuable data before experimenting with destructive fixes.

---

# 33. Search Returns No Results

Check the flow in order:

```text
SearchBloc query
    |
    v
SearchRepository
    |
    v
Backend Search API
    |
    v
TMDB
```

Verify:

- query meets minimum requirements;
- media filter is correct;
- TMDB token is configured;
- backend provider request succeeds;
- normalized response contains TV/Movie results.

People are intentionally filtered from the common media result model.

---

# 34. Search Shows Old Results

Search intentionally protects against stale/out-of-order responses.

If results appear wrong, inspect:

- query normalization;
- debounce;
- request sequence;
- current filter;
- cached key;
- page.

Do not remove stale-response protection unless it is proven to be the bug.

---

# 35. Search Cache Confusion

Search uses an in-memory TTL/LRU cache.

Current intended behavior:

```text
TTL = 5 minutes
max entries = 100
```

The cache is:

- process-local;
- non-persistent;
- query/filter/language/page aware where required.

Restarting the backend/client-side cache owner may clear it depending on where the relevant cache lives.

Do not debug persistent stale data as if this cache survives restarts.

---

# 36. Search Pagination Duplicates or Skips Results

Check:

- requested page;
- cache key includes page;
- append behavior;
- stale-response sequence;
- backend normalization;
- provider pagination.

Pagination failures should preserve already loaded results.

---

# 37. Library Mutation Does Not Update Search Row

This is known deferred work.

Search-state synchronization after Library mutations without rerunning Search is not fully finalized.

Do not build a duplicate architecture simply to patch one row.

Track it against the implementation roadmap.

---

# 38. Show Import Creates Duplicate

Import should be idempotent where designed.

Check:

- provider external ID;
- existing local mapping;
- transaction boundary;
- repository uniqueness checks;
- concurrent import behavior.

Do not use title matching as a substitute for provider identity when a direct provider ID exists.

---

# 39. Movie Import Creates Duplicate

The TMDB Movie import endpoint is intended to be idempotent.

Check the local provider mapping/import lookup before creating a new Movie.

Concurrent requests may reveal a missing uniqueness constraint or transaction issue.

---

# 40. Episode List Is Empty

Show Details loads Episodes lazily by Season.

Check:

- Season was expanded;
- local Episodes exist;
- sync decision executed;
- provider request succeeded;
- Episodes were persisted;
- Season-specific Cubit/state succeeded.

Do not assume all Episodes are imported during the initial Show import.

---

# 41. One Season Fails

Season failure should be isolated.

Expected behavior:

```text
Season 1 -> success
Season 2 -> failure
Season 3 -> success
```

If the entire Show Details page fails because one Season fails, inspect state composition.

The architecture expects independent Season loading/error/retry behavior.

---

# 42. Mark Watched Does Not Advance Watch Next

Trace the complete mutation:

```text
create watch event
    |
    v
recalculate progress
    |
    v
commit
    |
    v
refresh affected Watch Next data
```

Check whether the backend state is correct before debugging the UI refresh.

If backend state is correct but Watch Next is stale, inspect frontend coordination.

---

# 43. Rewatch Replaces Previous Watch

That is incorrect behavior.

A rewatch must create another watch event.

Expected:

```text
Event A
Event B
Event C
```

not:

```text
Event C only
```

Check:

- watch-event creation;
- unique constraints;
- service logic;
- event-removal logic;
- frontend action endpoint.

---

# 44. Removing a Watch Event Makes Episode Unwatched Incorrectly

After deleting one event, the backend must inspect remaining history.

Example:

```text
A + B + C
remove C
```

Expected:

```text
watch_count = 2
is_watched = true
watched_at = B
```

If the Episode becomes unwatched, inspect derived-state recalculation.

---

# 45. Ended Show Disappears from Watch Next

Remember:

```text
Ended
!=
Completed by the user
```

An Ended Show with unwatched eligible Episodes may still belong in Watch Next.

Check status normalization and Watch Next inclusion rules.

---

# 46. Caught-Up Show Still Appears in Watch Next

A caught-up Show should not appear when no eligible next Episode exists.

Check:

- Episode air dates;
- watched state;
- next-episode selection;
- local Episode synchronization;
- provider freshness.

Do not invent a future Episode to keep the Show visible.

---

# 47. Upcoming Shows Wrong Date

Upcoming is based on provider/local `air_date`.

Check:

- stored date;
- requested range;
- date-only handling;
- frontend grouping;
- local timezone presentation.

Do not manufacture an air time from a date-only value.

---

# 48. Background Job Does Not Run

First confirm the worker is running:

```bash
python -m app.jobs.worker
```

The FastAPI process does not execute scheduled jobs by itself.

Then inspect:

- registered job;
- persisted job state;
- next run;
- current status;
- worker logs.

---

# 49. Background Job Stuck as Running

A worker may have been interrupted mid-job.

Check:

- worker process;
- job start time;
- stale-running recovery logic;
- server restart history.

The scheduler is expected to recover stale/interrupted running states according to current logic.

Future work may make stale timeout configurable per job.

---

# 50. Metadata Sync Does Not Refresh a Show

Automatic metadata sync respects refresh policy.

Check:

- Show status;
- metadata age;
- `SOFAWATCH_METADATA_REFRESH_DAYS`;
- whether Show is Ended/Canceled;
- provider availability;
- job result counters.

A worker check every eight hours does not mean every Show refreshes every eight hours.

---

# 51. Metadata Sync Stops After One Error

That would be incorrect batch behavior.

One Show failure should not abort all remaining Shows.

Inspect the per-item exception boundary.

Expected:

```text
success
failure
success
skip
```

with structured result counters preserved.

---

# 52. TMDB Is Not Configured

Check:

```dotenv
SOFAWATCH_TMDB_API_TOKEN=
```

in the root `.env`.

A missing token should be treated as:

```text
configured = false
```

not as a generic network outage.

Restart backend/worker after changing configuration.

---

# 53. TMDB Timeout

Check:

```dotenv
SOFAWATCH_TMDB_TIMEOUT_SECONDS=20
```

Then inspect:

- network connectivity;
- TMDB availability;
- timeout mapping;
- retry behavior.

Do not remove timeouts to make provider calls "work."

Finite provider timeouts are intentional.

---

# 54. Provider Returns Malformed Data

Provider-specific parsing should fail at the provider/data boundary.

Do not patch Flutter widgets to tolerate raw malformed TMDB structures.

The correct flow is:

```text
provider response
    |
    v
DTO/parser
    |
    v
safe application error
```

---

# 55. Server Health Fails for Non-Admin

That is expected.

Server Health is Administrator-only.

The frontend should also avoid loading the Admin repository for non-admin users.

Expected:

```text
non-admin
  -> no Server section
  -> no /server/health request
```

Backend protection remains authoritative.

---

# 56. Profile Entirely Fails Because One Section Failed

That is contrary to the intended failure boundaries.

Profile sections such as:

- Statistics;
- Library;
- History;
- Server;

should fail independently where practical.

Inspect whether one parent Cubit/page is incorrectly coupling unrelated feature states.

---

# 57. Flutter Widget Overflow

First identify the exact viewport.

Useful test dimensions include:

- narrow mobile;
- normal phone;
- landscape;
- desktop;
- ultrawide.

Use:

- `LayoutBuilder`;
- `MediaQuery`;
- `AppBreakpoints`;
- content-width constraints.

Do not fix one overflow by adding arbitrary hardcoded widths that break another layout.

---

# 58. Desktop Rows Are Too Wide

Desktop should not stretch content indefinitely.

Check whether the page/content container has an appropriate maximum width.

The responsive strategy is adaptive presentation, not simply filling all available width.

---

# 59. Design Looks Inconsistent

Check whether the widget uses centralized design tokens:

```text
AppColors
AppTypography
AppSpacing
AppRadius
AppDurations
AppBreakpoints
```

Avoid introducing isolated magic colors/spacing before checking the design system.

---

# 60. Cubit Emits Unexpected State

Debug from the event/action boundary.

Check:

```text
initial state
action invoked
repository response
exception mapping
emitted states
```

Add a focused Cubit test before adding UI workarounds.

If the repository returns correct data but Cubit state is wrong, the bug belongs in application orchestration.

---

# 61. UI Does Not Update After Correct Cubit State

If the Cubit state is correct, inspect presentation:

- `BlocBuilder` scope;
- state equality;
- `Equatable` props;
- widget keys;
- conditional rendering;
- stale local `StatefulWidget` state.

Do not refetch backend data merely to force a rebuild.

---

# 62. Stale Local Widget State

Presentation-only state may outlive the data it represents.

Check:

- controllers;
- local booleans;
- `ValueKey`s;
- widget identity;
- modal lifecycle.

Prefer deriving UI from Cubit/domain state when it represents application truth.

---

# 63. Navigation Loses State

SofaWatch uses stateful navigation branches to preserve main-tab context.

If state disappears unexpectedly, inspect:

- whether route is using the intended navigator;
- whether feature Cubit is recreated;
- whether root vs branch navigator is correct;
- whether modal/detail route is replacing the branch state.

Search/details should not unnecessarily destroy originating context.

---

# 64. Search Opens in Wrong Presentation

Search is responsive/platform-specific.

Expected:

```text
Web/Desktop
-> modal-style global Search

Mobile
-> Dual-Pill integrated Search
```

Do not create another Search implementation inside Explore to solve presentation issues.

---

# 65. Authentication UI Is Correct but Endpoint Still Fails

UI state is not backend authorization.

Inspect:

- current user;
- access token/cookie;
- backend dependency;
- Administrator flag;
- session validity.

Do not remove backend authorization because the button was visible.

---

# 66. Error Message Exposes Technical Details

Errors should be mapped before presentation.

Backend:

```text
internal/provider/database error
-> safe API error
```

Frontend:

```text
Dio/API failure
-> AppException
-> user-safe message
```

Do not render raw exception strings directly.

---

# 67. Tests Pass Individually but Fail Together

Suspect shared mutable state.

Common causes:

- cached settings;
- environment variables;
- in-memory caches;
- database state;
- singleton instances;
- static test data;
- wall-clock dependency.

Tests must be independent from execution order.

---

# 68. Tests Fail Only on Current Date

This usually indicates uncontrolled time.

Prefer:

- explicit date input;
- injected clock;
- deterministic timestamps.

Do not continually update expected dates to match the calendar.

---

# 69. Backend Regression Workflow

When a backend regression appears:

```text
1. identify failing behavior
2. run smallest failing test
3. inspect route/service/repository boundary
4. fix production code
5. rerun focused test
6. run related tests
7. ruff check
8. pytest -q
```

Do not edit the test first unless the intended behavior deliberately changed.

---

# 70. Frontend Regression Workflow

When a frontend regression appears:

```text
1. reproduce
2. inspect Cubit/Bloc state
3. inspect repository response
4. inspect widget only after state is understood
5. add/fix focused test
6. flutter analyze
7. flutter test
```

---

# 71. Debugging with Temporary Logs

Temporary logs can be useful, but keep them:

- focused;
- safe;
- removable;
- free of credentials.

Good:

```text
Loaded 12 watch events for user X
```

Bad:

```text
Authorization: Bearer <token>
```

Remove noisy debugging logs before finalizing a change unless they provide lasting operational value.

---

# 72. Debugging with `print`

Prefer the project's logging infrastructure over scattered `print` statements in production code.

For very short local investigation, temporary output may be acceptable, but do not leave debugging noise behind.

Flutter-side debugging should similarly avoid long-lived `debugPrint` calls without operational purpose.

---

# 73. Use Focused Tests as a Debugger

A small test is often more useful than repeatedly clicking through the app.

Example:

```text
bug:
removing newest watch event produces wrong watched_at

focused test:
create A/B/C
delete C
assert watch_count == 2
assert watched_at == B
```

Once that test fails consistently, the fix becomes much easier to reason about.

---

# 74. Do Not Debug Against Stale Code

When the current file state matters, inspect the actual local implementation.

Useful commands include:

```bash
cat path/to/file
sed -n '1,220p' path/to/file
grep -R "symbol_name" -n app tests
```

Do not assume an old GitHub snapshot or previous conversation excerpt still matches current local code.

---

# 75. Git Helps Isolate Regressions

Useful commands:

```bash
git status
git diff
git log --oneline -10
```

For a recent regression, inspect which files changed.

Avoid broad rewrites before understanding whether the regression is localized.

---

# 76. `git diff` Before Testing

Before running a large suite, review:

```bash
git diff
```

This often catches:

- accidental edits;
- debug code;
- wrong file;
- duplicated logic;
- test changes masking regressions.

---

# 77. Preserve Valuable Development Data

Do not delete:

```text
data/sofawatch.db
```

as a generic debugging step.

A real development database may contain valuable Library/history/auth state.

If you need a clean database:

- copy the existing DB first;
- configure a separate disposable DB;
- or deliberately create a test fixture.

---

# 78. Snapshot Before Migration Debugging

Before experimenting with a migration against meaningful data, make a safe copy/snapshot.

Do not repeatedly run destructive migrations/downgrades against the only copy.

A future formal backup strategy will standardize this further.

---

# 79. Debugging Import / Export

If import fails:

1. validate export format/version;
2. inspect preview/validation result;
3. identify which section failed;
4. verify duplicate/conflict rules;
5. inspect partial-failure summary.

Do not apply the same import repeatedly without understanding idempotency/conflict behavior.

---

# 80. Debugging Statistics

Statistics are derived from persisted viewing data.

If a number looks wrong, inspect the underlying events first.

For example:

```text
Movies watched = 5
Unique Movies = 3
```

may be correct if two movies were rewatched.

Do not assume total viewings should equal unique media.

---

# 81. Debugging History

History is event-based.

Duplicate-looking rows may be legitimate rewatches.

Before deduplicating anything, compare:

- media ID;
- event ID;
- `watched_at`.

Two rows for the same Episode at different times are expected if it was watched twice.

---

# 82. Debugging Provider IDs

Keep internal and external IDs distinct.

When investigating a mismatch, write them explicitly:

```text
SofaWatch Show ID: 42
TMDB Show ID: 1396
```

Do not compare a local ID against a provider ID as if they were the same namespace.

---

# 83. Debugging Future TVDB Integration

When TVDB is introduced, debug at the provider mapping boundary.

Do not patch domain logic with conditionals such as:

```text
if provider == tvdb
```

throughout unrelated services.

Provider-specific failures should remain isolated.

---

# 84. Debugging External Ratings

Future external ratings must preserve provenance.

If an IMDb/TMDB rating looks wrong, verify:

```text
provider
rating value
scale
vote count
updated timestamp
```

Do not compare a personal SofaWatch rating to an external rating as if they were the same metric.

---

# 85. Debugging Worker vs API State

Both processes share the same SQLite database.

If the API does not reflect worker changes:

- verify both use the same `.env`;
- verify both use the same `SOFAWATCH_DATABASE_URL`;
- verify relative paths resolve from expected working directories;
- check commit/transaction behavior;
- restart only after understanding whether caching is involved.

Accidentally running the worker against another DB can make state appear inconsistent.

---

# 86. Debugging Wrong Database Path

Because SQLite uses a file path, accidentally changing working directory can create a second database.

Use:

```bash
find .. -name "*.db" -print
```

and inspect the configured URL.

Prefer consistent backend working directory during development.

---

# 87. Debugging Server Diagnostics

If diagnostics report degraded health:

```text
overall
database
TMDB
```

inspect the failing component independently.

Database unavailable and TMDB unavailable have different operational impact.

Do not assume "degraded" means the entire app is unusable.

---

# 88. Debugging Logs UI

If Admin Logs UI shows nothing:

- verify backend logging is producing entries;
- check level filter;
- check pagination/limit;
- verify Administrator authorization;
- inspect safe-message mapping.

Do not expose raw log files/secrets directly to the UI as a shortcut.

---

# 89. Debugging Background Job Counters

If:

```text
checked
refreshed
skipped
failed
```

look inconsistent, trace one media item through the sync workflow and define which counter it should increment.

These metrics should eventually have rigorous semantics.

Do not "fix" totals by adjusting the UI only.

---

# 90. Debugging Partial Failures

A partial failure should preserve successful work where the feature explicitly supports it.

Examples:

- metadata batch;
- import;
- independent Profile sections.

Identify whether the operation is intended to be:

```text
atomic
```

or:

```text
partially successful
```

before changing transaction/error behavior.

---

# 91. Debugging Responsive Tests

When a layout fails only at one size, reproduce that exact size in a widget test.

Do not rely only on manual resizing.

Test representative breakpoints rather than every possible width.

---

# 92. Debugging Accessibility

For semantics/focus issues:

- inspect semantic labels;
- verify tappable targets;
- inspect keyboard traversal on Web/Desktop;
- verify modal focus behavior;
- test screen-reader semantics where possible.

Do not solve accessibility by visually hiding content that should remain semantically available.

---

# 93. What Not to Do

Avoid these debugging shortcuts:

- disabling authorization;
- disabling foreign keys;
- deleting the DB immediately;
- replacing async state with hardcoded values;
- swallowing exceptions;
- returning fake success;
- increasing all timeouts blindly;
- removing stale-response protection;
- removing tests;
- changing expected values without understanding behavior;
- storing tokens in logs;
- creating duplicate Web/mobile implementations;
- adding provider-specific hacks into domain code.

These usually hide the real problem and create technical debt.

---

# 94. When to Add a Regression Test

Add a regression test when:

- the bug could realistically return;
- the behavior is important;
- the failure exposed a missing invariant;
- the fix changes a subtle edge case.

The test should fail on the buggy behavior and pass after the fix.

---

# 95. Minimal Debugging Checklist

For a general issue:

```text
[ ] reproduce consistently
[ ] identify platform
[ ] verify backend reachable
[ ] inspect HTTP response
[ ] inspect backend logs
[ ] verify DB/provider state
[ ] inspect Cubit/Bloc state
[ ] inspect UI rendering
[ ] add focused regression test
[ ] run analyzer/lint
[ ] run relevant full suite
```

---

## Related Documentation

- [Development Setup](setup.md)
- [Configuration](configuration.md)
- [Testing](testing.md)
- [Database Migrations](migrations.md)
- [Architecture Overview](../architecture/overview.md)
- [Data Flow](../architecture/data-flow.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Authentication Architecture](../architecture/authentication.md)
- [Provider Architecture](../architecture/provider-architecture.md)
- [Background Jobs](../architecture/background-jobs.md)
- [Implementation Status](../features/implementation-status.md)
