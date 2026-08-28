# Profile

## Overview

Profile is SofaWatch's user and application-management hub.

It brings together user identity, personal summaries, navigation to user-owned data, application preferences, and — for administrators — server and security functionality.

Profile should remain a composition surface rather than becoming the owner of every feature it exposes.

Conceptually:

```text
Profile
├── User identity
├── Statistics
├── Library
├── History
├── Application
└── Administrator-only
    ├── Server
    ├── Background Jobs
    ├── Logs
    ├── Import / Export
    └── Security
```

Each section should reuse the relevant feature's application/domain layer.

See:

- [Statistics](statistics.md)
- [Library](library.md)
- [History](history.md)
- [Authentication](authentication.md)
- [Server Administration](server-administration.md)
- [Import / Export](import-export.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-005: Authentication Model](../decisions/005-authentication-model.md)

---

## Status

**Implemented / Evolving**

Implemented or established:

- Profile page;
- authenticated user identity;
- display name;
- local-user information;
- administrator flag;
- Statistics summary;
- Library preview;
- History preview;
- navigation to richer feature experiences;
- administrator-aware UI behavior;
- server-health frontend domain/data/application layer;
- administrator-only server-health endpoint;
- lazy administrator Server section design;
- isolated section loading/error behavior;
- Application/Server management direction;
- Import / Export direction;
- Security settings direction.

The Profile page currently composes independent Cubits for major user-facing sections, including:

```text
ProfileCubit
StatisticsSummaryCubit
LibraryPreviewCubit
HistoryPreviewCubit
```

Administrator-only server state is intentionally designed to be created lazily only for administrators.

Future work includes final Server UI integration, broader administrator controls, user management, localization/preferences, Import/Export UI, Security settings, session management surfaces, and final responsive/accessibility validation.

See [Implementation Status](implementation-status.md).

---

# Goals

Profile should allow a user to:

- identify the currently authenticated account;
- access personal Statistics;
- preview and navigate to Library content;
- preview and navigate to History;
- manage application/account preferences;
- access Import/Export where permitted;
- manage authentication/session settings;
- access administrator functionality when authorized.

For administrators, Profile also acts as the entry point for operational management of the self-hosted SofaWatch server.

---

# Non-Goals

Profile is not:

- the full Statistics feature;
- the full Library;
- the full History timeline;
- a replacement for Home;
- a server monitoring dashboard for non-administrators;
- the owner of authentication business logic;
- the owner of background-job execution logic.

It coordinates and presents these features.

---

# Composition Principle

Profile should reuse existing feature boundaries.

Conceptually:

```text
Statistics domain/application
        |
        v
Profile Statistics preview

Library domain/application
        |
        v
Profile Library preview

History domain/application
        |
        v
Profile History preview
```

The Profile page should not duplicate the calculations or persistence rules owned by those features.

---

# User Identity

The Profile header represents the authenticated SofaWatch user.

The backend user contract includes normalized information such as:

```text
id
display_name
is_local
is_admin
```

Exact fields should follow the current API/domain model.

---

# Current User Endpoint

The authenticated user is exposed through:

```text
GET /api/v1/users/me
```

The response is the backend source of truth for identity and authorization-related presentation.

Flutter should not infer administrator status from local assumptions.

---

# ProfileUser

The frontend normalized user model includes administrator awareness.

Conceptually:

```text
ProfileUser
├── id
├── displayName
├── isLocal
└── isAdmin
```

The data repository maps API fields such as:

```text
is_admin
```

into the domain model.

---

# Display Name

`display_name` is the user-facing account name.

It should be used where a friendly account identity is needed.

Future account-management features can define how and whether it can be changed.

---

# Local User

`is_local` identifies the account's local-authentication nature according to the backend model.

Presentation should not invent authentication-provider assumptions beyond what the backend exposes.

---

# Administrator

`is_admin` indicates whether the authenticated user has administrator privileges.

This affects visibility of administrator-only Profile sections.

It does not replace backend authorization.

---

# Authorization Principle

Administrator functionality uses defense in depth:

```text
Frontend
-> hide admin-only controls for non-admin users

Backend
-> independently require administrator authorization
```

The frontend is a UX boundary.

The backend is the security boundary.

---

# AdminUserDependency

Administrator-only backend routes use the canonical administrator dependency.

Unauthorized authenticated users receive a safe `403` response.

The established error contract includes:

```text
code: admin_required
message: Administrator access is required.
```

The dependency must remain centralized rather than duplicated across route modules.

---

# Statistics Section

Profile exposes a compact Statistics summary.

It should reuse `StatisticsSummaryCubit` / Statistics application data.

The section can surface selected high-value metrics and provide navigation to full Statistics.

See [Statistics](statistics.md).

---

# Statistics Ownership

Profile must not calculate metrics independently.

For example:

```text
Profile
-> asks Statistics feature for summary

not

Profile
-> queries watch events and calculates its own totals
```

This keeps Home, Profile, and full Statistics consistent.

---

# Statistics Loading

Statistics loading/failure should be isolated from the rest of Profile.

Example:

```text
Profile identity
-> success

Statistics
-> failure

Library
-> success

History
-> success
```

The user should still see identity, Library, and History.

---

# Statistics Retry

A Statistics failure should expose a local Retry action where appropriate.

Retrying Statistics should not reload the entire Profile unless required by the architecture.

---

# Library Section

Profile exposes a Library preview.

The preview is intentionally smaller than the full Library experience.

It can summarize or show recent/relevant tracked media.

See [Library](library.md).

---

# Library Ownership

Library membership and classification remain owned by the Library feature/backend.

Profile should consume normalized preview data.

It should not independently decide whether a Show or Movie belongs to a particular Library state.

---

# Library Navigation

The Profile Library section should provide a natural route to the full Library/Shows/Movies experience.

The destination should preserve the application's established navigation model rather than introducing a Profile-specific duplicate page.

---

# Library Loading and Failure

Library preview state is independent.

Conceptually:

```text
LibraryPreviewCubit
-> initial
-> loading
-> success
-> failure
```

A Library preview failure should not remove the Profile identity or other successful sections.

---

# History Section

Profile exposes a compact History preview.

It uses canonical Episode and Movie viewing events through the History feature.

See [History](history.md).

---

# History Preview

The preview can show a small number of recent entries.

It should not implement full History pagination.

Conceptually:

```text
Combined History
-> recent subset
-> Profile preview
```

---

# History Navigation

Selecting the section can open full History.

Selecting an individual entry can navigate to the associated media where the current UX supports it.

---

# History Loading and Failure

History preview uses independent state.

A History failure should expose local error/retry behavior without collapsing the rest of Profile.

---

# Section Independence

Profile is intentionally composed of independently useful sections.

A robust page can look like:

```text
Identity             success
Statistics           success
Library              failure + Retry
History              success
Server               success
```

This is preferable to one giant Profile request/state where one failure makes the entire page unusable.

---

# ProfileCubit

`ProfileCubit` owns the authenticated Profile user state.

Conceptually:

```text
initial
loading
success(user)
failure(error)
```

Identity is foundational because administrator-only UI depends on `user.isAdmin`.

---

# Profile Page Structure

The Profile presentation currently follows a structure conceptually similar to:

```text
ProfilePage
    |
    v
_ProfileBody
    |
    +-> Statistics
    +-> Library
    +-> History
    +-> administrator/application sections
```

Exact private widget names may evolve.

The architectural principle is more important than preserving presentation implementation names in documentation.

---

# Router Providers

The Profile route can provide independent feature Cubits/repositories needed by normal user sections.

Established user-facing Cubits include:

```text
ProfileCubit
StatisticsSummaryCubit
LibraryPreviewCubit
HistoryPreviewCubit
```

Administrator-only requests require additional care.

---

# Administrator-Only Lazy Loading

Non-administrators must not request administrator endpoints merely because a Cubit was eagerly created by the router.

Therefore:

```text
DO NOT:

MultiBlocProvider
-> ServerHealthCubit(repository)..load()
for every Profile user
```

Instead:

```text
Profile user loaded
        |
        v
isAdmin?
   |
   +-- no --> do not create/load ServerHealthCubit
   |
   +-- yes -> create administrator subtree lazily
              -> load ServerHealthCubit
```

This is both cleaner UX and correct request behavior.

---

# Why Lazy Admin Loading Matters

Backend authorization would still reject a non-admin request, but unnecessary requests would:

- create avoidable `403` traffic;
- produce noisy logs;
- complicate tests;
- couple Profile initialization to inaccessible functionality;
- potentially flash administrator error states.

The UI should avoid requests it already knows the user cannot make.

---

# Server Section

Administrators can access Server information from Profile.

The Server feature is independently documented.

See [Server Administration](server-administration.md).

---

# Server Health

The backend exposes:

```text
GET /api/v1/server/health
```

This endpoint requires administrator authorization.

It provides normalized server-health information without exposing secrets.

---

# Server Health Model

The current server-health domain includes concepts such as:

```text
ServerHealth
├── status
├── checkedAt
├── uptimeSeconds
├── database
└── tmdb
```

with component health models.

Future components can include TVDB and other operational dependencies.

---

# Overall Server Status

Overall status can represent:

```text
healthy
degraded
unavailable
```

Exact enum semantics should remain backend-defined.

The frontend maps them into clear user-facing status presentation.

---

# Database Health

Database health can include:

```text
status
latency
```

The health check validates real database connectivity using a lightweight query.

Profile should not expose database credentials or raw connection details.

---

# TMDB Health

TMDB health can expose:

```text
status
configured
latency
```

This distinguishes:

```text
not configured
```

from:

```text
configured but unavailable
```

where supported by the backend health contract.

---

# TVDB Health

TVDB health is planned once TVDB integration exists.

It should follow the same normalized operational-health approach rather than embedding provider-specific secrets or raw responses in the UI.

---

# Server Checked At

The UI can show when the health snapshot was produced.

This is different from the current client time.

The timestamp should use standard localization/timezone formatting.

---

# Uptime

Server uptime can be exposed as a human-readable duration.

The underlying backend value should remain normalized, for example seconds.

Flutter owns formatting.

---

# Environment

Environment information may be useful for administrators if intentionally exposed.

Examples might include:

```text
development
production
```

Do not expose internal secrets, filesystem paths, tokens, or unnecessary host details merely for convenience.

---

# Backend Version

A future Server section can expose the running SofaWatch backend version.

This is useful for:

- support;
- upgrade verification;
- debugging.

The version should come from a canonical application version source.

---

# ServerHealthCubit

The frontend Server feature uses a Cubit conceptually:

```text
ServerHealthCubit
├── load()
└── retry()
```

with states:

```text
Initial
Loading
Success(health)
Failure(error)
```

Errors use the normalized `AppException` architecture.

---

# Server Failure Isolation

If server-health retrieval fails:

```text
Profile identity
Statistics
Library
History
```

must remain usable.

Only the Server section should show its failure state.

---

# Server Retry

Retry should call the Server health application flow again.

It should not reconstruct the entire Profile page.

---

# Application Section

Profile can contain general SofaWatch application settings.

Potential/current areas include:

- language;
- appearance-related application preferences;
- metadata language;
- account/session settings;
- application information.

Only settings with real persistence/product behavior should be added.

---

# Localization Settings

Planned localization includes:

```text
English
Portuguese
```

A future Profile/Application setting can control the user's preferred application language.

Locale changes should affect:

- UI strings;
- dates;
- numbers;
- durations;
- metadata-provider language where intentionally linked.

---

# Metadata Language

Application UI language and provider metadata language are related but not necessarily identical.

If SofaWatch exposes both, their semantics should be clear.

Example:

```text
UI language: Portuguese
Metadata language: English
```

may be a valid configuration.

---

# Security Section

Security is administrator/account-sensitive functionality.

It can include:

- password management;
- session management;
- registration policy;
- user administration;
- authentication diagnostics where safe.

See [Authentication](authentication.md).

---

# Open Registration

The planned administrator-only setting:

```text
Open registration
```

controls whether the login experience also allows public/self-registration.

Default:

```text
off
```

This is intentional for a self-hosted personal application.

---

# First-Run Administrator

A new SofaWatch installation enters first-run setup.

The first created account becomes the initial Administrator.

Conceptually:

```text
no users exist
-> setup required
-> create first account
-> first account is Administrator
```

After setup, normal registration policy applies.

---

# Multi-User

SofaWatch supports multiple authenticated users.

Each user has independent:

- Library state;
- viewing History;
- Statistics;
- ratings;
- preferences;
- sessions.

Administrator privileges are an additional authorization capability, not a replacement for user scoping.

---

# User Administration

Full administrator user management is planned.

Potential capabilities include:

- list users;
- create/invite users;
- activate/deactivate accounts;
- grant/revoke administrator role where policy allows;
- inspect/revoke sessions;
- reset/recovery workflows.

These should use explicit backend authorization and audit-safe behavior.

---

# Session Management

Profile/Security can eventually expose the user's active sessions.

Useful information can include:

- device/session label;
- creation time;
- last-used time;
- current-session indicator;
- revoke action.

Sensitive token values must never be displayed.

---

# Password Change

Local users should be able to change their password through an authenticated security flow.

Password handling belongs to Authentication/Security backend logic.

Profile only provides the UI entry point.

---

# Password Recovery

Password recovery is part of the authentication model.

For self-hosted deployments, recovery semantics must be carefully defined because email infrastructure may not exist.

Any recovery mechanism must avoid weakening authentication merely for convenience.

---

# Mobile-to-Web Authentication Handoff

The authentication roadmap includes mobile-to-Web handoff.

If Profile exposes this capability, it should use the dedicated authentication feature and short-lived secure handoff semantics.

It should not place long-lived credentials in URLs.

---

# Import / Export

Profile is a natural entry point for user/admin Import and Export functionality.

The actual data rules belong to the Import/Export feature.

See [Import / Export](import-export.md).

---

# Export

Exports can include user-owned SofaWatch data such as:

- Library;
- viewing History;
- ratings;
- relevant preferences.

The export contract should be versioned and documented.

---

# Import

Import can restore or migrate supported SofaWatch data.

Import must define:

- validation;
- duplicate handling;
- historical timestamps;
- partial failures;
- ownership;
- version compatibility.

Profile should present progress/results without implementing these rules itself.

---

# Background Jobs

Administrator Profile can provide access to Background Jobs.

The Background Jobs feature owns:

- schedules;
- status;
- execution history;
- structured results.

For Metadata Sync, Profile currently exposes two distinct administrator actions:

```text
Run now
-> normal synchronization
-> respects freshness rules

Force refresh
-> deep forced synchronization
-> refreshes Show, Season, and Episode metadata
```

Force refresh is presented separately because it can make significantly more provider requests.

The action requires explicit confirmation and is disabled while the job is busy.

See [Background Jobs](background-jobs.md).

---

# Logs

Administrators can eventually access application logs through the management UI.

Logs must be sanitized.

They should not expose:

- passwords;
- access tokens;
- refresh credentials;
- session secrets;
- provider API tokens;
- unnecessary personal data.

---

# Logs UX

Useful log functionality may include:

```text
recent logs
level filtering
component filtering
bounded pagination
refresh
```

A browser UI should not attempt to load an unlimited log file.

---

# Administration Separation

Operational sections should remain modular.

Conceptually:

```text
Profile
└── Administration
    ├── Server Health
    ├── Background Jobs
    ├── Logs
    ├── Import / Export
    └── Security
```

Each can fail independently.

---

# Non-Admin Behavior

For a non-administrator:

```text
Server
Background Jobs
Admin Logs
Admin Security
User Administration
```

should not be rendered as accessible actions.

More importantly, their protected endpoints should not be called.

---

# Admin Behavior

For an administrator:

```text
ProfileSuccess(user.isAdmin == true)
-> administrator subtree becomes available
-> admin-specific Cubits can be created lazily
```

This keeps authorization-aware presentation explicit.

---

# Backend Security Remains Mandatory

Even if Flutter contains a bug and renders an administrator control for a non-admin:

```text
backend
-> AdminUserDependency
-> 403 admin_required
```

must still protect the operation.

Never treat hidden UI as authorization.

---

# Loading Architecture

Profile can have several simultaneous loading scopes:

```text
Profile identity
Statistics summary
Library preview
History preview
Server health
Background jobs
```

The page should avoid one monolithic loading state after identity is available.

---

# Initial Identity Loading

The user identity is foundational.

Before the Profile user is known, administrator-only subtree decisions cannot be made safely.

Therefore initial Profile identity loading may gate the structural page state.

Once identity succeeds, child sections can load independently.

---

# Identity Failure

If the current-user request fails because authentication is invalid, normal authentication/session handling applies.

A generic Profile retry should not hide a real session-expiration flow.

---

# Child Section Failure

A child section failure should use the shared section-failure presentation where appropriate.

For example:

```text
SectionFailureCard
```

or the current canonical reusable widget.

This keeps Retry/error behavior visually consistent.

---

# Refresh

A Profile refresh can coordinate user-visible sections.

It should avoid triggering administrator requests for non-admin users.

Where possible, previous successful data can remain visible during refresh.

---

# Mutation Reconciliation

Changes made elsewhere can affect Profile previews.

Examples:

```text
new viewing
-> Statistics summary changes
-> History preview changes

Library mutation
-> Library preview changes
```

Profile should reconcile through feature Cubits/repositories rather than maintaining its own shadow state.

---

# Navigation Back

When returning to Profile from full Statistics, Library, History, or admin pages, unnecessary complete reloads should be avoided if state is still valid.

Refresh when correctness requires it.

---

# Errors

Profile and its sections use the common SofaWatch error architecture.

Possible failures include:

- network;
- timeout;
- authentication;
- authorization;
- invalid response;
- server failure.

Raw technical errors should not be shown directly.

See [API Errors](../api/errors.md).

---

# Responsive Design

Profile shares domain/application logic across Web and mobile.

Mobile can favor:

- vertically stacked sections;
- compact preview cards;
- full-width settings rows;
- bottom sheets for lightweight actions.

Desktop can favor:

- constrained content width;
- grouped settings panels;
- multi-column summary sections where appropriate;
- dialogs for focused actions.

---

# Administrator Responsive Design

Administrator sections can contain denser operational information.

On mobile, avoid forcing desktop-style status tables into narrow widths.

Use:

- stacked component cards;
- concise labels;
- expandable detail where needed.

Desktop can present richer health/status layouts.

---

# Accessibility

Final Profile validation should include:

- semantic user identity;
- accessible section headings;
- accessible admin status where displayed;
- keyboard navigation;
- visible focus states;
- accessible Retry actions;
- status not communicated only by color;
- accessible toggles for Security settings;
- confirmation focus management for destructive actions.

---

# Performance

Profile should avoid:

- duplicate Statistics requests;
- duplicate Library queries;
- duplicate History queries;
- eager administrator requests;
- rebuilding every section for one child-state change.

Feature-specific Cubits and targeted widget rebuilds should help keep updates scoped.

---

# Testing

Backend tests should cover relevant Profile dependencies:

```text
/users/me authenticated response
is_admin field
non-admin admin dependency -> 403
admin dependency success
server health admin-only
user isolation
security-setting authorization
```

Frontend Profile tests should cover at least:

```text
initial Profile loading
Profile success
Profile failure
display name
Statistics preview
Statistics failure isolation
Library preview
Library failure isolation
History preview
History failure isolation
navigation
admin visible
non-admin hidden
non-admin does not call admin repository
admin Server loading
admin Server success
admin Server failure
Server Retry
section independence
responsive layout
```

---

# Critical Admin Request Test

A particularly important frontend test is:

```text
Given:
ProfileUser.isAdmin == false

When:
Profile renders

Then:
Server admin section is absent
AND
ServerRepository is never called
```

This verifies request behavior, not merely visual hiding.

---

# Admin Success Test

```text
Given:
ProfileUser.isAdmin == true

When:
Profile renders administrator subtree

Then:
ServerHealthCubit is created/loaded
AND
Server health UI is shown according to state
```

---

# Partial Failure Test

Example:

```text
Profile user -> success
Statistics -> success
Library -> failure
History -> success
Server -> failure
```

Expected:

```text
identity visible
Statistics visible
Library local failure + Retry
History visible
Server local failure + Retry
```

---

# Edge Cases

## Non-Admin User

```text
isAdmin = false
-> normal Profile
-> no administrator requests
```

## Administrator

```text
isAdmin = true
-> administrator sections available
```

## Server Unavailable

```text
Server section -> failure/degraded presentation
normal personal Profile sections -> remain usable
```

## TMDB Unavailable

Server health may show degraded TMDB state while local Profile/History/Statistics remain usable where they rely on persisted data.

## Empty Library

Library preview shows a valid empty state.

## Empty History

History preview shows a valid empty state.

## New Installation

First-run setup occurs before normal Profile usage.

The first account becomes Administrator.

## Administrator Role Changes

If a user's role changes in another session, the next authoritative user refresh should update `isAdmin` and the available UI.

The client should not permanently cache administrator privilege.

---

# Future Work

## Server UI

```text
[ ] integrate final admin-only Server section
[ ] lazy ServerHealthCubit creation
[ ] overall Server status
[ ] checked-at presentation
[ ] backend version
[ ] uptime
[ ] environment
[ ] database health
[ ] TMDB health
[ ] TVDB health when available
[ ] isolated Retry
```

---

## Application Settings

```text
[ ] language preference
[ ] metadata language preference
[ ] locale-aware dates/numbers
[ ] application information
[ ] evaluate additional useful preferences
```

---

## Security

```text
[ ] Open registration setting
[ ] default Open registration = off
[ ] password change UI
[ ] session management
[ ] session revocation
[ ] password recovery workflow
[ ] mobile-to-Web handoff UI where appropriate
```

---

## User Administration

```text
[ ] user list
[ ] user details
[ ] activate/deactivate accounts
[ ] administrator role management
[ ] session administration
[ ] safe confirmation flows
[ ] authorization tests
```

---

## Import / Export

```text
[ ] export UI
[ ] import UI
[ ] progress/result presentation
[ ] partial-failure presentation
[ ] version compatibility messaging
[ ] administrator/user ownership rules
```

---

## Background Jobs

```text
[ ] Profile/admin entry point
[ ] jobs overview
[ ] execution history
[ ] structured results
[ ] manual-run controls where supported
[ ] failure/retry presentation
```

---

## Logs

```text
[ ] sanitized log viewer
[ ] level filtering
[ ] component filtering
[ ] bounded pagination
[ ] refresh
[ ] verify secret redaction
```

---

## Final Validation

```text
[ ] mobile responsive audit
[ ] desktop responsive audit
[ ] ultrawide audit
[ ] accessibility audit
[ ] section independence tests
[ ] administrator request tests
[ ] navigation-state audit
```

---

# Notes

> Profile is a composition hub. Statistics, Library, History, Authentication, Server, Jobs, and Import/Export keep ownership of their own business rules.

> `GET /api/v1/users/me` is the authoritative source for the current Profile identity and administrator flag.

> Non-admin users must not request administrator endpoints.

> Administrator Cubits should be created lazily after the Profile user is known to be an administrator.

> Backend administrator authorization remains mandatory regardless of frontend visibility.

> One Profile section failing should not unnecessarily make the other independent sections unusable.

> The first account on a new installation becomes the initial Administrator.

> Public registration is controlled by the administrator-only `Open registration` setting and defaults to off.

> Server-health responses must not expose secrets.

> Personal user state remains user-scoped even for administrators.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Library](library.md)
- [Home](home.md)
- [Statistics](statistics.md)
- [History](history.md)
- [Authentication](authentication.md)
- [Server Administration](server-administration.md)
- [Background Jobs](background-jobs.md)
- [Import / Export](import-export.md)
- [Architecture Overview](../architecture/overview.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-005: Authentication Model](../decisions/005-authentication-model.md)
