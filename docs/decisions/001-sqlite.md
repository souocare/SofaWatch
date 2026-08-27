# ADR-001: SQLite as the Primary Database

- Status: Accepted
- Date: 2026-08-27

## Context

SofaWatch is designed primarily as a self-hosted application for personal and small multi-user deployments.

The application persists data such as:

- users and authentication state;
- TV shows, seasons, and episodes;
- movies;
- Library entries;
- viewing progress;
- Episode and Movie watch events;
- ratings;
- metadata synchronization state;
- background jobs and execution history;
- application settings and administrative state.

A database is therefore a core part of every SofaWatch installation.

The database choice affects not only backend implementation, but also:

- installation complexity;
- upgrades;
- backups;
- restores;
- deployment;
- operational maintenance;
- data portability;
- resource usage;
- the experience of running SofaWatch on small self-hosted servers.

During development it would be easy to treat SQLite as a temporary development database and assume that a server database such as PostgreSQL should eventually replace it.

That is not the current SofaWatch product direction.

SofaWatch needs a database strategy aligned with the actual deployment model rather than with the architecture of much larger hosted services.

---

## Decision

SofaWatch uses **SQLite as its primary and intended database**.

SQLite is not considered a temporary development-only database.

The production/self-hosted architecture is designed around SQLite unless future evidence demonstrates that the deployment requirements have materially changed.

Schema evolution is managed through Alembic migrations.

Database access is implemented through SQLAlchemy rather than coupling application services directly to raw SQLite queries.

SQLite foreign-key enforcement is explicitly enabled using:

```sql
PRAGMA foreign_keys=ON;
```

The project does not currently maintain a PostgreSQL migration roadmap.

---

## Rationale

### Self-Hosted Deployment

SofaWatch is intended to be straightforward to deploy and operate.

SQLite allows the database to exist as part of the SofaWatch data directory without requiring users to install, configure, secure, upgrade, and back up a separate database server.

Conceptually:

```text
SofaWatch
├── application
├── SQLite database
├── cached/application data
└── configuration
```

rather than:

```text
SofaWatch
├── application
├── database connection configuration
└── external database server
    ├── users
    ├── passwords
    ├── networking
    ├── permissions
    ├── upgrades
    └── independent backups
```

For the intended deployment model, the first structure is substantially easier to operate.

---

### Operational Simplicity

A self-hosted media tracker should not require database administration knowledge merely to run the application.

SQLite removes several operational requirements associated with a separate database service:

- database server installation;
- service management;
- network connectivity;
- database user provisioning;
- database port exposure;
- server-specific configuration;
- independent database service monitoring.

This reduces both installation friction and the number of components that can fail.

---

### Appropriate Scale

SofaWatch is not currently designed as a large public SaaS service serving thousands of simultaneous writers.

The expected deployment is closer to:

```text
one household / personal server
+
small number of users
+
one backend instance
+
one background worker
```

The workload primarily consists of:

- metadata reads;
- Library queries;
- progress updates;
- individual viewing events;
- periodic metadata synchronization;
- administrative operations.

SQLite is appropriate for this expected workload.

---

### Resource Efficiency

SofaWatch should be able to run on modest self-hosted hardware.

A separate database server consumes additional:

- memory;
- CPU;
- disk;
- operational attention.

SQLite has a much smaller operational footprint.

That is valuable for installations on:

- mini PCs;
- home servers;
- NAS-like environments;
- virtual machines;
- containers;
- other resource-conscious self-hosting setups.

---

### Data Portability

A SQLite database is naturally portable as a file-backed database.

This can simplify future workflows around:

- backup;
- restore;
- migration between servers;
- disaster recovery;
- development copies.

Portability does not remove the need for a proper backup strategy, but it provides a useful foundation for one.

---

### Development and Production Consistency

Using SQLite intentionally in production avoids a common mismatch where development uses one database while production uses another.

That reduces the risk of differences in:

- SQL behavior;
- constraints;
- transaction semantics;
- migrations;
- type handling.

SofaWatch tests and development therefore exercise the same database family intended for deployment.

---

## SQLAlchemy Boundary

Choosing SQLite does not mean application business logic should depend directly on SQLite-specific implementation details.

The intended backend flow remains:

```text
API / Routes
     |
     v
Services
     |
     v
Repositories
     |
     v
SQLAlchemy
     |
     v
SQLite
```

Business logic should remain in services/domain-oriented application code rather than being embedded in database-specific SQL wherever practical.

This separation preserves maintainability even if the database decision is revisited in the future.

---

## Alembic Migrations

Schema evolution is managed through Alembic.

A normal installation upgrade follows the migration chain rather than recreating the database.

Conceptually:

```text
existing SofaWatch DB
        |
        v
Alembic revisions
        |
        v
current schema
```

Before important releases, the migration chain should be checked with commands such as:

```bash
alembic current
```

and:

```bash
alembic check
```

where appropriate.

Migration correctness is part of release quality.

---

## Existing Database Upgrades

Testing only databases created from the latest schema is insufficient.

Before stable upgrade compatibility is considered complete, SofaWatch should also test:

```text
older SofaWatch database snapshot
        |
        v
alembic upgrade head
        |
        v
current application
```

and verify preservation of user-owned data such as:

- user identity;
- Library;
- Episode progress;
- Episode watch history;
- Movie watch history;
- ratings;
- related persisted state.

This is especially important as the project moves toward stable releases.

---

## Foreign Keys

SQLite foreign-key enforcement is not assumed implicitly.

SofaWatch explicitly enables:

```sql
PRAGMA foreign_keys=ON;
```

for database connections.

This is required so relational constraints behave as intended.

Foreign-key behavior should remain covered by database/integration testing.

---

## Concurrency Model

SQLite supports multiple readers but has more constrained concurrent write behavior than client/server databases.

This is accepted because the current SofaWatch deployment model does not require high-volume concurrent writes.

Typical write operations are relatively small:

```text
mark Episode watched
add Movie to Library
update account
store job execution
sync metadata
```

The application should still:

- keep transactions appropriately scoped;
- avoid unnecessarily long write transactions;
- handle database failures correctly;
- avoid holding locks while performing slow external-provider requests.

---

## Background Worker

SofaWatch includes a separate background worker.

The worker and API may both interact with the same SQLite database.

This makes transaction discipline important.

Background jobs should avoid unnecessarily long database write locks and should not wrap slow external API operations in long-lived write transactions without reason.

The current single-worker self-hosted model is compatible with this approach.

---

## WAL

SQLite Write-Ahead Logging may be used/configured where appropriate for the SofaWatch runtime model.

WAL can improve the interaction between readers and writers.

However, WAL also affects backup and operational behavior because a live SQLite installation may involve files such as:

```text
sofawatch.db
sofawatch.db-wal
sofawatch.db-shm
```

A future backup implementation must account for SQLite's consistency requirements rather than blindly copying only the main database file while writes are occurring.

The exact backup implementation is deliberately deferred until the backup feature is designed.

---

## Backup Implications

SQLite simplifies the number of components involved in backup, but a safe backup is not equivalent to:

```text
cp live-database.db backup.db
```

under all runtime conditions.

The future backup strategy should use a SQLite-safe mechanism such as an appropriate SQLite backup operation, controlled application procedure, or another consistency-preserving method.

The backup feature should eventually define:

- backup creation;
- retention;
- backup destination;
- verification;
- restore;
- interaction with WAL;
- upgrade/migration behavior;
- administrative status reporting.

Until that feature exists, Server diagnostics should not claim a backup status that SofaWatch does not actually manage.

---

## Integrity

Database diagnostics may use SQLite capabilities to inspect health.

Examples include:

```text
connectivity
integrity check
foreign-key check
database size
WAL size
Alembic revision
```

These diagnostics are useful precisely because SQLite is part of the self-contained SofaWatch deployment.

They should not expose sensitive application data.

---

## Consequences

### Positive

#### Simpler Installation

Users do not need to provision a database server.

#### Lower Operational Burden

There is one fewer long-running service to configure, monitor, secure, and upgrade.

#### Lower Resource Usage

SQLite fits well with resource-conscious self-hosted deployments.

#### Easier Portability

The database can be moved as part of a controlled SofaWatch data migration.

#### Development Consistency

Development, testing, and intended production use the same database family.

#### Straightforward Self-Hosting Story

SQLite aligns with SofaWatch's goal of being practical to run on personal infrastructure.

---

### Trade-offs

#### Write Concurrency

SQLite is not designed for the same high-volume concurrent-write workloads as server databases.

SofaWatch accepts this limitation for its intended scale.

#### Multi-Instance Scaling

Running many API replicas and workers concurrently against one SQLite database is not the target architecture.

If SofaWatch eventually requires horizontal scaling, this decision may need to be revisited.

#### Backup Requires SQLite Awareness

The database being file-backed does not make every filesystem copy automatically safe.

Backup/restore must account for transactions and WAL.

#### Operational Discipline Still Matters

SQLite reduces operational complexity but does not eliminate:

- migrations;
- backups;
- integrity checks;
- disk-space management;
- recovery planning.

---

## Alternatives Considered

### PostgreSQL

PostgreSQL would provide:

- stronger high-concurrency characteristics;
- mature client/server operational tooling;
- easier horizontal application scaling;
- capabilities useful for large multi-user hosted services.

However, it would also introduce:

- another service to install;
- another service to configure;
- credentials and connection management;
- additional memory/resource usage;
- independent backup/restore procedures;
- greater self-hosting complexity.

These costs do not currently provide enough benefit for SofaWatch's intended deployment model.

PostgreSQL is therefore **not part of the current roadmap**.

---

### Supporting SQLite and PostgreSQL Simultaneously

Supporting multiple database engines could appear flexible, but it would increase maintenance significantly.

It would require testing:

- migrations on both engines;
- query behavior on both engines;
- constraints on both engines;
- transaction behavior on both engines;
- production upgrades on both engines.

SofaWatch does not currently have a product requirement that justifies that complexity.

Database portability should not be pursued merely as theoretical flexibility.

---

### Embedded Alternatives

Other embedded databases could provide some similar operational advantages.

SQLite was selected because it is:

- mature;
- widely supported;
- well understood;
- integrated effectively with SQLAlchemy;
- appropriate for the required relational model;
- backed by strong tooling and ecosystem support.

There is currently no concrete benefit that justifies replacing it with another embedded database.

---

## Rejected Assumption: SQLite Is Only for Development

The following assumption is explicitly rejected:

```text
"Use SQLite now and migrate to PostgreSQL before production."
```

For SofaWatch:

```text
SQLite
```

is itself the intended production database for the current self-hosted architecture.

A database migration should happen only because requirements change, not because production software is assumed to require PostgreSQL by default.

---

## Revisit When

This decision should be reconsidered if real SofaWatch requirements evolve substantially.

Examples include:

### High Write Concurrency

If real deployments regularly produce enough simultaneous writes that SQLite locking becomes a demonstrated operational problem.

### Horizontal Scaling

If SofaWatch needs:

```text
multiple API replicas
+
multiple workers
+
shared database
```

as a normal supported deployment.

### Large Hosted Service

If SofaWatch evolves from primarily self-hosted software into a centrally hosted multi-tenant service with substantially different scale requirements.

### Database-Specific Missing Capability

If an essential future feature requires database functionality that SQLite cannot reasonably provide.

### Proven Reliability Problem

If production evidence demonstrates that SQLite itself is preventing SofaWatch from meeting its reliability requirements.

A vague expectation that the application "might grow" is not sufficient reason to revisit the decision.

---

## If the Decision Changes

A future migration away from SQLite would require a new ADR.

That ADR should define:

- the new database;
- why current requirements invalidate ADR-001;
- data migration strategy;
- Alembic implications;
- backup/restore changes;
- deployment changes;
- upgrade compatibility;
- whether SQLite remains supported;
- testing requirements.

ADR-001 would then be marked:

```text
Status: Superseded by ADR-XXX
```

rather than deleted.

---

## Implementation Constraints

Code written under this decision should follow these rules:

```text
[ ] SQLite remains a supported first-class production database
[ ] migrations must work against SQLite
[ ] schema design must account for SQLite behavior
[ ] foreign keys remain explicitly enabled
[ ] long write transactions should be avoided
[ ] external provider calls should not unnecessarily hold DB write locks
[ ] backup design must be SQLite-safe
[ ] database diagnostics may use SQLite-specific capabilities intentionally
[ ] PostgreSQL-specific infrastructure must not be introduced without a new decision
[ ] abstractions should not be added solely to pretend multiple database engines are supported
```

---

## Relationship to Other Decisions

### Backend as Source of Truth

[ADR-002](002-backend-source-of-truth.md) means clients interact with persisted state through the SofaWatch backend rather than opening the SQLite database directly.

### Internal Media IDs

[ADR-003](003-internal-media-ids.md) means database identity belongs to SofaWatch rather than being inherited from metadata providers.

### Provider Independence

[ADR-006](006-provider-independence.md) keeps external metadata concerns separate from persisted domain identity and business rules.

---

## Related Documentation

- [Documentation Index](../README.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Migrations](../development/migrations.md)
- [Setup](../development/setup.md)
- [Configuration](../development/configuration.md)
- [Testing](../development/testing.md)
- [Implementation Status](../features/implementation-status.md)
