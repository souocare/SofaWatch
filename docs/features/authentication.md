# Authentication

## Overview

Authentication is SofaWatch's identity, session, and account-access system.

SofaWatch is designed as a multi-user self-hosted application. Authentication therefore protects not only access to the server, but also the separation of each user's Library, viewing History, Statistics, ratings, preferences, and administrative privileges.

The authentication model deliberately differs between Web and native mobile clients:

```text
Web
-> server-managed session
-> HttpOnly cookie

iOS / Android
-> short-lived access credential
-> rotating refresh credential
```

A new SofaWatch installation uses a first-run setup flow. The first account created becomes the initial Administrator.

After initial setup, public self-registration is disabled by default and can be enabled by an Administrator through the `Open registration` security setting.

See:

- [Profile](profile.md)
- [Server Administration](server-administration.md)
- [ADR-005: Authentication Model](../decisions/005-authentication-model.md)
- [API Errors](../api/errors.md)

---

## Status

**Implemented / Evolving**

Implemented or established in the authentication architecture:

- multi-user authentication;
- authenticated current-user identity;
- administrator role support;
- first-run administrator setup;
- Web authentication using HttpOnly cookies/server-managed sessions;
- native authentication using access and refresh credentials;
- rotating refresh credentials;
- persistent authenticated sessions;
- session revocation;
- password change;
- password recovery architecture;
- configurable public registration;
- administrator-only registration policy;
- `Open registration` defaulting to disabled;
- mobile-to-Web authentication handoff architecture;
- authenticated user scoping throughout the application;
- backend administrator dependency;
- frontend administrator-aware presentation.

Authentication remains security-sensitive and should continue to evolve conservatively.

Future work includes final management UI, richer session/device presentation, user administration, recovery UX, handoff UX, security auditing, rate limiting/brute-force protections where appropriate, and production deployment hardening.

See [Implementation Status](implementation-status.md).

---

# Goals

Authentication should provide:

- secure account identity;
- persistent sessions;
- strict user isolation;
- first-run setup;
- multi-user support;
- administrator authorization;
- safe Web authentication;
- safe native authentication;
- credential rotation/revocation;
- password management;
- controlled registration;
- secure cross-device authentication handoff.

The design should remain appropriate for a self-hosted application without assuming a large external identity platform.

---

# Core Principles

Authentication follows these principles:

1. The backend is the authentication and authorization authority.
2. Passwords are never stored in plaintext.
3. Web session credentials should not be exposed to JavaScript.
4. Native access credentials should be short-lived.
5. Native refresh credentials should rotate.
6. Refresh/session credentials must be revocable.
7. User data is always scoped by authenticated identity.
8. Administrator UI visibility is not authorization.
9. Public registration is closed by default.
10. The first installation flow must not require a pre-existing administrator.
11. Sensitive credentials must never be logged.
12. Security behavior should be explicit rather than inferred by clients.

---

# Authentication vs Authorization

Authentication answers:

```text
Who is this user?
```

Authorization answers:

```text
What is this user allowed to do?
```

SofaWatch requires both.

Example:

```text
authenticated normal user
-> can access own Library
-> cannot access administrator Server endpoints
```

---

# User Model

The authenticated user domain includes concepts such as:

```text
User
├── id
├── display_name
├── authentication identity
├── is_local
├── is_admin
└── account status
```

Exact persisted fields should follow the current backend implementation.

Sensitive authentication fields must not be returned in normal user responses.

---

# Current User

The authenticated user can be retrieved through:

```text
GET /api/v1/users/me
```

The normalized response includes user-facing identity and authorization context such as:

```text
id
display_name
is_local
is_admin
```

This endpoint is the authoritative source for current-user Profile state.

---

# User Scoping

Authenticated identity is the basis for personal-data isolation.

Conceptually:

```text
authenticated user
        |
        +-> Library
        +-> EpisodeWatchEvents
        +-> MovieWatchEvents
        +-> Statistics
        +-> Ratings
        +-> Preferences
```

Clients should not be able to select an arbitrary `user_id` to access another user's normal application data.

---

# Never Trust Client User IDs

For user-owned endpoints, ownership should normally derive from the authenticated principal.

Avoid contracts such as:

```text
GET /history?user_id=123
```

for ordinary personal access when the backend can derive the user from authentication.

This reduces accidental authorization mistakes.

---

# First-Run Setup

A fresh SofaWatch installation begins with no users.

Normal login cannot work yet, so SofaWatch exposes a first-run setup state.

Conceptually:

```text
users = 0
    |
    v
setup required
    |
    v
create first account
    |
    v
account becomes Administrator
    |
    v
normal authentication mode
```

---

# Initial Administrator

The first successfully created account becomes:

```text
is_admin = true
```

This assignment is a backend invariant.

The frontend must not submit a trusted `is_admin=true` flag and decide the role itself.

---

# First-Run Race Condition

Two simultaneous first-run requests must not result in multiple unintended initial administrators.

The backend/database should make initial-account creation atomic enough to enforce:

```text
exactly one first account
```

under concurrent setup attempts.

The exact transaction/constraint strategy should follow the backend architecture.

---

# Setup Availability

First-run account creation should only be available while the installation genuinely has no users.

After the initial account exists:

```text
first-run setup endpoint
-> unavailable / conflict / appropriate safe response
```

It must not remain an unprotected administrator-creation endpoint.

---

# Registration

Registration after first-run setup is controlled by server security policy.

The key setting is:

```text
Open registration
```

Default:

```text
off
```

---

# Closed Registration

When `Open registration` is disabled:

```text
Login
-> available

Public self-registration
-> unavailable
```

Administrators can still manage accounts through explicit administrator functionality as that feature is implemented.

---

# Open Registration

When an Administrator enables:

```text
Open registration = on
```

the login/authentication experience may expose self-registration.

New self-registered users are normal users unless an explicit backend-admin workflow later grants administrator privileges.

Public registration must never implicitly create administrators.

---

# Registration Policy Ownership

The backend owns registration policy.

Even if a stale frontend still displays a registration action after the setting was disabled:

```text
backend
-> reject registration according to current policy
```

Frontend visibility is convenience, not enforcement.

---

# Registration Validation

Registration should validate at least the account fields required by the current model.

Potential validation includes:

- required identity fields;
- password policy;
- uniqueness;
- normalized input;
- account-state rules.

Validation errors should use the standard API error contract.

---

# Password Storage

Passwords must be stored using an appropriate password hashing algorithm.

Never store:

```text
plaintext password
reversible encrypted password
password in logs
```

The chosen hashing parameters should follow current security guidance and remain upgradeable.

---

# Password Verification

Login verifies the supplied password against the stored password hash.

Responses should avoid unnecessarily revealing whether:

- a username/account exists; or
- only the password was incorrect

when doing so would materially increase account-enumeration risk.

The exact UX can balance usability and security for a self-hosted application.

---

# Web Authentication

Flutter Web uses server-managed sessions through HttpOnly cookies.

Conceptually:

```text
Browser
   |
   | login
   v
Backend
   |
   | creates server session
   | Set-Cookie: session credential
   v
Browser cookie jar
```

Subsequent authenticated requests send the cookie automatically according to browser cookie policy.

---

# Why HttpOnly

The Web authentication credential should be stored in an HttpOnly cookie.

This prevents normal client-side JavaScript from reading the credential directly.

It reduces credential exposure in the event of certain client-side vulnerabilities.

HttpOnly does not eliminate the need for broader Web security controls.

---

# Web Cookie Security

Production cookie configuration should consider:

```text
HttpOnly
Secure
SameSite
Path
expiry / Max-Age
```

The exact `SameSite` strategy depends on deployment topology.

Production authentication should use HTTPS.

---

# Development HTTP

Local development may use:

```text
http://127.0.0.1:8000
```

and LAN HTTP for physical-device testing.

Production security requirements should not be weakened merely because local development uses HTTP.

Environment-aware cookie configuration may therefore be required.

---

# CORS and Credentials

When Flutter Web and the API run on different origins during development, authenticated cookie requests require correct CORS/credential configuration.

The backend should explicitly allow only appropriate origins rather than using insecure wildcard credential behavior.

Frontend HTTP configuration must send credentials where required by the Web authentication model.

---

# CSRF

Cookie-based authentication requires deliberate CSRF consideration because browsers can attach cookies automatically.

The final production security model should account for:

- `SameSite` policy;
- request origin validation where appropriate;
- CSRF tokens for relevant state-changing requests if required by deployment topology.

Do not assume HttpOnly alone solves CSRF.

---

# Web Login

Conceptually:

```text
credentials
-> login endpoint
-> verify account
-> create session
-> set HttpOnly cookie
-> authenticated Web session
```

The authentication response should not expose unnecessary secret session material to Flutter.

---

# Web Logout

Logout should invalidate the server-side session and clear/expire the corresponding browser cookie.

Conceptually:

```text
logout
-> revoke session
-> clear cookie
```

Clearing only the browser cookie without invalidating the server session is weaker than explicit revocation.

---

# Native Authentication

iOS and Android use credential-based API authentication suitable for native clients.

Conceptually:

```text
login
   |
   v
access credential
+
refresh credential
```

The access credential is short-lived.

The refresh credential provides persistent login and is rotated.

---

# Access Credential

The access credential is used for normal authenticated API calls.

Properties:

```text
short-lived
limited purpose
not a permanent login secret
```

If compromised, its useful lifetime should be bounded.

---

# Refresh Credential

The refresh credential is longer-lived than the access credential and is used to obtain a new access credential.

It is therefore more sensitive.

It should be stored using platform-appropriate secure storage.

---

# Secure Native Storage

Native refresh credentials should use secure operating-system storage rather than ordinary application preferences.

Examples conceptually include:

```text
iOS Keychain
Android Keystore-backed secure storage
```

Exact Flutter package choices should follow current project dependencies and security review.

---

# Refresh Rotation

Refresh credentials rotate.

Conceptually:

```text
refresh A
-> access B + refresh B
-> refresh A becomes invalid
```

The client stores the new refresh credential after successful rotation.

---

# Why Rotation

Rotation limits replay of old refresh credentials and enables detection/control of reused credential chains depending on the backend implementation.

A refresh credential should not remain valid indefinitely after it has been exchanged.

---

# Refresh Reuse

If an already-rotated/revoked refresh credential is presented again, the backend should reject it.

Depending on the session-family security design, reuse can trigger broader revocation of the affected session family.

The exact policy should be explicit and tested.

---

# Native Logout

Native logout should revoke the relevant server-side session/refresh credential and remove local secure credentials.

Conceptually:

```text
revoke server session
+
clear local access credential
+
clear local refresh credential
```

---

# Session Model

Persistent authentication is represented by revocable server-side session state.

A session can conceptually include:

```text
id
user_id
created_at
expires_at
revoked_at
last_used_at
client/session metadata
refresh-family state
```

Exact fields should follow the current implementation.

---

# Session Revocation

Sessions can be revoked.

After revocation:

```text
session/refresh credential
-> no longer valid
```

Revocation is important for:

- logout;
- lost devices;
- password/security changes;
- administrator actions where permitted;
- refresh-token reuse handling.

---

# Current Session

Future session-management UI should identify the current session clearly.

The user should not need to infer it from opaque IDs.

---

# Session Metadata

Useful safe metadata can include:

- created time;
- last used time;
- approximate client/device label;
- current-session indicator.

Avoid exposing:

- raw access credentials;
- raw refresh credentials;
- session secrets;
- unnecessary fingerprinting information.

---

# Session Expiry

Sessions/refresh credentials should have bounded validity.

Expiry policy should balance:

- convenient persistent login;
- security;
- self-hosted usage expectations.

The exact durations belong to configuration/security policy and should be documented when finalized.

---

# Access Expiry Handling

A native API request can encounter an expired access credential.

The client can:

```text
request fails due to expired access
-> refresh once
-> receive rotated credentials
-> retry eligible original request
```

This requires careful concurrency control.

---

# Concurrent Refresh

Multiple API calls can discover access expiry simultaneously.

The client should avoid launching multiple competing refresh rotations with the same refresh credential.

Conceptually:

```text
request A ─┐
request B ─┼-> one refresh operation
request C ─┘
               |
               v
       all continue with new access
```

This is particularly important with rotating refresh credentials.

---

# Failed Refresh

If refresh fails because the refresh credential is invalid, expired, or revoked:

```text
clear local auth state
-> return to authentication flow
```

The client should not loop indefinitely.

---

# Request Retry Safety

Automatic retry after authentication refresh must respect mutation semantics.

A request that definitely failed before reaching application execution may be safe to retry.

An ambiguous non-idempotent mutation requires care.

Authentication middleware/interceptors should not blindly duplicate actions such as creating a viewing event.

---

# Password Change

Authenticated local users can change their password.

A secure password-change flow should verify appropriate credentials and validate the new password.

---

# Password Change and Sessions

The security policy should explicitly define what happens to existing sessions after a password change.

A strong default is to allow the user to revoke other sessions, or automatically revoke them depending on the chosen threat model.

The current session may be retained or renewed deliberately.

This behavior must be tested and documented when finalized.

---

# Password Recovery

Password recovery is more complicated in a self-hosted application because email delivery may not be configured.

Recovery must not introduce an easy authentication bypass.

Potential recovery strategies require explicit product/security decisions.

---

# Recovery Principles

Any recovery mechanism should:

- verify a legitimate recovery capability;
- use short-lived one-time material where applicable;
- invalidate used recovery material;
- avoid exposing whether arbitrary accounts exist unnecessarily;
- allow session revocation after recovery;
- never log recovery secrets.

---

# Administrator Recovery

A future self-hosted recovery path may involve an authenticated Administrator helping another user.

This must not mean administrators can casually read or retrieve user passwords.

Passwords remain non-recoverable plaintext secrets.

An administrator can at most initiate/reset credentials according to an explicit secure workflow.

---

# No Administrator Password Visibility

SofaWatch must never provide:

```text
show user's current password
download password
decrypt password
```

because passwords are hashed, not reversibly stored.

---

# Administrator Authorization

Administrator-only operations use backend authorization.

The canonical dependency verifies:

```text
current_user.is_admin
```

Failure returns a safe `403` with the established administrator-required error.

See [Profile](profile.md).

---

# Frontend Administrator Visibility

Flutter can use:

```text
ProfileUser.isAdmin
```

to decide whether to render administrator functionality.

This avoids inaccessible controls and unnecessary requests.

It does not replace backend authorization.

---

# Account Deactivation

Future administrator user management can support account deactivation.

A deactivated account should not continue authenticating normally.

The policy should define what happens to existing sessions:

```text
deactivate account
-> revoke sessions
```

is generally the expected behavior.

Personal data should not automatically be deleted merely because access is disabled.

---

# Account Deletion

If account deletion is implemented, it requires explicit data-retention semantics.

Potential affected data includes:

- Library;
- viewing events;
- ratings;
- preferences;
- sessions.

This should not be conflated with simple deactivation.

---

# Role Changes

Changing administrator status is security-sensitive.

The backend should enforce:

- administrator authorization;
- valid role transition rules;
- protection against accidental loss of all administrative access where appropriate.

The client must refresh authoritative user state after role changes.

---

# Last Administrator

If SofaWatch allows administrator-role removal, it should consider preventing the installation from ending with no Administrator.

Conceptually:

```text
only remaining Administrator
-> cannot remove own admin role
```

unless another explicit recovery mechanism exists.

---

# Mobile-to-Web Handoff

SofaWatch's authentication roadmap includes native-mobile-to-Web authentication handoff.

The goal is to let an already authenticated mobile user authorize a Web session without manually re-entering credentials.

---

# Handoff Security Model

The handoff should use a short-lived, one-time authorization artifact.

Conceptually:

```text
Mobile authenticated session
        |
        v
request one-time handoff
        |
        v
short-lived handoff code/token
        |
        v
Web redeems once
        |
        v
backend creates Web session
        |
        v
HttpOnly cookie
```

---

# Handoff Must Not Transfer Long-Lived Credentials

Do not place:

```text
refresh credential
session secret
password
long-lived bearer token
```

into a QR code, URL, clipboard handoff, or browser query string.

The handoff artifact should be purpose-specific and short-lived.

---

# Handoff One-Time Use

After successful redemption:

```text
handoff artifact
-> consumed
-> cannot be reused
```

It should also expire quickly if never redeemed.

---

# Handoff Confirmation

Depending on the final UX, mobile can show enough context to confirm the Web-login attempt.

This can reduce accidental authorization of an unexpected browser.

Avoid collecting invasive device fingerprinting solely for this feature.

---

# Handoff Failure

Expired, invalid, or already-used handoff artifacts should fail safely.

The Web client should return to a normal authentication path without exposing secret validation details.

---

# Authentication State in Flutter

Flutter should expose normalized authentication state to the application.

Conceptually:

```text
unknown / restoring
unauthenticated
authenticated(user/session context)
```

Exact Cubit/Bloc/router architecture should follow the current implementation.

---

# Startup Restoration

On application startup:

Web:

```text
browser already has session cookie
-> request authenticated session/current user
-> restore app state
```

Native:

```text
secure refresh state exists
-> restore/refresh credentials
-> request current user
-> restore app state
```

The UI should avoid briefly showing protected content before authentication state is known.

---

# Router Protection

Protected application routes require authenticated state.

Unauthenticated users should be routed to the authentication/setup experience.

Administrator pages additionally require administrator presentation checks, while backend authorization remains authoritative.

---

# Setup vs Login Routing

Startup routing must distinguish:

```text
fresh installation
-> setup

configured installation + unauthenticated
-> login

authenticated
-> application
```

The backend should expose enough safe state for the client to make this distinction without guessing.

---

# Registration Routing

When registration is closed:

```text
login UI
-> no public Register action
```

When open:

```text
login UI
-> Register available
```

The backend remains authoritative if the policy changes while the page is open.

---

# Logout Routing

After successful logout or definitive session invalidation:

```text
clear authenticated application state
-> navigate to login
```

User-scoped Cubits/caches should not remain available to the next account.

---

# User Switch Isolation

On logout followed by another user's login, the frontend must not show stale data from the previous user.

User-scoped state should be disposed/reset appropriately.

This includes:

- Home;
- Library;
- History;
- Statistics;
- Profile;
- ratings;
- cached previews.

---

# Backend Dependency Architecture

Authenticated endpoints should use centralized current-user dependencies.

Administrator endpoints layer administrator authorization on top.

Conceptually:

```text
request
-> authenticate session/token
-> resolve current user
-> route/service
```

Admin:

```text
request
-> authenticate
-> resolve current user
-> require admin
-> route/service
```

Avoid duplicating authentication parsing in individual route handlers.

---

# Service and Repository Boundaries

Authentication routes should delegate persistence/business behavior through appropriate services/repositories rather than embedding session/password logic directly into HTTP handlers.

This improves:

- testability;
- transaction handling;
- reuse;
- security review.

---

# API Errors

Authentication errors use the common safe error contract.

Potential categories include:

```text
authentication required
invalid credentials
session expired
session revoked
administrator required
registration closed
validation error
conflict
rate limited
```

Internal cryptographic/database details must not be exposed.

See [API Errors](../api/errors.md).

---

# 401 vs 403

Use semantics consistently.

Conceptually:

```text
401
-> not validly authenticated

403
-> authenticated, but not authorized
```

Example:

```text
normal user requests /server/health
-> 403 admin_required
```

---

# Registration Conflict

Attempting to create an already-existing identity should return an appropriate safe conflict/validation response.

The exact message should balance usability with account-enumeration considerations.

---

# First-Run Conflict

If setup is submitted after another request already created the initial account:

```text
-> safe conflict/setup-complete response
```

It must not create another Administrator through the first-run path.

---

# Rate Limiting

Production hardening should evaluate rate limiting for security-sensitive operations such as:

- login;
- registration;
- password recovery;
- handoff creation/redemption.

A self-hosted deployment should avoid making legitimate local use painful, but unlimited brute-force attempts are undesirable.

---

# Brute-Force Protection

Potential protections include:

- request rate limits;
- progressive delay;
- temporary attempt throttling;
- security logging without credentials.

Avoid permanent account lockouts that can trivially become denial-of-service mechanisms unless carefully designed.

---

# Security Logging

Useful security events can include:

- successful login;
- failed login category without password;
- logout;
- session revocation;
- password change;
- recovery;
- administrator role changes;
- registration-policy changes.

Logs should avoid excessive personal data and never contain credentials.

---

# Secrets in Logs

Never log:

```text
password
password hash
access credential
refresh credential
session cookie
handoff secret
recovery secret
TMDB/TVDB token
```

Request logging middleware should redact authentication headers/cookies where necessary.

---

# Configuration

Authentication-related configuration may include:

- credential lifetimes;
- cookie settings;
- allowed Web origins;
- environment/HTTPS behavior;
- password-hashing parameters;
- recovery configuration.

Secrets belong in environment/configuration, not source control.

See the development/configuration documentation.

---

# Production HTTPS

Production authentication must be deployed behind HTTPS.

HTTPS protects credentials and session cookies in transit.

A reverse proxy can terminate TLS while forwarding trusted traffic to the FastAPI application according to the deployment architecture.

---

# Reverse Proxy

Production documentation should define:

- trusted proxy headers;
- HTTPS detection;
- secure cookie behavior;
- origin/host configuration;
- forwarding rules.

Authentication should not blindly trust arbitrary forwarded headers from untrusted clients.

---

# CSRF and Cross-Origin Deployment

If frontend and backend are deployed cross-origin, the security model must be reviewed carefully.

Cookie authentication, CORS, SameSite, and CSRF protections interact.

Prefer a simple same-site deployment when practical for self-hosting.

---

# Testing

Backend tests should cover at least:

```text
first-run state
create initial Administrator
concurrent/duplicate first-run prevention
setup unavailable after first user
login success
invalid login
Web session creation
Web current-user authentication
Web logout revocation
native login
access credential authentication
access expiry
refresh success
refresh rotation
old refresh rejection
refresh revocation
logout
session revocation
current user
user isolation
admin dependency
non-admin -> 403
registration closed
registration open
self-registration creates non-admin
password change
password recovery rules
deactivated account
role changes
handoff creation
handoff expiry
handoff one-time redemption
```

Frontend tests should cover at least:

```text
startup auth restoration
setup routing
login routing
authenticated routing
registration hidden when closed
registration visible when open
login success
login failure
logout
expired session
native refresh
failed refresh
concurrent refresh
user-state reset on logout
non-admin admin UI hidden
non-admin no admin requests
admin UI visible
password-change flow
session management
handoff flow
```

---

# Security Tests

Security-focused tests should explicitly verify:

```text
cannot access another user's data
cannot delete another user's watch event
cannot use first-run after setup
cannot self-register as admin
cannot access admin endpoints as normal user
revoked sessions fail
rotated refresh credential cannot be reused normally
expired handoff cannot be redeemed
used handoff cannot be redeemed twice
credentials never appear in API responses
```

---

# Edge Cases

## Fresh Installation

```text
0 users
-> setup required
```

## Two Simultaneous Setup Attempts

Only one should become the initial Administrator.

## Registration Disabled

```text
normal login works
public registration rejected
```

## Registration Enabled

New public accounts are normal users.

## Expired Web Session

Current-user request fails authentication and client returns to login.

## Expired Native Access Credential

Client refreshes once using the valid rotating refresh flow.

## Expired Refresh Credential

Authentication state is cleared and login is required.

## Revoked Session

Credential refresh/use is rejected.

## Password Changed on Another Device

Behavior follows the finalized session-revocation policy.

## User Deactivated

Existing sessions should no longer provide normal access according to policy.

## Admin Role Revoked

Next authoritative user refresh removes administrator UI; backend immediately enforces current authorization.

## Handoff Redeemed Twice

Second redemption fails.

## User A Logs Out, User B Logs In

No User A Library/History/Statistics state may remain visible.

---

# Future Work

## Authentication UX

```text
[ ] final first-run setup UI
[ ] final login UI
[ ] final registration UI
[ ] validation/error UX
[ ] password-change UI
[ ] recovery UI
[ ] session-management UI
```

---

## Session Management

```text
[ ] device/session labels
[ ] current-session indicator
[ ] revoke individual session
[ ] revoke other sessions
[ ] session expiry presentation
[ ] last-used presentation
```

---

## User Administration

```text
[ ] list users
[ ] create/manage users
[ ] activate/deactivate users
[ ] administrator role management
[ ] prevent accidental loss of last Administrator
[ ] revoke user sessions
```

---

## Mobile-to-Web Handoff

```text
[ ] finalize one-time handoff API
[ ] short expiry
[ ] one-time redemption
[ ] mobile confirmation UX
[ ] Web redemption UX
[ ] prevent credentials in URLs/logs
[ ] security tests
```

---

## Recovery

```text
[ ] finalize self-hosted recovery strategy
[ ] define optional email-based recovery if configured
[ ] administrator-assisted reset rules
[ ] one-time recovery secrets
[ ] session revocation after recovery
```

---

## Production Hardening

```text
[ ] login rate limiting
[ ] registration rate limiting
[ ] recovery throttling
[ ] security-event logging
[ ] cookie configuration audit
[ ] CSRF audit
[ ] CORS audit
[ ] HTTPS/reverse-proxy audit
[ ] credential redaction audit
[ ] dependency/security audit
```

---

## Localization

```text
[ ] English authentication strings
[ ] Portuguese authentication strings
[ ] localized validation
[ ] localized security/session dates
[ ] pluralization
```

---

# Notes

> The backend is always the authentication and authorization authority.

> The first account on a fresh installation becomes the initial Administrator.

> First-run setup must become unavailable after the first account exists.

> Public registration defaults to disabled.

> Enabling public registration does not allow users to self-register as Administrators.

> Web uses server-managed sessions with HttpOnly cookies.

> Native clients use short-lived access credentials and rotating refresh credentials.

> Refresh credentials should be stored using platform secure storage.

> Rotated/revoked refresh credentials must not remain valid.

> Administrator UI visibility is not a security boundary; protected backend endpoints must independently require administrator authorization.

> Logout should revoke server-side session state, not merely delete local credentials.

> User-scoped frontend state must be cleared when accounts change.

> Passwords and authentication credentials must never be logged.

> Mobile-to-Web handoff must use short-lived, one-time purpose-specific authorization material rather than transferring long-lived credentials.

---

# Related Documentation

- [Implementation Status](implementation-status.md)
- [Profile](profile.md)
- [Server Administration](server-administration.md)
- [Import / Export](import-export.md)
- [Library](library.md)
- [History](history.md)
- [Statistics](statistics.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Database Architecture](../architecture/database.md)
- [Data Flow](../architecture/data-flow.md)
- [Frontend Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [ADR-002: Backend as Source of Truth](../decisions/002-backend-source-of-truth.md)
- [ADR-005: Authentication Model](../decisions/005-authentication-model.md)
