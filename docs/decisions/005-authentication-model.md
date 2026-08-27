# ADR-005: Authentication and Session Model

- Status: Accepted
- Date: 2026-08-27

## Context

SofaWatch is a multi-user self-hosted application with clients running in different security environments.

The primary client categories are:

```text
Web browser
Native iOS application
Native Android application
```

These clients cannot safely or conveniently use exactly the same persistent credential mechanism.

A browser provides strong built-in support for server-managed cookies, including `HttpOnly` cookies that are unavailable to JavaScript.

Native applications instead need an explicit credential lifecycle suitable for API requests and secure device storage.

SofaWatch also requires:

- first-run account creation;
- Administrator authorization;
- optional public registration;
- persistent sessions;
- short-lived request authentication;
- session revocation;
- logout;
- logout everywhere;
- password changes;
- password recovery;
- Administrator recovery;
- Mobile-to-Web authentication handoff.

The authentication architecture must support these capabilities without relying on long-lived bearer tokens or storing reusable plaintext credentials on the server.

---

## Decision

SofaWatch uses a **server-managed session model** represented by `AuthSession`, with client-specific persistent authentication mechanisms.

Web uses:

```text
HttpOnly session cookie
        |
        v
server-side AuthSession
```

Native clients use:

```text
short-lived access token
        +
rotating refresh credential
        |
        v
server-side AuthSession
```

Both authentication paths resolve to the same backend `User`.

Conceptually:

```text
Web cookie ───────┐
                  │
                  v
           Current User
                  ^
                  │
Bearer token ─────┘
```

Persistent reusable credentials are stored on the server only as hashes.

Passwords are hashed using Argon2.

---

## AuthSession

`AuthSession` represents a persistent authenticated session.

A session is associated with:

- a User;
- a client/session type;
- lifecycle state;
- persistent credential state;
- expiry/revocation information;
- last-used information where applicable.

Conceptually:

```text
User
 |
 +-- AuthSession (Web)
 |
 +-- AuthSession (Mobile)
 |
 +-- AuthSession (another device)
```

This makes sessions individually revocable and provides a foundation for future session-management UI.

---

## Session Types

SofaWatch distinguishes at least:

```text
WEB
MOBILE
```

This is useful because the persistent credential behavior differs between browser and native clients.

The distinction belongs to the session model rather than requiring separate user types.

---

# Web Authentication

## HttpOnly Cookie

Web authentication uses a persistent session credential transported through an `HttpOnly` cookie.

The intended cookie characteristics include:

```text
HttpOnly
SameSite=Lax
Path=/
```

In production over HTTPS:

```text
Secure
```

should be enabled.

---

## Why HttpOnly

The persistent Web credential should not be readable through normal browser JavaScript.

Using an `HttpOnly` cookie reduces exposure of the reusable session credential to client-side script.

The Flutter Web application does not need to manually read and attach the credential.

The browser participates in cookie transport according to the configured request/CORS policy.

---

## Browser Session Restoration

Because the Web credential is persistent and browser-managed, reopening SofaWatch Web can restore the authenticated session without requiring the user to manually log in each time, provided the session remains valid.

Conceptually:

```text
Browser opens SofaWatch
        |
        v
request includes session cookie
        |
        v
backend resolves AuthSession
        |
        v
current User
```

---

## Web Credential Storage

The Web persistent credential must not be stored in:

```text
localStorage
sessionStorage
JavaScript-readable application state
```

as a replacement for the `HttpOnly` cookie model.

Short-lived in-memory application state may exist, but the reusable Web session credential remains cookie-based.

---

# Native Authentication

## Access Token

Native clients use a short-lived access token for normal authenticated API requests.

Conceptually:

```text
Authorization: Bearer <access-token>
```

The access token is intentionally short-lived.

It is not the persistent login mechanism.

---

## Refresh Credential

Native persistence is provided by a refresh credential associated with an `AuthSession`.

The refresh credential is:

- longer-lived than the access token;
- random/reusable only according to rotation rules;
- stored securely on the native client;
- stored only as a hash on the server.

The server must not need the plaintext refresh credential after issuance.

---

## Refresh Rotation

Refresh credentials rotate.

Conceptually:

```text
credential A
    |
    | refresh
    v
credential B

credential A
-> invalid immediately
```

The client replaces A with B after a successful refresh.

This limits the lifetime of any previously used refresh credential.

---

## Reuse

A previously rotated refresh credential must not continue to work.

Conceptually:

```text
A -> refresh -> B

later:

A -> refresh
     X rejected
```

The exact security response to detected reuse may evolve, but silently accepting an old credential is not valid behavior.

---

## Native Credential Storage

Native clients should store persistent refresh material using platform-appropriate secure storage.

The architecture should not depend on storing refresh credentials in ordinary unprotected application preferences.

Access tokens may remain in application memory and be recreated through refresh when needed.

---

# Unified Current User Resolution

## One User Model

Web and native authentication do not create different classes of users.

Both resolve to:

```text
User
```

The rest of the backend should consume authenticated identity through shared dependencies/contracts rather than reimplementing authentication per route.

---

## CurrentUserDependency

The backend current-user dependency accepts the supported authentication mechanisms and resolves the authenticated user.

Conceptually:

```text
Bearer access token
        or
Web session cookie
        |
        v
CurrentUserDependency
        |
        v
User
```

---

## Bearer Precedence

If a Bearer credential is explicitly present, it has precedence.

If the Bearer credential is invalid, SofaWatch must **not** silently fall back to a valid Web cookie.

Example:

```text
Authorization: Bearer invalid-token
Cookie: valid-web-session
```

must not be interpreted as:

```text
"Bearer failed, but cookie works, so authenticate anyway."
```

An explicitly supplied invalid Bearer credential should fail authentication.

This avoids ambiguous authentication behavior and prevents one credential channel from unexpectedly masking failure in another.

---

# Passwords

## Argon2

User passwords are hashed with Argon2.

SofaWatch never stores plaintext passwords.

Conceptually:

```text
password
   |
   v
Argon2
   |
   v
password hash
```

Authentication verifies the supplied password against the stored hash.

---

## Password Logging

Passwords must never be:

- written to application logs;
- included in exception messages;
- printed during normal command execution;
- returned through API responses.

---

## Password Change

An authenticated user may change their password by providing the current password and the new password.

The backend validates the current password.

Password changes are security-sensitive backend mutations and must not be implemented as frontend-only state.

---

# First-Run Setup

## Setup Required

A new SofaWatch installation with no users enters first-run setup.

Conceptually:

```text
no users
   |
   v
setup_required = true
   |
   v
Setup UI
```

The frontend should show Setup rather than normal Login when setup is required.

---

## First Administrator

The first account created during setup becomes the initial Administrator automatically.

This is a real user account, not a legacy special local-user object.

After successful setup:

```text
setup_required = false
```

and the setup endpoint/flow must no longer permit creation of additional first users.

---

## Concurrent Setup Protection

The backend protects against concurrent attempts creating multiple initial Administrators.

The first-user invariant is enforced server-side.

Frontend navigation alone is not sufficient protection.

---

# Registration

## Open Registration

SofaWatch has a global Security setting:

```text
Open registration
```

Default:

```text
false
```

Only an Administrator can change it.

---

## Closed Registration

When registration is closed:

```text
backend
-> rejects public registration

frontend
-> does not show Sign Up
```

The backend rule is authoritative.

Hiding Sign Up is UX, not security.

---

# Administrator Authorization

Administrator-only functionality is protected by backend authorization.

Examples include:

- Server diagnostics;
- Security settings;
- Logs;
- Background-job administration;
- password recovery initiation for other users;
- future user administration.

Frontend checks such as:

```text
user.isAdmin
```

are used to hide unavailable UI and avoid unnecessary calls.

They are not the authorization boundary.

---

# Logout

## Current Session Logout

Normal Logout revokes the current `AuthSession`.

The client also clears its locally held authentication material.

Conceptually:

```text
logout
   |
   +--> revoke current AuthSession
   |
   +--> clear client credential
```

---

## Logout Everywhere

Logout Everywhere revokes all sessions belonging to the authenticated user.

It does not affect other users.

Conceptually:

```text
User A
├── Web session      -> revoked
├── iPhone session   -> revoked
└── Android session  -> revoked

User B
└── sessions         -> unchanged
```

---

## Revocation

Revocation must be enforced server-side.

Deleting a token from one client without revoking the server session is not sufficient for a real Logout operation.

---

# Password Recovery

## Regular User Recovery

An Administrator may initiate password recovery for a regular user.

The recovery process uses a temporary random token.

The recovery token is:

- user-bound;
- short-lived;
- stored only as a hash on the server;
- single-use.

Conceptually:

```text
Admin initiates recovery
        |
        v
temporary recovery token
        |
        v
user opens recovery link
        |
        v
sets new password
        |
        v
token invalidated
+
existing sessions revoked
```

---

## Why Administrator-Initiated Recovery

SofaWatch is self-hosted and does not require an external email-delivery infrastructure as a prerequisite for account recovery.

An Administrator can securely provide the generated recovery link to the intended user through an appropriate channel.

A future email integration could build on this model without changing the fundamental token security properties.

---

## Administrator Recovery

An Administrator must not depend on being able to log into the Web UI to recover their own account.

SofaWatch therefore provides a server-side recovery command:

```bash
python -m app.admin.reset_password <username-or-email>
```

The new password is requested interactively through `getpass`.

The password must **not** be supplied as a command-line argument.

---

## CLI Recovery Security

Administrator recovery must not:

```text
python ... --password my-secret-password
```

because command-line arguments may be visible through:

- shell history;
- process inspection;
- logs;
- automation output.

The password is collected interactively and must not be printed.

After reset, existing sessions for that Administrator are revoked.

---

# Mobile-to-Web Authentication Handoff

## Purpose

A user already authenticated in the native application may want to open SofaWatch Web without manually entering credentials again.

SofaWatch supports a temporary Mobile-to-Web authentication handoff.

Conceptually:

```text
Authenticated Mobile
        |
        v
request handoff credential
        |
        v
open browser URL
        |
        v
Web exchanges credential
        |
        v
new Web AuthSession
```

---

## Handoff Credential

The handoff credential is:

- temporary;
- short-lived;
- user-bound;
- single-use.

It is not:

- a normal access token;
- a persistent mobile refresh credential;
- a permanent Web session credential.

---

## Exchange

The browser exchanges the temporary handoff credential with the backend.

If valid, the backend creates/establishes a Web `AuthSession` and sets the Web authentication cookie.

The handoff credential is then unusable.

---

## Invalid Handoff

The backend rejects credentials that are:

```text
invalid
expired
already used
```

The client must not attempt to reinterpret them as another credential type.

---

# Session Revocation and Security Events

Security-sensitive account operations may revoke existing sessions.

Examples include:

- password recovery completion;
- Administrator password reset;
- Logout Everywhere.

The exact policy for every future account mutation should be chosen deliberately.

The important principle is that the backend can invalidate persistent sessions centrally.

---

# Session Last Used

Where tracked, `last_used_at` or equivalent session activity metadata is backend-owned.

It can support future features such as:

- session listing;
- identifying old sessions;
- device/session management;
- security auditing.

It must not be treated as a precise user-presence indicator unless the implementation guarantees that semantic.

---

# Expiration

Access tokens and persistent sessions have different lifetimes.

Conceptually:

```text
Access token
-> short lifetime

AuthSession / refresh capability
-> longer persistent lifetime
```

This allows native API credentials to expire frequently without forcing the user to log in again after every access-token expiry.

---

# Credential Hashing

Reusable server-side credentials should be persisted as hashes where the server only needs to verify presented values.

This applies to concepts such as:

```text
refresh credentials
recovery tokens
handoff tokens
```

where supported by the implementation.

The database should not become a collection of immediately reusable plaintext authentication secrets.

---

# API Authentication Errors

Authentication and authorization failures follow the normalized SofaWatch API error contract.

Conceptually:

```text
401
-> authentication missing/invalid/expired

403
-> authenticated but not permitted
```

Clients should distinguish authentication failure from authorization failure.

See [API Errors](../api/errors.md).

---

# CORS and Cookies

Web cookie authentication requires correct CORS and credential behavior when frontend and backend origins differ.

Production configuration should use explicit trusted origins.

Authentication architecture must not be "fixed" by enabling unrestricted insecure CORS behavior.

Cookie attributes and CORS configuration should be evaluated together during production deployment.

---

# HTTPS

Production deployments that expose authentication over a network should use HTTPS.

HTTPS protects credentials in transit and allows the Web session cookie to use:

```text
Secure
```

Reverse proxy / TLS deployment guidance belongs to production/self-hosting documentation.

This ADR defines the authentication expectation rather than one mandatory reverse proxy product.

---

# CSRF Considerations

Web authentication uses cookies, so state-changing Web requests must be designed with cross-site request behavior in mind.

`SameSite=Lax`, explicit CORS configuration, accepted request methods/content types, and deployment origin design form part of the security boundary.

If SofaWatch's deployment or browser request model changes in a way that increases CSRF exposure, explicit CSRF-token protection should be evaluated.

Do not assume that `HttpOnly` protects against CSRF; it protects credential readability from JavaScript, which is a different concern.

---

# Access Token Scope

Access tokens authenticate requests.

They should not become a general-purpose permanent API key system by accident.

If SofaWatch later needs:

```text
personal API tokens
automation tokens
third-party integrations
```

those should be designed explicitly, with their own lifecycle and scopes, rather than reusing mobile access tokens indefinitely.

---

# Multi-User Data Isolation

Authentication establishes the current user.

User-scoped operations should derive ownership from that authenticated identity.

Conceptually:

```text
credential
   |
   v
User 42
   |
   +--> Library for User 42
   +--> History for User 42
   +--> Ratings for User 42
```

Clients should not be trusted to select another user's identity through arbitrary request parameters for normal user-scoped operations.

This follows [ADR-002](002-backend-source-of-truth.md).

---

# Legacy Local User

The previous concept of a special:

```text
Local User
is_local
isLocal
```

has been removed.

It must not be reintroduced as part of authentication shortcuts.

Development accounts are normal accounts.

The migrated development user retained the same user ID so existing user-scoped relationships could remain intact.

---

# Username Editing

Username editing is currently deliberately deferred.

This is not an authentication bug or missing requirement that should be implemented automatically.

Changing that product decision should consider:

- uniqueness;
- login behavior;
- session behavior;
- auditability;
- recovery;
- references/UI.

---

# Future User Administration

Full Administrator user management is separate from the core authentication model.

Future functionality may include:

- listing users;
- activating/deactivating users;
- identifying Administrators;
- administrative actions;
- session management.

This functionality should remain backend-authorized and is currently planned as Desktop/Web administration.

---

# Account Deactivation

Future account deactivation should be designed so that:

```text
inactive user
-> cannot log in
-> existing sessions are revoked
```

Reactivation should not magically restore previously revoked sessions.

Self-deactivation rules for Administrators must be explicitly protected.

This behavior is planned rather than implied to be fully implemented by this ADR.

---

# Consequences

## Positive

### Revocable Persistent Sessions

The server can invalidate authentication without waiting for every client credential to naturally expire.

### Browser Security Model

Web uses browser-managed `HttpOnly` cookies instead of exposing reusable session credentials to Flutter Web JavaScript.

### Native-Friendly Authentication

Native clients can authenticate API requests with Bearer access tokens while maintaining persistent login through refresh rotation.

### Short-Lived Access Tokens

Compromise of an access token has a limited natural lifetime.

### Multi-Device Support

A user can have independent Web and native sessions.

### Central Authorization

All clients resolve to the same backend User and authorization model.

### Recovery Without Mandatory Email Infrastructure

Self-hosted Administrators can recover normal users, while server-side CLI recovery protects against Administrator lockout.

---

## Trade-offs

### More Complex Than One Long-Lived Token

The model requires:

- AuthSession persistence;
- token expiry;
- refresh rotation;
- cookie handling;
- revocation;
- multiple client flows.

This complexity is intentional because authentication is security-sensitive.

### Web and Native Differ

The clients cannot share every authentication implementation detail.

They should share user-facing semantics where possible while respecting their different security environments.

### Production Configuration Matters

HTTPS, cookie settings, CORS, origin configuration, and reverse proxy behavior can affect authentication correctness.

### Session Cleanup

Expired/revoked sessions may eventually require cleanup/retention policy.

---

# Alternatives Considered

## One Long-Lived Bearer Token Everywhere

Rejected because a long-lived bearer token becomes a powerful reusable credential with weak revocation and exposure characteristics.

It is especially undesirable as the default persistent Web credential.

---

## JWT-Only Stateless Authentication

A completely stateless token model would make immediate server-side session revocation more difficult and would not naturally provide the desired per-device session lifecycle.

SofaWatch intentionally maintains server-side `AuthSession` state.

---

## Refresh Tokens Without Rotation

Rejected because a stolen refresh credential could remain reusable until expiry/revocation.

Rotation narrows reuse and makes old credentials invalid after successful refresh.

---

## JavaScript-Readable Web Tokens

Storing persistent Web credentials in `localStorage` or equivalent was rejected in favor of `HttpOnly` cookies.

---

## Same Cookie Mechanism for Native Apps

Native applications do not need to imitate browser cookie persistence when an explicit access/refresh model better fits their environment.

---

## External Identity Provider as a Requirement

SofaWatch could require OAuth/OIDC through an external identity system.

Rejected as a mandatory dependency because SofaWatch should remain practical as a self-contained self-hosted application.

External identity integration could be evaluated separately in the future.

---

## Email-Only Password Recovery

Rejected as the only recovery path because it would make email infrastructure a prerequisite for basic self-hosted account recovery.

---

# Revisit When

This decision should be revisited if authentication requirements materially change.

Examples include:

## External Identity / SSO

If SofaWatch adds:

```text
OIDC
OAuth
LDAP
SAML
```

the relationship between external identities, local users, and AuthSessions will require a new decision.

## Public API Tokens

If users need long-lived API access for scripts or integrations, a separate scoped API-token model should be designed.

## Offline-First Authentication

If native clients must remain fully functional for long periods without backend contact, credential/session semantics may require adjustment.

## High-Security Deployment Requirements

If SofaWatch targets environments requiring stronger controls such as:

- MFA;
- hardware-backed authentication;
- mandatory CSRF tokens;
- enterprise session policies;

the model should be extended deliberately.

## Passwordless Authentication

Passkeys/WebAuthn or another passwordless mechanism would require a new authentication decision while potentially retaining AuthSession as the post-authentication session model.

---

# If the Decision Changes

A materially different authentication architecture should be introduced through a new ADR.

That ADR should address:

- migration of existing users;
- existing AuthSessions;
- credential invalidation;
- Web behavior;
- native behavior;
- recovery;
- first-run setup;
- Administrator access;
- compatibility during upgrades.

ADR-005 should then be marked as superseded rather than rewritten to hide the previous architecture.

---

# Implementation Constraints

Code written under this decision should follow these rules:

```text
[ ] passwords are hashed with Argon2
[ ] plaintext passwords are never persisted
[ ] Web persistence uses an HttpOnly session cookie
[ ] production Web cookies use Secure when served over HTTPS
[ ] native API requests use short-lived access tokens
[ ] native persistence uses rotating refresh credentials
[ ] reusable server credentials are stored as hashes where applicable
[ ] AuthSession represents persistent authenticated sessions
[ ] Web and Mobile sessions are distinguishable
[ ] old rotated refresh credentials are rejected
[ ] Bearer authentication has explicit precedence over cookie fallback
[ ] invalid explicit Bearer credentials do not silently fall back to cookie
[ ] Logout revokes the current session
[ ] Logout Everywhere revokes only the current user's sessions
[ ] first-run setup creates the first Administrator
[ ] concurrent first-admin creation is protected server-side
[ ] Open Registration defaults to false
[ ] registration is enforced by the backend
[ ] Administrator authorization is enforced by the backend
[ ] recovery tokens are temporary, hashed, expiring, and single-use
[ ] successful recovery revokes existing user sessions
[ ] Administrator CLI reset never accepts the password as a CLI argument
[ ] Mobile-to-Web handoff tokens are short-lived and single-use
[ ] legacy is_local / Local User concepts are not reintroduced
[ ] username editing remains deferred unless product requirements change
```

---

# Relationship to Other Decisions

## SQLite

[ADR-001](001-sqlite.md) defines the database that persists users, AuthSessions, security settings, and authentication-related state.

## Backend as Source of Truth

[ADR-002](002-backend-source-of-truth.md) establishes that authentication validity, user identity, and authorization are backend-owned.

## Internal Media IDs

[ADR-003](003-internal-media-ids.md) separates authenticated user identity from provider/media identity.

## Global Search

[ADR-004](004-global-search.md) uses the same authenticated backend API model regardless of Search presentation.

## Provider Independence

[ADR-006](006-provider-independence.md) keeps authentication independent from metadata providers.

---

# Related Documentation

- [Documentation Index](../README.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Data Flow](../architecture/data-flow.md)
- [API Authentication](../api/authentication.md)
- [Frontend API Contract](../api/frontend-contract.md)
- [API Errors](../api/errors.md)
- [Configuration](../development/configuration.md)
- [Setup](../development/setup.md)
- [Testing](../development/testing.md)
- [Implementation Status](../features/implementation-status.md)
