# Background Jobs

## Overview

Background Jobs provide SofaWatch with persistent server-side execution for work that should not depend on an active Web or mobile request.

They are used for recurring and potentially longer-running application tasks such as metadata synchronization.

Conceptually:

```text
FastAPI API
    |
    | creates/reads application state
    |
    v
SQLite

Background Worker
    |
    +-> discovers due jobs
    +-> executes job handlers
    +-> persists execution state/results
    +-> schedules next execution
```

The API and worker are separate runtime responsibilities.

A healthy API process does not automatically mean background processing is healthy.

See:

- [Background Jobs Architecture](../architecture/background-jobs.md)
- [Metadata Sync](metadata-sync.md)
- [Server Administration](server-administration.md)
- [Database Architecture](../architecture/database.md)
- [ADR-001: SQLite](../decisions/001-sqlite.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)

---

## Status

**Implemented / Evolving**

Implemented or established:

- persistent background-job model;
- separate worker process;
- recurring job scheduling;
- persisted schedule information;
- job status;
- last execution;
- execution duration;
- next execution;
- error information;
- execution history;
- structured execution results;
- TV metadata synchronization job;
- scheduler checks for metadata synchronization every eight hours;
- metadata refresh-policy integration;
- ended/canceled Show automatic-refresh exclusion;
- manual metadata refresh remaining possible;
- checked/refreshed/skipped/failed sync counters;
- partial-failure preservation;
- job results persisted even when individual items fail;
- administrator/server-management direction;
- manual `Run now` execution;
- optional forced execution handler per job;
- explicit forced execution through `force=true`;
- rejection of forced execution for unsupported jobs;
- duplicate/concurrent execution protection;
- administrator frontend controls for manual execution.

Planned/evolving:

- final Background Jobs administration UI;
- worker/scheduler health visibility;
- richer execution-detail presentation;
- overlap/concurrency hardening and validation;
- additional recurring jobs;
- backup jobs;
- cleanup/maintenance jobs where justified;
- notifications for operational failures;
- production worker deployment guidance.

See [Implementation Status](implementation-status.md).

---

# Goals

Background Jobs should provide:

- reliable recurring server-side work;
- persistence across client disconnections;
- observable execution state;
- execution history;
- meaningful structured results;
- bounded failure handling;
- safe retries;
- deterministic scheduling;
- administrator visibility;
- separation from HTTP request lifetimes.

---

# Non-Goals

Background Jobs are not:

- an excuse to move every operation out of HTTP;
- a distributed queue platform;
- an arbitrary shell-task runner;
- a replacement for business services;
- a client-side scheduler;
- a guarantee that every job must run at the exact scheduled second.

SofaWatch should keep the implementation proportionate to its self-hosted architecture.

---

# Why Background Jobs Exist

Some work should happen without requiring the user to keep SofaWatch open.

Example:

```text
metadata should be refreshed periodically
```

This should not require:

```text
user opens Show Details
-> frontend discovers stale data
-> frontend performs global synchronization
```

Instead:

```text
worker
-> identifies due metadata-sync job
-> applies backend refresh policy
-> persists results
```

---

# API vs Worker

The FastAPI process serves interactive application requests.

The worker handles scheduled background execution.

Conceptually:

```text
                 SQLite
                /      \
               /        \
          FastAPI      Worker
            |             |
        HTTP/API      Scheduled work
```

Both operate against the same canonical application data.

---

# Worker Startup

During development, the worker is run separately:

```bash
python -m app.jobs.worker
```

It should not depend on a Flutter client being active.

Production deployment should run the worker as its own managed process/service.

---

# Persistent Job State

Job definitions/state are persisted rather than existing only in process memory.

This allows SofaWatch to retain operational information such as:

```text
status
schedule
last execution
next execution
errors
history
```

across worker restarts.

---

# Job Definition

A background job conceptually has stable identity and scheduling information.

Potential normalized fields include:

```text
id / key
name
status
schedule
last_started_at
last_finished_at
last_duration
next_run_at
last_error
```

Exact fields should follow the current implementation.

---

# Stable Job Identity

Recurring system jobs should have stable identifiers.

For example:

```text
metadata_sync
```

or the current canonical key.

Worker startup should not create duplicate logical jobs on every process restart.

---

# Idempotent Registration

If system jobs are registered/seeded during startup, registration should be idempotent.

Conceptually:

```text
job already exists
-> update/reconcile definition if required
-> do not create duplicate row
```

---

# Scheduling

The worker determines when persisted jobs are due.

Conceptually:

```text
now >= next_run_at
-> job is due
```

The scheduler/worker then executes according to concurrency and state rules.

---

# Metadata Sync Schedule

The first scheduled SofaWatch job handles TV metadata synchronization.

The scheduler checks for metadata synchronization every:

```text
8 hours
```

This schedule represents the recurring job cadence/check behavior.

The metadata refresh policy still determines whether each individual Show actually requires refreshing.

---

# Schedule vs Refresh Policy

These are different concepts.

```text
Job schedule
-> when the metadata-sync job runs

Refresh policy
-> which Shows should actually be refreshed
```

Therefore:

```text
metadata-sync job runs
```

does not imply:

```text
every Show contacts TMDB
```

---

# Next Execution

Jobs persist or expose their next expected execution time.

This allows administrator UI to answer:

```text
When should this run again?
```

The value should be backend-derived.

---

# Scheduling After Restart

A worker restart should reconcile persisted scheduling state.

The system should deliberately define behavior for overdue jobs.

Possible policy:

```text
job overdue
-> execute on next worker scheduling cycle
```

rather than permanently skipping the missed run.

The exact policy should remain centralized and tested.

---

# Missed Runs

SofaWatch does not need to replay every missed interval independently.

Example:

```text
worker offline for 24h
8h job missed 3 theoretical runs
```

Running three identical metadata syncs immediately may provide no value.

A sensible self-hosted policy is usually:

```text
run once when due/overdue
-> calculate next schedule
```

unless a specific job requires historical catch-up semantics.

---

# Job Execution

A job execution is a distinct historical occurrence.

Conceptually:

```text
BackgroundJob
    |
    +-> Execution A
    +-> Execution B
    +-> Execution C
```

This allows administrators to inspect historical behavior rather than only the latest status.

---

# Execution History

Execution history can contain:

```text
started_at
finished_at
duration
status
error
structured result
```

The history should be bounded/paginated when exposed through the API/UI.

---

# Execution Status

Useful normalized execution states can include concepts such as:

```text
running
succeeded
failed
```

If partial success is represented as a distinct state, its semantics should be explicit.

Otherwise a completed run can preserve partial failures in its structured result.

Use the current backend enum/model as the canonical definition.

---

# Running State

Before executing the handler, the job/execution should be persisted as running according to the current transaction model.

This improves observability if the process crashes mid-run.

---

# Success

A successful execution records:

```text
finished_at
duration
successful status
structured result
next scheduling state
```

where applicable.

---

# Failure

A failed execution should preserve a safe operational error summary.

It should not lose the fact that the execution started.

Technical stack traces belong in server logs, not normal API responses.

---

# Partial Failure

Many jobs operate on multiple independent items.

Metadata synchronization is an example.

Conceptually:

```text
50 Shows checked
42 refreshed
6 skipped
2 failed
```

The two failures should not erase the 42 successful refreshes.

---

# Structured Results

Background Jobs persist structured execution results.

For metadata synchronization, this includes counts such as:

```text
checked
refreshed
skipped
failed
```

This is more useful than storing only:

```text
success
```

---

# Why Structured Results Matter

Structured results allow:

- administrator UI summaries;
- tests;
- future notifications;
- diagnostics;
- historical comparisons;
- partial-failure reporting.

They also avoid parsing arbitrary log text to understand job outcomes.

---

# Result Schema

Each job type can have a defined result shape.

Conceptually:

```text
MetadataSyncResult
├── checked
├── refreshed
├── skipped
└── failed
```

Generic job infrastructure can persist serialized structured results while job-specific application/domain code defines their meaning.

---

# Result Versioning

If persisted structured result schemas evolve significantly, backward compatibility should be considered.

Old execution history should not become unreadable merely because a new field was added.

Simple additive evolution is preferable where possible.

---

# Metadata Synchronization Job

The current recurring job synchronizes TV metadata.

Its responsibilities are described in detail in [Metadata Sync](metadata-sync.md).

At a high level:

```text
worker
-> metadata sync job
-> determine eligible Shows
-> apply refresh policy
-> refresh required Shows
-> persist metadata
-> record structured result
```

---

# Automatic Refresh Policy

Automatic metadata synchronization does not force every Show refresh.

It respects the metadata refresh policy.

This avoids unnecessary external-provider requests and database writes.

---

# Ended Shows

Ended TV Shows are excluded from automatic metadata refresh.

Conceptually:

```text
status = Ended
-> automatic sync skips
```

They remain available for explicit/manual refresh when needed.

---

# Canceled Shows

Canceled Shows follow the same automatic-refresh exclusion principle.

```text
status = Canceled
-> automatic sync skips
```

Manual refresh remains possible.

---

# Why Ended/Canceled Are Skipped

Their metadata is generally much less likely to change than active Shows.

Skipping them:

- reduces TMDB requests;
- reduces unnecessary writes;
- keeps scheduled synchronization efficient.

Manual refresh remains the escape hatch for corrections.

---

# Manual Refresh vs Scheduled Refresh

Manual metadata refresh and automatic background synchronization are related but not identical.

```text
Automatic
-> respects automatic refresh eligibility/policy

Manual
-> user explicitly requests refresh
-> may force/check content excluded from automatic refresh
```

See [Metadata Sync](metadata-sync.md).

---

# Provider Failure

TMDB can fail during a metadata-sync execution.

The job should isolate failures where possible.

Example:

```text
Show A -> success
Show B -> TMDB timeout
Show C -> success
```

Expected result:

```text
A persisted
B recorded failed
C persisted
run preserves partial result
```

---

# One Item Must Not Poison Entire Batch

When business correctness allows it, one Show failure should not stop synchronization of all remaining Shows.

Per-item failure handling is therefore important.

---

# Transaction Boundaries

Batch jobs should use transaction boundaries that match failure-isolation requirements.

A single giant transaction for every Show can cause:

```text
one failure
-> rollback all successful work
```

which conflicts with partial-success semantics.

The service/repository architecture should choose transactions deliberately.

---

# Retry Semantics

Retry behavior depends on the job.

A future/manual retry of metadata synchronization should re-evaluate current backend state and refresh policy rather than blindly replaying stale in-memory work.

---

# Idempotency

Background jobs should be designed so that rerunning them does not corrupt state.

Metadata synchronization should be effectively idempotent with respect to provider metadata updates.

Repeated execution can update the same internal media entities rather than creating duplicates.

---

# Internal Media IDs

Metadata synchronization updates existing SofaWatch entities using internal identity/provider mappings.

It must not create duplicate Shows merely because the same TMDB Show is encountered again.

See [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md).

---

# Concurrency

A recurring job should not accidentally execute overlapping copies when overlap would produce conflicting work.

Example:

```text
metadata sync still running
-> next scheduler cycle sees job
```

The backend should define whether:

- overlapping execution is prevented;
- execution is skipped;
- execution is queued.

For current self-hosted needs, preventing duplicate overlap is generally preferable for the same logical job.

---

# Backend Concurrency Protection

Frontend button disabling is not sufficient.

If manual execution is added, two clients could submit simultaneously.

The backend must enforce the job's concurrency policy.

---

# Crash Recovery

A worker can terminate while an execution is marked running.

On restart, the system should be able to identify stale running executions/jobs.

A future/current recovery policy can mark abandoned executions failed/interrupted after appropriate detection.

The job must not remain permanently stuck in `running`.

---

# Heartbeats

A full distributed heartbeat system may be unnecessary initially.

If worker-health or long-running-job recovery requires it later, add the minimum mechanism justified by actual needs.

Avoid overengineering a distributed queue architecture for a single self-hosted worker.

---

# Worker Health

Server Administration should eventually distinguish:

```text
API health
```

from:

```text
Worker/scheduler health
```

The worker can be unavailable while FastAPI still serves normal requests.

---

# Worker Last Seen

A simple future health mechanism can persist a bounded worker heartbeat/last-seen timestamp.

Conceptually:

```text
worker_last_seen_at
```

The Server feature can derive a safe worker status from backend-defined thresholds.

Only add this if it improves operational visibility.

---

# Manual Run

Administrator UI exposes `Run now` for supported Background Jobs.

A normal manual execution uses the job's normal handler and preserves the same business semantics as scheduled execution.

For Metadata Sync:

```text
Scheduled execution
-> normal handler

Run now
-> normal handler

Force refresh
-> force handler
```

---

# Manual Run Authorization

Manual execution requires administrator authorization.

Normal users should neither see the control nor be able to invoke the endpoint.

---

# Manual Run Loading

When an Administrator starts a job:

```text
request accepted/started
-> UI shows appropriate running state
```

Do not allow repeated button presses to create overlapping executions.

---

# Manual Run Confirmation

Confirmation depends on job cost/risk.

A lightweight metadata refresh may not need a heavy confirmation.

A future backup restore or expensive maintenance job does.

Use proportional UX.

---

# Manual vs Scheduled Result

Both manual and scheduled executions should use the same job handler/business service where possible.

Execution history can optionally record trigger source:

```text
scheduled
manual
```

if operationally useful.

---

# Administrator UI

Background Jobs belongs in administrator Server/Profile management.

A Jobs overview can display:

```text
Job
Status
Schedule
Last run
Duration
Next run
Last result
```

Desktop and mobile presentations can differ.

---

# Job Details

Selecting a job can show:

- description;
- schedule;
- current state;
- last execution;
- execution history;
- structured result;
- safe error information;
- manual action where allowed.

---

# Execution Detail

Metadata sync execution detail can present:

```text
Checked:   50
Refreshed: 42
Skipped:    6
Failed:     2
```

This should come from structured result data, not parsed logs.

---

# Error Detail

Normal UI should show a safe error summary.

Detailed stack traces remain in logs.

If per-item failures are persisted in the future, avoid returning enormous unbounded error payloads.

---

# History Pagination

Execution history grows over time.

API/UI should use bounded results.

Possible strategy:

```text
newest executions first
-> Load More / pagination
```

---

# History Retention

Long-term job execution retention should eventually be deliberate.

Options include:

- retain indefinitely for small self-hosted use;
- retain latest N executions;
- time-based cleanup.

Do not introduce cleanup until retention volume becomes meaningful.

---

# Cleanup Jobs

Future maintenance may itself use background jobs.

Examples:

```text
expired session cleanup
old execution-history cleanup
temporary-file cleanup
```

Only add jobs for real maintenance requirements.

---

# Backup Jobs

Scheduled SQLite backups are a natural future Background Jobs use case.

Conceptually:

```text
backup job
-> create safe SQLite backup
-> verify result
-> persist status/history
```

See [Server Administration](server-administration.md).

---

# Backup Concurrency

Backup operations must account for SQLite consistency.

Do not simply copy an actively changing database file using an unsafe method.

The backup implementation should use an SQLite-safe backup strategy.

---

# Notification Jobs

Future notifications may depend on background processing.

Potential notifications include:

- upcoming Episodes;
- new Seasons;
- failed jobs;
- administrative events.

Notification delivery should be separated from core job correctness.

A notification failure should not retroactively invalidate a successful metadata update.

---

# No Client Scheduling

Flutter should never be responsible for deciding when server jobs run.

Clients can:

- display schedules;
- request manual execution where authorized;
- refresh job state.

The backend/worker owns scheduling.

---

# Time and Timezones

Background schedules should use a consistent server-side time model.

Recurring technical jobs such as:

```text
every 8 hours
```

do not need to depend on the user's display timezone.

User-facing scheduled notifications may require timezone-aware semantics later.

---

# Deterministic Time

Scheduler tests should use controlled time.

Avoid tests that wait for real hours to pass.

Inject or isolate clock behavior where practical.

---

# Clock Drift

The scheduler should tolerate normal process timing drift.

An eight-hour job does not require millisecond precision.

Correctness and avoiding duplicate execution matter more than exact-second scheduling.

---

# Database Locking

Because SofaWatch uses SQLite, API and worker processes can contend for writes.

Background jobs should:

- keep write transactions appropriately scoped;
- avoid unnecessary long transactions;
- respect existing SQLite configuration;
- handle transient database failures safely.

See [Database Architecture](../architecture/database.md).

---

# SQLite and Multiple Processes

FastAPI and the worker are separate processes sharing the SQLite database.

The architecture should remain aware of SQLite's write-concurrency characteristics.

This is one reason to avoid unnecessary parallel worker execution.

---

# External Provider Rate Limits

Background synchronization should avoid unnecessary provider requests.

Refresh policy, ended/canceled exclusions, and bounded concurrency all help reduce pressure on TMDB/TVDB.

If provider rate-limit handling is added, it belongs in provider/service infrastructure rather than Flutter.

---

# Provider Timeouts

Every external request used by a job should have a bounded timeout.

One hanging provider request must not indefinitely block the worker.

---

# Backoff

For transient provider failures, future retry/backoff can be considered.

Avoid aggressive immediate retry loops that amplify an external outage.

Batch-level scheduled reruns already provide natural later recovery.

---

# Failure Classification

Where useful, job internals can distinguish:

```text
timeout
provider unavailable
invalid provider response
database failure
unexpected internal failure
```

The administrator-facing API should still use safe normalized information.

---

# Logs

Background Jobs should emit operational logs with enough context to diagnose execution.

Useful context can include:

```text
job key
execution id
start/end
summary counts
safe failure category
```

Never log secrets.

---

# Correlation

An execution ID can help correlate:

```text
job history
```

with:

```text
application logs
```

without exposing private credentials or relying on timestamps alone.

---

# Security

Only trusted backend job handlers should be executable.

Do not allow a client to submit:

```text
command
module path
Python expression
shell script
```

as an arbitrary job definition.

---

# Fixed Job Registry

System jobs should come from a controlled application registry/configuration.

Administrator UI can invoke supported jobs but should not dynamically execute arbitrary code.

---

# Configuration

Job schedules and worker behavior should have explicit configuration where appropriate.

Configuration should remain simple.

Do not expose internal configuration secrets through the Jobs API.

---

# Deployment

Production deployment must run:

```text
FastAPI
+
Background Worker
```

as independently managed processes.

A process supervisor/container/orchestration environment should restart failed processes according to deployment guidance.

---

# Graceful Shutdown

The worker should handle normal shutdown signals sensibly.

If possible:

```text
stop accepting new work
-> finish or safely interrupt current work
-> persist coherent state
-> exit
```

Exact behavior depends on job duration and current implementation.

---

# Startup Reconciliation

Worker startup can perform lightweight reconciliation such as:

- ensure system jobs exist;
- identify due jobs;
- recover clearly stale execution state if supported.

Avoid expensive full application synchronization merely because the worker restarted.

---

# Error Handling

Background Jobs use backend error handling appropriate to non-interactive execution.

A job failure is persisted and logged.

It is not dependent on returning an HTTP error to a waiting client.

Manual-run API errors remain separate from execution-result failures.

---

# Manual Request vs Execution Failure

These are distinct:

```text
POST Run Now
-> request rejected before job starts
```

versus:

```text
POST Run Now
-> job starts
-> execution later fails
```

The UI/API should not conflate them.

---

# Observability

A useful job system should answer:

```text
What jobs exist?
What is due?
What is running?
When did it last run?
Did it succeed?
How long did it take?
What did it do?
What failed?
When will it run again?
```

The persisted model and admin UI should support these questions without requiring direct database inspection.

---

# Performance

Background jobs should avoid unnecessary resource usage.

Important considerations:

- bounded batches;
- efficient eligibility queries;
- no N+1 provider/database access where avoidable;
- limited parallelism;
- short write transactions;
- bounded execution history queries.

Measure before adding complex optimization.

---

# Testing

Backend tests should cover at least:

```text
job registration
idempotent registration
due-job detection
not-due job skipped
next-run calculation
execution starts
execution success
execution failure
duration persistence
error persistence
structured result persistence
execution history ordering
metadata sync scheduled execution
8-hour scheduling behavior
refresh-policy respect
ended Show skipped
canceled Show skipped
manual refresh remains possible
partial metadata failures
checked/refreshed/skipped/failed counts
user/provider failure isolation
```

Concurrency/reliability tests should cover:

```text
same job cannot overlap when prohibited
duplicate manual run protection
worker restart with due job
overdue job behavior
stale running execution recovery where implemented
database contention handling
provider timeout
```

Frontend tests should cover future Jobs UI:

```text
admin-only visibility
non-admin no request
jobs loading
jobs success
jobs failure
Retry
job details
execution history
structured results
partial failure presentation
Run Now loading
Run Now failure
running state
responsive layout
```

---

# Edge Cases

## Worker Offline for More Than Eight Hours

On restart, the due metadata job should follow the overdue-job policy rather than being forgotten.

## Worker Offline for Several Intervals

SofaWatch generally should not run multiple identical catch-up syncs back-to-back unless the job explicitly requires interval replay.

## TMDB Down

The execution records failures safely and future scheduled runs can recover.

## One Show Fails

Other eligible Shows continue where failure isolation permits.

## Show Ends Between Runs

Next automatic sync applies the current refresh policy and can skip it.

## Ended Show Needs Correction

Administrator/user manual refresh remains available.

## Worker Crashes Mid-Execution

Persisted running state allows later reconciliation rather than pretending the run succeeded.

## Manual Run While Scheduled Run Active

Backend concurrency policy prevents inappropriate duplicate overlap.

## API Healthy, Worker Down

Normal API usage may continue while scheduled work is degraded.

## Structured Result Has Old Schema

Historical UI should tolerate compatible older result records.

---

# Future Work

## Administration UI

```text
[ ] jobs overview
[ ] job details
[ ] execution history
[ ] structured-result cards
[ ] safe error presentation
[x] manual Run Now
[x] forced execution where supported
[x] force confirmation for expensive operations
[ ] local Retry/refresh
[ ] mobile layout
[ ] desktop layout
```

---

## Worker Health

```text
[ ] define worker-health signal
[ ] last-seen/heartbeat only if needed
[ ] expose worker state in Server Administration
[ ] distinguish API health from worker health
```

---

## Concurrency / Recovery

```text
[ ] final overlap policy per job
[ ] backend locking/claim strategy
[ ] stale-running recovery
[ ] crash-recovery tests
[ ] duplicate manual-run tests
```

---

## Additional Jobs

Potential future jobs:

```text
[ ] SQLite backups
[ ] expired-session cleanup
[ ] old temporary-file cleanup
[ ] execution-history cleanup if needed
[ ] notification processing
[ ] future provider synchronization
```

Add only when there is a real application requirement.

---

## Notifications

```text
[ ] job-failure notifications
[ ] administrative event notifications
[ ] upcoming Episode notifications
[ ] new Season notifications
[ ] independent notification failure handling
```

---

## Production Deployment

```text
[ ] worker service documentation
[ ] restart policy
[ ] graceful shutdown validation
[ ] SQLite API/worker contention test
[ ] log rotation
[ ] operational health checks
```

---

# Notes

> Background Jobs are backend-owned and do not depend on a Flutter client being open.

> The FastAPI API and Background Worker are separate runtime responsibilities.

> Persistent job state makes schedules and execution history survive process restarts.

> The metadata synchronization job runs on an eight-hour schedule/check cadence.

> A scheduled metadata-sync run does not force every Show to refresh.

> Automatic synchronization respects the metadata refresh policy.

> Ended and canceled Shows are excluded from automatic metadata refresh but remain manually refreshable.

> Repeated synchronization should not create duplicate media entities.

> One item failure should not erase successful work when partial-success semantics apply.

> Structured results are persisted so execution history can explain what a job actually did.

> Same-job overlap should be prevented where concurrent execution is unsafe or pointless.

> SQLite's write-concurrency characteristics should be considered when API and worker processes operate simultaneously.

> Administrator UI may trigger supported jobs, but must never become an arbitrary code/shell runner.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Metadata Sync](metadata-sync.md)
- [Server Administration](server-administration.md)
- [Profile](profile.md)
- [Authentication](authentication.md)
- [Import / Export](import-export.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Background Jobs Architecture](../architecture/background-jobs.md)
- [Data Flow](../architecture/data-flow.md)
- [Development Setup](../development/setup.md)
- [Testing](../development/testing.md)
- [API Errors](../api/errors.md)
- [ADR-001: SQLite](../decisions/001-sqlite.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-003: Internal Media IDs](../decisions/003-internal-media-ids.md)
- [ADR-006: Provider Independence](../decisions/006-provider-independence.md)
