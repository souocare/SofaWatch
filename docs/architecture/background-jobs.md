# Background Jobs Architecture

This document describes the background job architecture used by SofaWatch.

Background jobs handle recurring server-side work independently from the FastAPI request lifecycle.

The current architecture targets a self-hosted installation with a single background worker.

---

## 1. Goals

The background job system is designed to provide:

- recurring server-side execution
- persistent job state
- execution history
- safe failure reporting
- structured job-specific results
- manual execution
- separation from HTTP request handling
- reuse of normal application services and repositories

It intentionally avoids requiring an external queue/broker for the current SofaWatch deployment model.

---

## 2. High-Level Architecture

```text
                 SofaWatch Backend
                        |
          ┌─────────────┴─────────────┐
          │                           │
          v                           v
     FastAPI API               Background Worker
                                      |
                                      v
                                  Scheduler
                                      |
                                      v
                                   Registry
                                      |
                                      v
                                  Executor
                                      |
                                      v
                                 Job Handler
                                      |
                         ┌────────────┼────────────┐
                         v            v            v
                     Services   Repositories   Providers
                                      |
                                      v
                                    SQLite
```

The worker is a separate process from FastAPI.

---

# 3. Why Jobs Are Separate from FastAPI

Long-running recurring work should not depend on Web requests.

Separating the worker provides:

- predictable request latency
- independent worker restart
- clearer failure boundaries
- no requirement for a user request to trigger scheduled work
- simpler operational reasoning

FastAPI should remain focused on HTTP request/response behavior.

---

# 4. Worker

The worker entry point starts the background scheduler.

Conceptually:

```text
python -m app.jobs.worker
        |
        v
configure logging
        |
        v
BackgroundJobScheduler
        |
        v
run_forever()
```

The worker should normally run in a separate terminal/process during development and as a separately supervised service in production.

---

# 5. Registry

The Registry defines which jobs exist.

The registry is the source of truth for available job definitions.

A registered job contains concepts such as:

- unique key
- display name
- human-readable schedule
- execution interval
- handler

Conceptually:

```text
Registry
 |
 +-- metadata_sync
 +-- future job
 +-- future job
```

The database stores runtime state for registered jobs, but job definitions belong to code.

---

# 6. Why the Registry Is Code-Defined

Job behavior is application code.

Keeping definitions in the registry ensures:

- handlers are explicit
- schedules are version-controlled
- unsupported arbitrary job names cannot appear simply through DB edits
- deployment behavior matches the running application version

Persisted job state complements the registry; it does not replace it.

---

# 7. Persistent Job State

`BackgroundJob` stores current state for each registered job.

Typical state includes:

- job key
- current status
- last execution
- next execution
- last result/error
- scheduling information required by the runtime

Conceptually:

```text
Registry Definition
       |
       v
Persisted BackgroundJob State
```

The scheduler reconciles the registered jobs with persisted state.

---

# 8. Execution History

Each execution creates a `BackgroundJobRun`.

Conceptually:

```text
BackgroundJob
   |
   +-- Run #1
   +-- Run #2
   +-- Run #3
```

A run may persist:

- start time
- finish time
- duration
- success/failure
- safe error
- structured result

This provides operational history rather than storing only the latest outcome.

---

# 9. Structured Results

The generic job infrastructure supports a structured result object.

This allows each job to expose useful metrics without coupling the scheduler/executor to that particular job.

For example, metadata synchronization can report:

```text
checked
refreshed
skipped
failed
```

Another future job could return a completely different result structure.

The generic infrastructure should treat the result as job-specific structured output.

---

# 10. Scheduler

The Scheduler periodically evaluates persisted job state.

Its responsibilities include:

- discovering registered jobs
- ensuring runtime state exists
- determining which jobs are due
- invoking the executor
- detecting stale/interrupted running state
- continuing the scheduling loop

Conceptually:

```text
Loop
 |
 v
Load registered jobs
 |
 v
Load persisted state
 |
 v
Due?
 |
 +-- no --> continue
 |
 +-- yes --> execute
```

---

# 11. Due-Time Calculation

The scheduler should calculate the next execution based on the registered interval and persisted state.

Scheduling must not depend on the frontend being open.

The frontend only displays/administers server-side job state.

---

# 12. Executor

The Executor owns the lifecycle of one job execution.

Conceptually:

```text
Executor
   |
   v
Mark job running
   |
   v
Create BackgroundJobRun
   |
   v
Execute handler
   |
   +-- success
   |      |
   |      v
   |   persist result
   |
   +-- failure
          |
          v
       persist safe error / partial result
   |
   v
Record duration
   |
   v
Calculate next run
```

This centralizes generic execution behavior.

Job handlers should not duplicate it.

---

# 13. Job Handler

A handler implements job-specific application work.

Handlers should reuse normal backend services and repositories.

Preferred direction:

```text
Scheduler / Manual Trigger
          |
          v
       Executor
          |
          v
      Job Handler
          |
          v
Application Services
```

Avoid implementing separate versions of business rules only for background execution.

---

# 14. Transactions

A background job may process one large operation or many independent items.

Transaction scope should match the product behavior.

For batch jobs, it may be desirable to commit successful items while recording failures for others.

For atomic jobs, the whole operation may need one transaction.

This choice belongs to the job/service design rather than to the generic scheduler.

---

# 15. Metadata Synchronization Job

The first registered recurring job is:

```text
metadata_sync
```

Its purpose is to keep locally imported TV metadata reasonably fresh.

The scheduled job runs on an eight-hour check interval.

This does not mean every Show is refreshed every eight hours.

The normal metadata freshness policy still applies.

---

# 16. Metadata Refresh Policy

Scheduled synchronization does not force every Show to refresh.

Conceptually:

```text
Worker wakes for metadata_sync
        |
        v
Check local Show
        |
        v
Refresh needed?
   /           \
 no             yes
 |               |
 v               v
skip          provider fetch
```

This avoids unnecessary provider traffic.

---

# 17. Ended / Canceled Shows

Ended and canceled Shows are excluded from automatic metadata refresh under the current policy.

They can still be refreshed manually.

Provider/status normalization should eventually centralize variants such as:

```text
Ended
Canceled
Cancelled
```

The background job should not maintain its own divergent status interpretation.

---

# 18. Per-Show Failure Isolation

One Show failing should not stop all remaining Shows from being processed.

Conceptually:

```text
Show A -> success
Show B -> failure
Show C -> success
Show D -> skipped
```

Processing continues after Show B.

This makes the synchronization useful even when one provider response or local item has a problem.

---

# 19. Overall Metadata Sync Result

A metadata sync run records counts such as:

```text
checked
refreshed
skipped
failed
```

If one or more individual Shows fail, the run can be marked failed while preserving the partial structured result.

Example:

```json
{
  "checked": 50,
  "refreshed": 8,
  "skipped": 41,
  "failed": 1
}
```

The exact schema belongs to the metadata-sync job rather than the generic scheduler.

---

# 20. Partial Failure Semantics

Partial success and overall status are separate concepts.

Example:

```text
48 items succeeded/skipped
2 items failed

Run status:
FAILED

Structured result:
preserved
```

This gives Administrators useful operational context rather than reducing the outcome to a boolean.

---

# 21. Error Storage

Persisted job errors must be safe.

Do not store:

- API tokens
- authentication credentials
- sensitive request headers
- passwords
- raw secrets

Errors should provide enough information to diagnose the failure without exposing protected data.

Detailed runtime traces can remain in server logs where appropriate.

---

# 22. Running Status

Before executing a handler, the job is marked running.

The current state allows the UI and scheduler to know that work is in progress.

Conceptually:

```text
idle
  |
  v
running
  |
  +--> success
  |
  +--> failed
```

---

# 23. Interrupted Workers

A worker process may terminate while a job is marked running.

Examples:

- process crash
- host restart
- manual kill
- power loss

The scheduler contains logic to detect jobs left in a stale running state and recover scheduling behavior.

A future improvement is to make stale timeout configurable per job.

---

# 24. Manual Run Now

Administrators can request a job to run manually.

Manual execution should reuse the same executor/handler path as scheduled execution.

Conceptually:

```text
Scheduled Trigger -----+
                       |
                       v
                    Executor
                       ^
                       |
Manual Run Now --------+
```

This prevents behavior drift.

---

# 25. Current Manual Execution Semantics

The current Run Now implementation is acceptable for the self-hosted single-worker scenario.

A future evolution may return:

```text
202 Accepted
```

and perform the execution asynchronously.

That improvement is not currently a blocker.

---

# 26. API

Administrator-facing background-job endpoints can expose:

- list jobs
- current status
- schedule
- last run
- next run
- duration
- latest structured result
- error information
- execution history
- Run Now

Endpoints are Administrator-only.

Frontend visibility does not replace backend authorization.

---

# 27. Frontend

The Profile/Admin UI can display Background Jobs independently from other server sections.

Possible UI state includes:

```text
Loading
Success
Failure
Retry
Running
```

A job failure should not break unrelated Profile/Server functionality.

---

# 28. Job Status Presentation

Useful fields include:

- display name
- schedule
- current status
- last execution
- next execution
- last duration
- structured result
- last error

The UI should avoid exposing raw internal exception details.

---

# 29. Checked / Refreshed / Skipped / Failed

Metadata synchronization currently exposes these concepts.

Future work should ensure their semantics are rigorous.

For example:

```text
checked
  = item evaluated by the synchronization workflow

refreshed
  = provider refresh actually applied

skipped
  = evaluated but intentionally not refreshed

failed
  = item attempted/evaluated and ended in failure
```

These definitions should remain stable once formalized.

---

# 30. GET Side Effects

Read-only endpoints should ideally not mutate job state.

If the current implementation reconciles/creates persisted job rows during a GET request, that behavior should eventually be reviewed.

Desired direction:

```text
GET
  -> observe state

Worker/startup/reconciliation
  -> mutate runtime registration state
```

This is a quality improvement, not a blocker for current use.

---

# 31. Single-Worker Assumption

The current architecture assumes one worker.

Under one worker:

```text
Scheduler
   |
   v
One executor path
```

This substantially reduces concurrent job-claim complexity.

The design should not add distributed queue infrastructure without a real need.

---

# 32. Multiple Workers

If SofaWatch ever supports multiple workers, atomic claiming will be required.

Without it:

```text
Worker A sees job due
Worker B sees job due
       |
       v
duplicate execution
```

Future design would need a database-backed atomic claim/lease/lock strategy.

This should only be implemented when multiple-worker deployment becomes a real requirement.

---

# 33. Provider Rate Limits

Background jobs must respect external-provider constraints.

A periodic job should not create unnecessary bursts of API traffic.

Useful mechanisms include:

- refresh-age policy
- skipping ineligible media
- provider timeouts
- bounded retry
- future provider-specific throttling if needed

Do not create endless automatic retry loops.

---

# 34. Provider Failures

Provider failures should be translated into job-level outcomes.

Examples:

- network error
- timeout
- provider unavailable
- malformed response
- rate limit

A failed secondary provider in future multi-provider sync may not need to invalidate successful primary-provider work.

This should be governed by provider/sync rules.

---

# 35. Scheduling and Clock Behavior

Job scheduling depends on server time.

Tests should avoid brittle dependence on the real wall clock.

Where date/time behavior becomes complex, inject or control clock/time sources in tests rather than relying on today's actual date.

---

# 36. Logging

The worker configures its own logging.

Useful log events include:

- worker startup
- job start
- job completion
- job failure
- duration
- safe summary metrics

Logs should not contain provider secrets or authentication credentials.

---

# 37. Persistence

Background-job persistence uses the same SQLite database as the application.

This allows:

- job state to survive worker restart
- execution history to survive API restart
- frontend/admin UI to observe worker state

The job system should not require the FastAPI process to hold in-memory scheduler truth.

---

# 38. Worker Deployment

Development:

```bash
python -m app.jobs.worker
```

Production should eventually run the worker as a separately supervised process/service.

Future operational documentation should cover:

- automatic restart
- logs
- graceful shutdown
- environment configuration
- upgrade ordering

---

# 39. Graceful Shutdown

A future production review should ensure that worker shutdown behavior is predictable.

Desired behavior:

- stop scheduling new jobs
- allow safe handler completion where reasonable
- avoid leaving ambiguous running state
- rely on stale-state recovery after hard termination

---

# 40. Adding a New Job

A new recurring job should normally require:

1. define a unique job key
2. define display/schedule metadata
3. implement a handler
4. register it
5. reuse application services/repositories
6. define structured result if useful
7. add scheduler/executor tests
8. add handler-specific tests
9. expose Admin UI only if useful

Avoid modifying generic scheduler code for job-specific metrics.

---

# 41. Job-Specific Result Design

A structured result should contain operationally meaningful summary information.

Good:

```json
{
  "checked": 100,
  "refreshed": 12,
  "skipped": 87,
  "failed": 1
}
```

Less useful:

```json
{
  "message": "done"
}
```

Do not put large raw provider responses into job-result storage.

---

# 42. Job Idempotency

Recurring handlers should be safe to run again where practical.

A repeated metadata sync should not create duplicate Shows, Seasons, Episodes, or provider mappings.

Idempotency is especially important after:

- worker restart
- manual Run Now
- scheduling recovery

---

# 43. Security

Background-job administration is privileged functionality.

Requirements:

- Administrator backend authorization
- no provider secrets in responses
- safe stored errors
- no arbitrary handler/key execution from user input
- registered jobs only

A Run Now endpoint should select from known registered jobs rather than execute arbitrary code.

---

# 44. Testing

Tests should cover generic infrastructure and individual handlers separately.

## Scheduler

Validate:

- job reconciliation
- due/not-due logic
- stale-running recovery
- next-run behavior

## Executor

Validate:

- running transition
- run creation
- success
- failure
- duration/result persistence
- partial result preservation
- next-run persistence

## Metadata Sync

Validate:

- refresh policy
- skipping
- per-item failure isolation
- counts
- overall failure when items fail
- manual vs automatic behavior

## API

Validate:

- Administrator authorization
- list/read behavior
- Run Now
- safe error contract

---

# 45. Anti-Patterns to Avoid

Avoid:

- running recurring work inside normal FastAPI requests
- duplicating service business rules in handlers
- job-specific logic inside the generic scheduler
- one item failure aborting a batch unnecessarily
- losing partial result counters after failure
- exposing raw exceptions/secrets
- using GET endpoints for substantial mutations
- assuming multi-worker safety when it does not exist
- adding Redis/Celery/queue infrastructure without a real requirement
- unbounded retries
- non-idempotent recurring handlers where avoidable

---

# 46. Future Work

Known improvements include:

- more rigorous result metrics
- remove undesirable GET side effects
- configurable stale timeout per job
- `202 Accepted` asynchronous Run Now
- atomic job claiming if multiple workers are ever supported
- production worker deployment documentation
- additional jobs only when real recurring work exists

---

## Related Documentation

- [Architecture Overview](overview.md)
- [Backend Architecture](backend.md)
- [Database Architecture](database.md)
- [Provider Architecture](provider-architecture.md)
- [Metadata Synchronization](../features/metadata-sync.md)
- [Implementation Status](../features/implementation-status.md)
