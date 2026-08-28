# Server Administration

## Overview

Server Administration is SofaWatch's administrator-only operational area for understanding and managing the health of a self-hosted installation.

It brings together operational information such as:

```text
Server Administration
├── Server Health
├── Database / Storage
├── Metadata Providers
├── Background Jobs
├── Logs
├── Import / Export
├── Security
└── User Administration
```

The feature has two distinct responsibilities:

```text
Observability
-> understand what is happening

Administration
-> perform explicit privileged actions
```

These responsibilities should remain clearly separated. Viewing server health should never accidentally mutate server state.

Server Administration is exposed through administrator-aware UI, primarily from Profile, while backend authorization remains the security boundary.

See:

- [Profile](profile.md)
- [Authentication](authentication.md)
- [Background Jobs](background-jobs.md)
- [Import / Export](import-export.md)
- [Metadata Sync](metadata-sync.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-005: Authentication Model](../decisions/005-authentication-model.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)

---

## Status

**Implemented / Evolving**

Implemented or established:

- administrator role support;
- centralized administrator backend dependency;
- administrator-aware Profile user model;
- admin-only Server Health endpoint;
- overall Server health status;
- checked-at timestamp;
- uptime;
- database health;
- database latency;
- TMDB health;
- TMDB configured state;
- TMDB latency;
- normalized frontend Server domain models;
- Server repository;
- `ServerHealthCubit`;
- isolated loading/success/failure states;
- Retry support;
- lazy administrator-only frontend loading design;
- no-secret health responses;
- background-job infrastructure;
- structured job execution history/results.

Planned or evolving:

- final Server section UI;
- backend/application version;
- environment information;
- storage diagnostics;
- TVDB health;
- richer database diagnostics;
- Background Jobs administration UI;
- sanitized Logs UI;
- Import/Export administration;
- Security settings;
- user administration;
- backup status/history;
- operational audit and production hardening.

See [Implementation Status](implementation-status.md).

---

# Goals

Server Administration should help an Administrator answer:

```text
Is SofaWatch healthy?
Is the database reachable?
Is storage healthy?
Are metadata providers working?
When was health last checked?
How long has the backend been running?
Which version is running?
Are background jobs succeeding?
Why did a job fail?
Are there relevant application errors?
Is registration open?
Are backups healthy?
```

It should provide enough information to operate a personal self-hosted server without exposing sensitive implementation details unnecessarily.

---

# Non-Goals

Server Administration is not:

- a generic Linux administration panel;
- a shell/terminal exposed through the browser;
- a database query console;
- a secret/configuration viewer;
- a replacement for external infrastructure monitoring;
- a way for normal users to inspect server internals.

SofaWatch should expose only operational information and actions that are useful for administering SofaWatch itself.

---

# Authorization

All Server Administration endpoints are administrator-only unless explicitly documented otherwise.

Conceptually:

```text
request
-> authenticate user
-> resolve current user
-> require Administrator
-> execute operation
```

The canonical administrator dependency should remain centralized.

---

# AdminUserDependency

The backend administrator dependency validates:

```text
current_user.is_admin
```

A normal authenticated user receives:

```text
403
code: admin_required
message: Administrator access is required.
```

Exact response structure follows the common API error contract.

---

# Frontend Authorization Awareness

Flutter uses:

```text
ProfileUser.isAdmin
```

to decide whether to expose Server Administration.

For non-admin users:

```text
admin UI
-> hidden

admin repositories
-> should not be called
```

This avoids unnecessary `403` requests.

Backend authorization remains mandatory regardless of frontend behavior.

---

# Lazy Administrator Loading

Administrator-specific Cubits should not be eagerly created for every Profile user.

Preferred flow:

```text
ProfileSuccess
     |
     v
user.isAdmin?
   /      \
 no        yes
 |          |
stop     create admin subtree
         load Server state
```

This is documented in [Profile](profile.md).

---

# Server Health

The current backend health endpoint is:

```text
GET /api/v1/server/health
```

It is protected by administrator authorization.

The response provides normalized operational status without secrets.

---

# Health Response

The current health model includes:

```text
ServerHealth
├── status
├── checkedAt
├── uptimeSeconds
├── database
└── tmdb
```

Future components can be added without changing the conceptual purpose of the endpoint.

---

# Overall Health Status

The overall Server status supports:

```text
healthy
degraded
unavailable
```

The backend owns the meaning of these states.

The frontend should not independently recompute overall health from component colors or labels.

---

# Healthy

`healthy` means the required components checked by the health service are functioning according to the current health policy.

This does not mean every optional external service in the entire deployment is perfect.

---

# Degraded

`degraded` means SofaWatch is operational but one or more checked components are unhealthy or unavailable.

Example:

```text
Database -> healthy
TMDB     -> unavailable

Overall -> degraded
```

Local features that rely only on persisted data can remain usable.

---

# Unavailable

`unavailable` is reserved for a state where the application/server health itself cannot be considered operational according to the backend health policy.

The exact threshold should remain centralized in the backend.

---

# Checked At

Health responses include the time at which the health snapshot was produced.

Conceptually:

```text
checked_at
```

This is important because:

```text
health status
```

without freshness context can be misleading.

Flutter formats the timestamp according to localization/timezone rules.

---

# Uptime

The backend exposes application uptime in normalized form:

```text
uptime_seconds
```

Flutter can format this as:

```text
3h 12m
2d 4h
```

The underlying API should remain numeric.

---

# Backend Version

A planned Server Administration field is the running SofaWatch backend/application version.

Example:

```text
SofaWatch 0.x.x
```

The value should come from one canonical application version source.

Do not maintain unrelated hard-coded version strings across endpoints and Flutter.

---

# Version Use Cases

Version information is useful for:

- confirming upgrades;
- bug reports;
- migration troubleshooting;
- support;
- checking client/server compatibility.

---

# Environment

A planned field can expose a safe environment label such as:

```text
development
production
```

Environment information must remain intentionally limited.

Do not expose:

- `.env` contents;
- filesystem paths;
- database URLs;
- credentials;
- API tokens;
- host secrets.

---

# Database Health

The current Server Health service checks database connectivity using a lightweight query such as:

```sql
SELECT 1
```

The result includes:

```text
status
latency_ms
```

This validates that the application can actually communicate with its database.

---

# Database Status

Database component status supports normalized values such as:

```text
healthy
unavailable
```

The health response should not expose raw SQL exceptions to the frontend.

Technical details belong in sanitized server logs.

---

# Database Latency

Latency provides a lightweight operational signal.

It is not intended as a complete SQLite performance benchmark.

A single health-check latency value should not be overinterpreted as application-wide performance.

---

# SQLite

SofaWatch intentionally uses SQLite for its self-hosted deployment model.

Server Administration should therefore focus on SQLite-relevant operational information rather than pretending SofaWatch requires a remote database server.

See:

- [Database Architecture](../architecture/database.md)
- [ADR-001: SQLite](../decisions/001-sqlite.md)

---

# Database Diagnostics

Future database diagnostics can include safe information such as:

```text
database reachable
database file size
migration state
schema revision
integrity-check status
last backup status
```

Each diagnostic should justify its cost.

Expensive checks should not run on every lightweight health request.

---

# SQLite Integrity Checks

A deeper diagnostic workflow may expose an explicit SQLite integrity check.

This should be:

- administrator initiated or appropriately scheduled;
- separated from the normal lightweight health endpoint;
- bounded and observable;
- reported using safe results.

Do not run expensive full integrity checks on every Profile render.

---

# Migration Status

Server Administration can eventually show whether the running database schema is at the expected Alembic revision.

Useful states might include:

```text
up to date
upgrade required
unknown/error
```

Migration execution itself should remain an explicit deployment/administration operation.

---

# Storage Diagnostics

Storage is important because SQLite, exports, backups, logs, and potentially cached/local assets consume disk space.

Future diagnostics can include:

```text
storage available
database size
backup storage size
free-space warning
```

---

# Storage Privacy

Storage diagnostics should expose useful aggregate values rather than arbitrary filesystem browsing.

Do not provide a Web file explorer over the host filesystem.

---

# Disk Space

A future disk-space diagnostic can help prevent failures caused by a full volume.

Possible safe values:

```text
total
used
available
usage percentage
```

The monitored path should be the SofaWatch data/storage location, not necessarily the entire host.

---

# Storage Thresholds

If warning thresholds are introduced, they should be configurable or centrally defined.

Example conceptual states:

```text
healthy
warning
critical
```

Avoid frontend-only threshold logic that disagrees with backend operational policy.

---

# TMDB Health

TMDB is currently SofaWatch's primary metadata provider.

The health response includes:

```text
status
configured
latency_ms
```

---

# TMDB Configured State

The Server UI should distinguish:

```text
TMDB not configured
```

from:

```text
TMDB configured but currently unavailable
```

These require different administrator actions.

---

# TMDB Health Check

The health service uses the TMDB client/provider's health behavior rather than embedding unrelated HTTP code directly in the route.

Conceptually:

```text
ServerHealthService
-> TMDB client/provider
-> lightweight provider check
```

This preserves layering and testability.

---

# TMDB Failure

A TMDB outage should normally produce:

```text
TMDB -> unavailable
Overall -> degraded
```

rather than implying the local SofaWatch database is unavailable.

Persisted local Library, History, and Statistics should remain usable where they do not require live metadata.

---

# TVDB Health

TVDB support is planned.

Once integrated, Server Administration can expose:

```text
configured
status
latency
```

using the same normalized operational model.

See [ADR-006: Provider Independence](../decisions/006-provider-independence.md).

---

# Provider Independence

Server Administration can identify providers by name, but operational architecture should not force the SofaWatch domain to depend on one provider.

Conceptually:

```text
Metadata Providers
├── TMDB
├── TVDB
└── future provider
```

Provider health remains a server/integration concern.

---

# External Ratings Provider

If IMDb or another legitimate ratings source is added, its operational state can eventually appear in provider diagnostics if live availability materially affects SofaWatch.

Do not add health checks merely because a provider exists.

Health checks should have operational value.

---

# Health Check Cost

The normal health endpoint should remain lightweight.

Avoid:

- downloading large provider datasets;
- full metadata synchronization;
- database integrity scans;
- backup creation;
- filesystem crawling.

Deep diagnostics should use explicit separate operations.

---

# Health Timeouts

External provider health checks require bounded timeouts.

A slow TMDB request should not cause the administrator health page to hang indefinitely.

Component failure should be represented safely.

---

# Partial Health Failures

Health is inherently componentized.

Example:

```text
Database -> healthy
TMDB     -> unavailable
TVDB     -> healthy
```

The response should preserve individual component states even when overall status is degraded.

---

# ServerHealthService

Operational health logic belongs in a service.

Conceptually:

```text
API Route
    |
    v
ServerHealthService
    |
    +-> Database check
    +-> TMDB check
    +-> future TVDB check
```

The route should remain thin.

---

# ServerHealthCubit

The frontend Server feature uses:

```text
ServerHealthCubit
```

with operations:

```text
load()
retry()
```

and states conceptually:

```text
Initial
Loading
Success(health)
Failure(error)
```

---

# Isolated Server State

Server Health failure should affect only the Server section.

Example:

```text
Profile identity -> success
Statistics       -> success
Library          -> success
History          -> success
Server Health    -> failure + Retry
```

This is expected behavior.

---

# Retry

Retry performs a fresh health request.

It should not reload unrelated Profile data.

---

# Refresh

A manual refresh action can be useful because health is time-sensitive.

The UI should make the new `checked_at` visible enough that the Administrator can understand the freshness of the result.

Avoid aggressive automatic polling unless there is a demonstrated need.

---

# Automatic Polling

The initial Server Administration experience does not require a constantly updating monitoring dashboard.

Manual refresh or modest refresh behavior is sufficient for a self-hosted application unless real usage demonstrates otherwise.

Continuous polling can:

- create unnecessary provider requests;
- add database work;
- increase mobile/network usage;
- create noisy logs.

---

# Background Jobs

Background Jobs are a major Server Administration area.

The job infrastructure tracks recurring server-side work independently from request/response flows.

See [Background Jobs](background-jobs.md).

---

# Job Overview

Administrator UI can expose:

```text
job name
status
schedule
last execution
last duration
next execution
last result
```

Exact fields should follow the background-job domain.

---

# Job Execution History

Each job can expose bounded execution history.

Useful information includes:

```text
started_at
finished_at
status
duration
error
structured result
```

---

# Structured Job Results

Job results should preserve meaningful machine-readable information.

For metadata synchronization, this can include counts such as:

```text
checked
refreshed
skipped
failed
```

This is more useful than a generic:

```text
Job completed
```

---

# Partial Job Failure

A job can complete with partial failures.

Example:

```text
50 Shows checked
42 refreshed
6 skipped
2 failed
```

The execution record should preserve this result.

A partial failure should not erase successful work.

---

# Manual Job Execution

Manual job execution is exposed as an administrator-only privileged operation.

For a normal execution:

```text
Run now
-> normal job handler
```

For jobs that explicitly support forced execution:

```text
Force refresh
-> force handler
```
Metadata Sync currently supports both modes.

---

# Forced Job Execution

Forced execution is opt-in per Background Job.
A job may define a separate forced handler.
If a job does not support forced execution:

```text
force=true
-> 400 background_job_force_not_supported
```

The request is rejected before execution state is persisted as running.

Forced execution must never silently fall back to normal execution.

---

# Duplicate Job Execution

The backend should prevent or explicitly define overlapping execution for jobs that must not run concurrently.

The frontend should also disable duplicate manual submission while the request is in flight.

Backend protection remains authoritative.

---

# Job Scheduler Health

Future operational diagnostics can indicate whether the worker/scheduler is functioning.

This is different from whether the FastAPI API process itself is healthy.

Conceptually:

```text
API healthy
Worker unavailable
-> degraded operational state
```

if the worker is required for expected background behavior.

---

# Worker Architecture

SofaWatch's background worker runs separately from normal API request handling.

Server Administration should therefore avoid assuming:

```text
API process alive
=
background jobs are running
```

Worker status requires its own observable signal if exposed.

---

# Logs

Application logs are useful for troubleshooting.

A future administrator Logs UI can expose sanitized, bounded application logs.

---

# Log Safety

Logs must never expose secrets.

At minimum, redact/avoid:

```text
passwords
password hashes
access credentials
refresh credentials
session cookies
handoff secrets
recovery secrets
TMDB tokens
TVDB tokens
database credentials
```

---

# Personal Data in Logs

Logs should also avoid unnecessarily recording full user viewing histories or sensitive account details.

Operational logging should contain enough context to debug without turning logs into a secondary personal-data database.

---

# Log Levels

Useful filtering can include:

```text
DEBUG
INFO
WARNING
ERROR
CRITICAL
```

Production defaults should avoid excessive debug logging.

---

# Log Components

Future filters can include logical components such as:

```text
API
Authentication
Database
TMDB
TVDB
Background Jobs
Metadata Sync
Import / Export
```

Exact component taxonomy should follow actual logging architecture.

---

# Log Pagination

A Web log viewer should use bounded pagination or incremental loading.

Never attempt to load an unlimited log history into Flutter.

---

# Log Download

If raw/sanitized log download is ever supported, it should be an explicit administrator action.

The generated artifact must follow the same secret-redaction policy as the UI.

---

# Import / Export

Server Administration can provide entry points to Import and Export operations.

See [Import / Export](import-export.md).

---

# Import Administration

Administrator-level imports may affect large amounts of application data.

The UI should expose:

- validation;
- progress where meaningful;
- result summary;
- partial failures;
- safe Retry/recovery guidance.

---

# Export Administration

Exports can be useful for:

- migration;
- backup adjuncts;
- user portability;
- diagnostics where appropriate.

An application export is not automatically equivalent to a full SQLite backup.

---

# Backups

Backup management is planned.

SQLite makes reliable backup strategy especially important because the database file is the core persistent store.

---

# Backup vs Export

These are distinct concepts.

```text
Backup
-> operational recovery of SofaWatch data/store

Export
-> portable/versioned application data
```

A JSON export may not preserve every database-level detail required for disaster recovery.

---

# Backup Status

Future Server Administration can show:

```text
last successful backup
last failed backup
next scheduled backup
backup destination status
backup size
```

Do not expose storage credentials.

---

# Backup History

Backup runs can use a history model similar to background jobs where appropriate.

Each run can record:

```text
started
finished
status
size
safe error summary
```

---

# Restore

Restore is a high-impact operation.

A future restore workflow should require:

- administrator authorization;
- explicit confirmation;
- compatibility validation;
- safe database replacement strategy;
- rollback/recovery planning;
- clear service interruption semantics.

Restore should never be a casual one-click action without context.

---

# Security Settings

Server Administration includes administrator-level Security settings.

The primary established setting is:

```text
Open registration
```

Default:

```text
off
```

See [Authentication](authentication.md).

---

# Open Registration

When disabled:

```text
public self-registration
-> rejected
```

When enabled:

```text
public self-registration
-> allowed according to backend policy
```

Only an Administrator can change this setting.

---

# Security Setting Persistence

Security settings must be persisted by the backend.

The frontend should not treat local UI state as authoritative.

A toggle mutation should:

```text
submit desired value
-> backend validates authorization
-> backend persists
-> response becomes authoritative state
```

---

# Security Mutation Failure

If changing a setting fails:

```text
backend state remains authoritative
```

The UI should reconcile the toggle rather than pretending the change succeeded.

---

# User Administration

Full user administration is planned.

Potential capabilities include:

```text
list users
view account status
activate/deactivate user
manage administrator role
revoke sessions
```

See [Authentication](authentication.md).

---

# User Privacy

Administrator capability should not automatically mean unrestricted browsing of another user's personal viewing History.

Operational account management and personal-content access are separate product/security decisions.

Default toward least privilege.

---

# Destructive Administration

Administrative mutations can have large effects.

Examples:

```text
deactivate user
revoke sessions
restore backup
run migration
delete data
```

Such operations should use:

- explicit labels;
- confirmation;
- targeted loading;
- backend authorization;
- safe result reporting.

---

# Observability vs Mutation

The UI should visually distinguish read-only operational information from actions.

For example:

```text
Database: Healthy
Latency: 2 ms
```

should not be visually confused with:

```text
Run integrity check
Restore backup
```

---

# No Shell Access

SofaWatch should not expose arbitrary shell-command execution through Server Administration.

This would dramatically expand the security boundary and is unnecessary for application administration.

Host-level administration remains outside SofaWatch.

---

# No Arbitrary SQL

Similarly, do not expose an arbitrary SQL console.

Database-specific maintenance should be implemented as narrow, reviewed operations if genuinely required.

---

# Secrets

Server Administration must never expose secret values merely to prove configuration exists.

Use:

```text
configured: true
```

rather than:

```text
token: abc123...
```

This applies to:

- TMDB;
- TVDB;
- external ratings providers;
- authentication secrets;
- email credentials;
- backup credentials.

---

# Configuration Diagnostics

A useful configuration diagnostic answers:

```text
Is this required integration configured?
```

not:

```text
What is the secret?
```

---

# Error Handling

Server Administration uses the common application error model.

Possible errors include:

- authentication required;
- administrator required;
- network;
- timeout;
- server unavailable;
- provider unavailable;
- database unavailable;
- invalid response;
- mutation conflict.

See [API Errors](../api/errors.md).

---

# Safe Errors

Frontend messages should be useful without exposing raw technical internals.

Example:

```text
Database health check failed.
```

instead of a full SQLAlchemy stack trace.

Detailed technical context belongs in sanitized logs.

---

# Component Errors

Where possible, component failures should remain component-specific.

Example:

```text
TMDB health failed
```

should not cause the database card to display an error if the database check succeeded.

---

# Production Failure Behavior

If the API itself is unreachable, Flutter cannot retrieve the health endpoint.

The UI should represent this as a connection/server failure rather than fabricating a component health response.

---

# Localization

Future localization should cover:

- Server;
- Healthy;
- Degraded;
- Unavailable;
- Configured;
- Not configured;
- Uptime;
- Checked at;
- Database;
- Metadata providers;
- Jobs;
- Logs;
- Security;
- Retry;
- confirmation dialogs;
- durations;
- dates;
- storage sizes.

Initial planned languages are English and Portuguese.

---

# Responsive Design

Server Administration must work on Web and mobile.

Mobile can use:

- stacked health cards;
- concise component rows;
- expandable details;
- full-width actions;
- bottom sheets where appropriate.

Desktop can use:

- multi-column status cards;
- denser job/log tables;
- dialogs for focused actions;
- constrained content width.

---

# Tables on Mobile

Do not force wide desktop tables into narrow mobile layouts.

For jobs/logs/users:

```text
desktop -> table/list with columns
mobile  -> cards or adaptive rows
```

Domain/application data remains shared.

---

# Accessibility

Final Server Administration validation should include:

- health status communicated with text, not color alone;
- semantic component names;
- accessible timestamps/durations;
- keyboard navigation;
- visible focus;
- accessible Retry;
- accessible toggles;
- confirmation focus management;
- screen-reader-friendly job/log summaries.

---

# Performance

Operational endpoints should be lightweight by default.

Avoid:

- expensive diagnostics on Profile load;
- frequent external-provider polling;
- unbounded logs;
- unbounded job history;
- filesystem scans;
- loading full database statistics unnecessarily.

Deep diagnostics should be explicit.

---

# Timeouts

Health checks and operational requests should use bounded timeouts.

A single external provider must not indefinitely block the entire Server page.

---

# Caching

Health data is time-sensitive.

Avoid long-lived client caching that makes stale health look current.

Short-lived reuse while navigating may be acceptable if `checked_at` remains visible.

---

# Database Query Efficiency

Job/log/user administration endpoints should use:

- bounded pagination;
- indexed ordering/filtering;
- no unnecessary N+1 queries.

Self-hosted does not mean performance concerns can be ignored.

---

# Testing

Backend tests should cover at least:

```text
admin Server Health access
non-admin Server Health -> 403
unauthenticated access
overall healthy
database failure
TMDB configured healthy
TMDB not configured
TMDB unavailable
overall degraded
checked_at
uptime
safe response without secrets
provider timeout
service exception mapping
```

Future backend tests should cover:

```text
TVDB health
storage diagnostics
migration status
job administration
manual job execution
overlap prevention
log authorization
log redaction
security settings
Open registration mutation
backup status
restore authorization
user administration
```

Frontend tests should cover at least:

```text
non-admin Server section hidden
non-admin repository never called
admin Server section visible
initial loading
health success
overall status
database status
TMDB status
not configured provider
failure
Retry
section failure isolation
responsive mobile
responsive desktop
```

Future frontend tests should cover:

```text
jobs
logs
security toggles
mutation failure reconciliation
user administration
backup status
restore confirmation
accessibility semantics
```

---

# Security Tests

Explicitly verify:

```text
non-admin cannot access admin endpoints
admin response contains no provider tokens
admin response contains no auth secrets
logs redact credentials
configuration diagnostics expose configured state only
security settings require admin
restore requires admin
user-role changes require admin
```

---

# Edge Cases

## Non-Admin Opens Profile

```text
Server Administration
-> not rendered
-> no Server repository request
```

## Database Healthy, TMDB Down

```text
Database -> healthy
TMDB -> unavailable
Overall -> degraded
```

## TMDB Not Configured

The UI should show configuration state distinctly from an outage.

## API Unreachable

No health response exists; Flutter shows a connection/server error.

## Worker Down, API Healthy

Future worker diagnostics can show degraded background-processing capability independently of API health.

## Job Partially Fails

Successful work and structured failure counts remain visible.

## Log Contains Secret-Like Field

Logging/redaction layer must prevent secret exposure.

## Disk Almost Full

Future storage diagnostics should warn without exposing arbitrary filesystem content.

## Security Toggle Request Fails

UI returns/reconciles to backend-authoritative value.

## Administrator Role Revoked

Backend immediately rejects future admin operations; frontend removes admin UI after authoritative user refresh.

---

# Future Work

## Server Overview

```text
[ ] final Server UI
[ ] backend/application version
[ ] environment
[ ] uptime formatting
[ ] checked-at refresh UX
[ ] component status presentation
```

---

## Database / Storage

```text
[ ] database file size
[ ] Alembic revision/status
[ ] optional integrity-check action
[ ] storage free-space diagnostics
[ ] storage warning thresholds
[ ] backup storage diagnostics
```

---

## Metadata Providers

```text
[ ] TVDB health
[ ] provider health abstraction review
[ ] external ratings provider health only if useful
[ ] provider-specific safe diagnostics
```

---

## Background Jobs

```text
[ ] jobs overview UI
[ ] execution history UI
[ ] structured result presentation
[ ] manual Run Now where appropriate
[x] Force refresh
[ ] overlapping-run protection
[ ] worker/scheduler health
```

---

## Logs

```text
[ ] sanitized log viewer
[ ] level filtering
[ ] component filtering
[ ] bounded pagination
[ ] refresh
[ ] optional sanitized download
[ ] credential-redaction audit
```

---

## Backups

```text
[ ] SQLite backup strategy
[ ] backup schedule
[ ] backup status
[ ] backup history
[ ] storage diagnostics
[ ] restore validation
[ ] restore confirmation
[ ] restore recovery strategy
```

---

## Security

```text
[ ] Open registration UI
[ ] security-settings persistence
[ ] session-management entry point
[ ] user administration
[ ] administrator role management
[ ] security-event visibility where useful
```

---

## Production Hardening

```text
[ ] reverse-proxy/HTTPS documentation
[ ] health-check timeout audit
[ ] secret-redaction audit
[ ] admin authorization audit
[ ] operational endpoint rate/cost audit
[ ] large-log/job-history performance audit
[ ] backup/restore disaster-recovery test
```

---

# Notes

> Server Administration is administrator-only.

> Frontend hiding improves UX; backend authorization provides security.

> Non-admin users should not make administrator API requests.

> Server Health is observability and should remain lightweight and read-only.

> Overall health is backend-defined.

> Component failures should remain individually visible.

> TMDB being unavailable does not mean SofaWatch's local database is unavailable.

> Provider configuration should be exposed as `configured/not configured`, never by revealing tokens.

> Expensive diagnostics should not run during every normal health request.

> Logs must be bounded and sanitized.

> SofaWatch should not expose arbitrary shell or SQL execution.

> Backup and Export are different concepts.

> Restore is a high-impact administrative operation requiring explicit safeguards.

> Profile remains the composition/entry surface; Server Administration owns operational behavior.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Profile](profile.md)
- [Authentication](authentication.md)
- [Background Jobs](background-jobs.md)
- [Import / Export](import-export.md)
- [Metadata Sync](metadata-sync.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Background Jobs Architecture](../architecture/background-jobs.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-001: SQLite](../decisions/001-sqlite.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-005: Authentication Model](../decisions/005-authentication-model.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)
