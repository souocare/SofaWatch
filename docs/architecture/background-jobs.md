# Background Jobs

SofaWatch includes a generic background job system for recurring server-side tasks.

The system is intentionally separate from the FastAPI request lifecycle.

## Components

### Registry

The registry defines which jobs exist and their schedules.

A job definition contains:

- a unique key;
- display name;
- human-readable schedule;
- execution interval;
- handler.

The registry is the source of truth for available jobs.

### Scheduler

The scheduler periodically checks persisted job state and determines which registered jobs are due.

It also detects jobs that were left in a running state after an interrupted worker process.

### Executor

The executor is responsible for:

- marking a job as running;
- creating execution history;
- executing the handler;
- measuring execution duration;
- recording success or failure;
- persisting structured handler results when available;
- preserving structured partial results from failed handlers when exposed by the error;
- storing the next execution time.

### Persistence

`background_jobs` stores the current state of each job.

`background_job_runs` stores execution history.

Each run can also store a generic structured `result` object.

This allows individual jobs to expose job-specific execution metrics without coupling the generic background job infrastructure to a particular task.

This allows the frontend to show information such as:

- schedule;
- current health;
- last run;
- duration;
- next run;
- structured execution result;
- last error.


## Metadata synchronization

The first registered background job is `metadata_sync`.

It checks all locally stored TV series every eight hours.

The scheduled synchronization uses the normal refresh policy and does not force metadata updates.

Ended and canceled series are skipped during automatic metadata refreshes, but they can still be refreshed manually.

Individual show failures do not prevent remaining shows from being processed.

If one or more shows fail, the overall job execution is marked as failed.

A metadata synchronization run records:
- checked shows;
- refreshed shows;
- skipped shows;
- failed shows.

The result is stored on the corresponding background job run.
If individual shows fail, processing continues for the remaining shows. The final run is marked as failed when at least one show fails, while the partial synchronization counters are still preserved.