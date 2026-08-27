# Authentication API

This document describes the API contract and client expectations for SofaWatch authentication.

It complements the broader [Authentication Architecture](../architecture/authentication.md). The architecture document explains the system design; this document focuses on HTTP-facing authentication flows and the behavior clients can rely on.

For exact endpoint paths, request bodies, response fields, and status codes in the current build, use FastAPI's generated OpenAPI documentation.

---

## 1. Goals

SofaWatch authentication is designed for a self-hosted, multi-user application with both browser and native clients.

The API supports:

- first-run bootstrap;
- account login;
- persistent Web sessions;
- native/mobile sessions;
- short-lived access tokens;
- rotating refresh credentials;
- session restoration;
- logout;
- logout everywhere;
- configurable public registration;
- password changes;
- user password recovery;
- Administrator recovery through the server;
- Mobile-to-Web authentication handoff.

The backend is authoritative for authentication and authorization state.

---

## 2. Authentication Is Multi-User

SofaWatch no longer uses a fixed local user.

Do not use or reintroduce concepts such as:

```text
is_local
isLocal
Local User
fixed local user
```

Every authenticated request resolves to a real SofaWatch `User`.

---

## 3. Authentication vs Authorization

Authentication answers:

```text
Who is making this request?
```

Authorization answers:

```text
Is this user allowed to perform this action?
```

A valid session does not automatically grant Administrator permissions.

Conceptually:

```text
Request
   |
   v
Authentication
   |
   v
Current User
   |
   v
Authorization
   |
   +--> normal user capability
   |
   +--> Administrator capability
```

---

# Bootstrap and First Run

## 4. Bootstrap State

Before showing Setup or Login, clients should use the backend authentication/bootstrap contract to determine the server state.

Important concepts include:

```text
setup_required
registration availability
current authenticated state
```

The frontend must not decide setup state from local storage.

---

## 5. Fresh Installation

A new SofaWatch installation with no users reports:

```text
setup_required = true
```

The client should present first-run account creation instead of the normal Login screen.

---

## 6. First Account

The first successfully created account becomes the initial Administrator.

Conceptually:

```text
No users
   |
   v
Setup
   |
   v
Create User
   |
   +--> is_admin = true
   |
   v
Setup permanently completed
```

The frontend does not submit:

```text
is_admin = true
```

as a trusted decision.

Administrator assignment is a backend rule.

---

## 7. Concurrent Setup Protection

Two clients may theoretically attempt first-run setup at the same time.

The backend must ensure that this cannot create two independent "first administrators."

Only one setup operation can win.

A losing client should receive a safe conflict/setup-no-longer-available response and refresh its bootstrap state.

---

## 8. Setup Is Not Public Registration

First-run setup and public registration are distinct flows.

Setup exists only while no account exists.

Public registration is governed by the global:

```text
Open Registration
```

setting after setup.

---

# Registration

## 9. Open Registration

The global security setting:

```text
Open Registration
```

defaults to:

```text
false
```

Only an Administrator can change it.

---

## 10. Registration Closed

When registration is closed:

```text
public registration request
        |
        v
backend rejects request
```

The frontend should also hide Sign Up.

Hiding the UI is not the security mechanism.

---

## 11. Registration Open

When registration is enabled, unauthenticated users may create normal accounts through the public registration flow.

Public registration must not allow callers to choose Administrator privileges.

---

## 12. Account Fields

Account creation/login contracts may use concepts such as:

- username;
- email;
- display name;
- password.

Exact validation constraints are defined by the current backend schemas.

Clients should use OpenAPI/current validation errors rather than duplicate every validation rule independently.

---

# Passwords

## 13. Password Storage

Passwords are hashed using Argon2.

The API never returns:

- plaintext passwords;
- password hashes.

Password verification happens server-side.

---

## 14. Password Transport

Passwords are sensitive request data.

Production deployments must use HTTPS.

Do not log request bodies containing passwords.

---

## 15. Password Change

An authenticated user may change their password when they know the current password.

Conceptually:

```text
authenticated user
    |
    v
current password + new password
    |
    v
verify current password
    |
    v
store new Argon2 hash
```

The backend owns password verification and hashing.

---

## 16. Username Editing

Changing username is deliberately deferred.

The absence of username editing is not an authentication bug.

Do not introduce a username-update API without a new product decision.

---

# Login

## 17. Login Identity

Login supports the account identifier accepted by the current backend contract, such as username/email, together with password.

The exact request schema should be read from OpenAPI.

---

## 18. Login Failure

Invalid credentials must produce a safe authentication failure.

The API must not reveal sensitive account-discovery details unnecessarily.

The frontend should present a safe Login error rather than raw backend exceptions.

---

## 19. Inactive Accounts

When account activation/deactivation is introduced/used, an inactive account must not be able to authenticate successfully.

Administrative activation/deactivation is planned broader user-management work.

---

# Sessions

## 20. AuthSession

Persistent authenticated sessions are represented server-side by `AuthSession`.

A session represents a persistent authenticated client relationship.

Sessions distinguish client types such as:

```text
WEB
MOBILE
```

---

## 21. Server-Side Credential Storage

Persistent session credentials are not stored in plaintext server-side.

The server stores hashes of persistent credentials.

If the database is inspected, it should not reveal usable refresh/session credentials.

---

## 22. Session Lifecycle

A session can be:

- created;
- used;
- renewed/rotated as appropriate;
- expired;
- revoked.

It may also track operational metadata such as last use.

---

# Web Authentication

## 23. Web Session Model

Web uses:

```text
HttpOnly cookie
+
server-side AuthSession
```

The browser sends the cookie automatically when request/CORS configuration permits it.

---

## 24. Web Cookie Properties

The persistent Web session cookie uses security properties including:

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

## 25. Why HttpOnly

HttpOnly prevents JavaScript from directly reading the session credential.

The frontend should not need access to the raw credential.

Do not replace this with:

```text
localStorage token
```

for convenience.

---

## 26. Web Login Flow

Conceptually:

```text
Browser
   |
   | username/email + password
   v
Login API
   |
   v
Authenticate User
   |
   v
Create WEB AuthSession
   |
   v
Set HttpOnly cookie
   |
   v
Authenticated browser
```

---

## 27. Web Session Restoration

After browser reload/restart:

```text
browser still has valid cookie
        |
        v
authenticated API/bootstrap request
        |
        v
backend resolves AuthSession
        |
        v
current User restored
```

The Flutter Web client should not require a locally persisted access token for this.

---

## 28. Web CORS and Credentials

Cross-origin Web development requires correct CORS configuration.

The server must allow the frontend origin and credential behavior.

Do not weaken authentication to work around CORS.

See [Configuration](../development/configuration.md) and [Debugging](../development/debugging.md).

---

# Native / Mobile Authentication

## 29. Native Session Model

Native clients use:

```text
short-lived access token
+
rotating refresh credential
+
server-side MOBILE AuthSession
```

The access token is not the long-term persistence mechanism.

---

## 30. Access Token

The access token authenticates normal API requests.

It is intentionally short-lived.

Requests use the standard Bearer mechanism:

```text
Authorization: Bearer <access-token>
```

The raw token must not be logged.

---

## 31. Refresh Credential

The refresh credential provides persistent native authentication.

It is bound to a server-side `AuthSession`.

The server stores only its hash.

The native client must protect the usable credential using secure client storage.

---

## 32. Native Login Flow

Conceptually:

```text
Native App
    |
    | credentials
    v
Login API
    |
    v
Authenticate User
    |
    v
Create MOBILE AuthSession
    |
    +--> short access token
    |
    +--> refresh credential
```

The client stores the refresh credential securely and keeps the access token according to the auth implementation's lifecycle.

---

## 33. Refresh Flow

Conceptually:

```text
Access token expires / needs renewal
        |
        v
send Refresh A
        |
        v
validate AuthSession + hash
        |
        v
rotate credential
        |
        +--> new access token
        +--> Refresh B
```

The client must replace A with B.

---

## 34. Rotation Is Mandatory

After successful rotation:

```text
Refresh A
```

is immediately invalid.

This reduces the usefulness of a stolen old credential.

---

## 35. Refresh Reuse

If an already-rotated refresh credential is submitted again, the request must fail.

Clients must not interpret this as a reason to keep retrying the same credential.

---

## 36. Native Session Restoration

On app startup, the client may use the securely stored refresh credential to restore authentication according to the current auth flow.

The client should not assume an old access token remains valid indefinitely.

---

# Unified Current User Resolution

## 37. CurrentUserDependency

Protected API routes resolve the current user through a unified backend dependency.

Supported authentication sources include:

```text
Bearer access token
OR
Web session cookie
```

Both produce the same application identity.

---

## 38. Bearer Precedence

If a Bearer header is present, it has precedence.

Conceptually:

```text
Bearer present?
   |
   +-- yes --> validate Bearer
   |              |
   |              +-- invalid --> reject
   |
   +-- no --> evaluate Web cookie
```

The backend must not silently ignore an invalid explicit Bearer credential and authenticate through a cookie instead.

---

## 39. Protected Routes

Most `/api/v1` application resources require a current authenticated user.

Examples include:

- Library;
- Shows;
- Movies;
- Search;
- Explore;
- Statistics;
- user/profile operations.

The exact route registration is defined by the running OpenAPI schema.

---

# Administrator Authorization

## 40. Administrator Dependency

Administrator-only endpoints require an authenticated user with Administrator privileges.

Conceptually:

```text
CurrentUser
   |
   v
is_admin?
   |
   +-- true --> continue
   |
   +-- false --> 403
```

---

## 41. Safe Administrator Error

A normal user attempting an Administrator-only operation receives a safe authorization error.

The current contract uses a stable concept such as:

```text
code = "admin_required"
```

with a safe message.

Frontend behavior should key off the error code where necessary.

---

## 42. Administrator API Areas

Administrator-only areas include capabilities such as:

- Server Health/diagnostics;
- Background Jobs administration;
- Security settings;
- administrative recovery;
- logs/admin functionality where exposed.

Future full User Management will also be Administrator-only.

---

## 43. Frontend Administrator Visibility

Flutter should use:

```text
user.isAdmin
```

to avoid rendering/loading Administrator-only capabilities for normal users.

This is UX optimization, not authorization.

---

# Logout

## 44. Current Session Logout

Logout revokes the current `AuthSession`.

Conceptually:

```text
Client
  |
  v
Logout
  |
  v
Revoke current session
  |
  v
Clear client credential state
```

---

## 45. Web Logout

For Web:

- revoke the current WEB session;
- clear/invalidate the Web cookie;
- transition frontend auth state to unauthenticated.

---

## 46. Native Logout

For native:

- revoke the current MOBILE session;
- clear local refresh credential;
- clear access-token state;
- transition to unauthenticated state.

---

## 47. Logout Everywhere

Logout everywhere revokes every `AuthSession` belonging to the current user.

It does not revoke sessions belonging to other users.

---

## 48. Other Devices After Logout Everywhere

Another client may not discover revocation until its next authenticated request/refresh.

When the backend rejects the revoked session, that client should transition to unauthenticated state.

---

# Password Recovery

## 49. Regular User Recovery

An Administrator can initiate recovery for a normal user.

The backend generates a temporary recovery credential/link.

---

## 50. Recovery Credential Properties

A recovery credential is:

- random;
- temporary;
- user-bound;
- hashed server-side;
- expiring;
- single-use.

It is not an access token.

---

## 51. Recovery Flow

Conceptually:

```text
Administrator
    |
    v
initiate recovery
    |
    v
temporary recovery link
    |
    v
User opens link
    |
    v
submit new password
    |
    v
validate/consume token
    |
    v
change password
    |
    v
revoke user's existing sessions
```

---

## 52. Recovery Token Failure

The backend rejects a recovery token that is:

- unknown;
- expired;
- already consumed;
- otherwise invalid.

The frontend should show a safe expired/invalid recovery state and must not repeatedly submit a consumed token.

---

## 53. Session Revocation After Recovery

After a successful password recovery, existing sessions for the recovered user are revoked.

This ensures old persistent credentials cannot continue authenticating after account recovery.

---

# Administrator Server-Side Recovery

## 54. Why Administrator Recovery Is Different

An Administrator may be the only person capable of changing application security settings or recovering other users.

If that Administrator cannot log in, relying solely on the authenticated Web UI would create a lockout cycle.

Therefore Administrator recovery is available server-side.

---

## 55. CLI Command

From the backend environment:

```bash
python -m app.admin.reset_password <username-or-email>
```

The new password is requested interactively using `getpass`.

---

## 56. Never Pass Password Through CLI Arguments

Do not use:

```bash
python -m app.admin.reset_password admin "new-password"
```

Passwords in process arguments can leak through shell history/process inspection.

The command intentionally prompts securely instead.

---

## 57. CLI Recovery Effects

After successful Administrator password reset:

- the password hash is updated;
- existing sessions for that user are revoked.

The password itself must not be written to logs/stdout.

---

# Mobile-to-Web Handoff

## 58. Purpose

An authenticated native user can open SofaWatch Web without manually logging in again.

This is achieved through a temporary handoff credential.

---

## 59. Handoff Flow

Conceptually:

```text
Authenticated Mobile App
        |
        v
request handoff
        |
        v
temporary credential
        |
        v
open browser
        |
        v
browser exchanges credential
        |
        v
new WEB AuthSession
        |
        v
HttpOnly Web cookie
```

---

## 60. Handoff Credential Properties

The handoff credential must be:

- short-lived;
- single-use;
- bound to the requesting user;
- unsuitable as a permanent access credential.

---

## 61. Handoff Is Not Token Transfer

The native access token or refresh credential should not simply be placed in a browser URL.

The handoff mechanism creates a separate temporary exchange credential specifically for this purpose.

---

## 62. Handoff Failure

The exchange must reject credentials that are:

- invalid;
- expired;
- already used.

The browser should then fall back to the normal authentication experience.

---

# Session Security

## 63. Persistent Credential Hashing

The database stores hashes of persistent credentials.

Examples include:

- Web session credentials;
- native refresh credentials;
- recovery credentials;
- handoff credentials where applicable.

The usable secret should only exist client-side/temporarily where required by the protocol.

---

## 64. Access Tokens vs Persistent Credentials

Short-lived access tokens and persistent credentials serve different purposes.

Do not increase access-token lifetime merely to avoid implementing refresh correctly.

The intended model is:

```text
short access token
+
persistent revocable session
```

---

## 65. Revocation

Server-side sessions make it possible to revoke persistent authentication.

Revocation is important for:

- logout;
- logout everywhere;
- password recovery;
- future account deactivation;
- security response.

---

## 66. Session Expiry

Clients must handle expired sessions as normal authentication lifecycle events.

Do not display raw database/session exceptions.

A client that cannot restore a valid session should return to the unauthenticated flow.

---

# API Error Semantics

## 67. Authentication Failure

Use:

```text
401 Unauthorized
```

for missing/invalid authentication.

Examples:

- missing credentials;
- invalid Bearer token;
- invalid/expired session.

---

## 68. Authorization Failure

Use:

```text
403 Forbidden
```

when authentication succeeded but the user is not permitted to perform the operation.

Example:

```text
normal user -> Administrator-only endpoint
```

---

## 69. Conflict

Authentication/setup operations may use a conflict response when state changed between discovery and mutation.

Example:

```text
two clients attempt first setup
```

The exact endpoint status/error code is defined by OpenAPI/current route tests.

---

## 70. Validation

Invalid request bodies are validated through FastAPI/Pydantic.

Clients should map validation failures safely.

Do not expose backend stack traces.

---

## 71. Stable Error Codes

Where the backend defines application error codes, frontend behavior should depend on those codes instead of matching message text.

Example:

```text
admin_required
```

Human-readable messages are presentation-oriented and may change.

---

# Client Responsibilities

## 72. Flutter Auth Layer

The Flutter authentication feature should centralize:

- bootstrap;
- Login;
- logout;
- session restoration;
- current user;
- native refresh;
- credential persistence abstraction;
- auth state transitions.

Feature widgets should not independently implement token refresh.

---

## 73. Repository Boundary

HTTP-specific behavior belongs in the data layer.

Conceptually:

```text
presentation
    |
application
    |
domain repository contract
    |
API repository
    |
ApiClient / Dio
```

Widgets should not manually construct authentication HTTP requests.

---

## 74. Web and Native Credential Strategy

The shared application layer should not require presentation code to understand raw credential mechanics.

Platform-aware infrastructure can determine whether the active client uses:

```text
Web cookie
```

or:

```text
native Bearer + refresh
```

while exposing a coherent auth state to the rest of the app.

---

## 75. Avoid Refresh Storms

When multiple native requests encounter an expired access token simultaneously, the client should coordinate refresh behavior.

Do not launch multiple independent refresh rotations using the same refresh credential.

Because rotation invalidates the old credential, parallel refresh attempts can conflict.

A single-flight/serialized refresh strategy is appropriate.

---

## 76. Retrying After Refresh

After a successful native token refresh, eligible failed requests may be retried using the new access token.

Avoid automatically retrying operations whose semantics make repetition unsafe unless the client knows the original request was not committed.

---

## 77. Authentication State Changes

When authentication becomes invalid, the frontend should update global auth state consistently.

Do not leave protected feature Cubits running as if the user remained authenticated.

User-scoped state may need to be cleared/recreated when the authenticated user changes.

---

# User Isolation

## 78. User-Owned Data

Authenticated identity scopes private resources such as:

- Library;
- viewing progress;
- Episode history;
- Movie history;
- ratings;
- Statistics;
- sessions.

Normal clients should not choose a `user_id` for these operations.

---

## 79. Switching Users

Logging out and logging in as another user must not retain the previous user's private application state in visible frontend caches/Cubits.

User-scoped state should be reset when authentication identity changes.

---

## 80. Administrator Does Not Imply Data Impersonation

Administrator privileges do not automatically mean normal user-scoped endpoints should expose another user's Library/history.

Any future impersonation/admin-inspection capability would require an explicit product/security design.

Do not infer it from `is_admin`.

---

# Security Settings

## 81. Security Settings Are Backend-Owned

Global settings such as Open Registration are persisted/enforced by the backend.

The frontend Administrator UI reflects and mutates that state through protected APIs.

---

## 82. Updating Open Registration

Conceptually:

```text
Administrator
    |
    v
Security API
    |
    v
update setting
    |
    v
backend persists
```

After success, the frontend should use the returned/refreshed backend state.

---

## 83. Normal Users

Normal users must not be able to update global Security settings.

Frontend hides the controls; backend returns authorization failure if called directly.

---

# Production Considerations

## 84. HTTPS

Production authentication must be served over HTTPS.

This protects:

- passwords in transit;
- cookies;
- access tokens;
- refresh credentials;
- recovery/handoff exchanges.

---

## 85. Secure Cookies

Production Web sessions should use the `Secure` cookie flag under HTTPS.

Development HTTP behavior may differ according to environment configuration.

---

## 86. Reverse Proxy

A production reverse proxy must preserve authentication-relevant headers/cookies correctly.

Proxy configuration must not accidentally:

- strip cookies;
- downgrade HTTPS assumptions;
- expose backend ports unnecessarily;
- log sensitive authorization headers.

---

## 87. CORS

CORS origins should be explicit for browser deployments.

Do not use wildcard origins with credentialed Web authentication as a production shortcut.

---

# Testing

## 88. Backend Authentication Tests

Important backend test areas include:

- setup required/no users;
- first account becomes Administrator;
- concurrent setup protection;
- Login success/failure;
- Web session creation;
- native session creation;
- access-token authentication;
- refresh rotation;
- old refresh reuse rejection;
- Web cookie authentication;
- Bearer precedence;
- logout;
- logout everywhere;
- Open Registration enforcement;
- Administrator authorization;
- password change;
- recovery token expiry/single-use;
- session revocation after recovery;
- Mobile-to-Web handoff expiry/single-use.

---

## 89. Frontend Authentication Tests

Important frontend test areas include:

- Setup vs Login routing;
- Login loading/success/failure;
- session restoration;
- native refresh;
- replacement of rotated credential;
- logout;
- auth-state reset;
- Administrator UI visibility;
- Sign Up visibility based on registration state;
- recovery flow;
- handoff initiation where applicable.

---

## 90. Security Regression Tests

Authentication/security bugs should generally receive focused regression tests.

Examples:

```text
invalid Bearer must not fall back to cookie
```

```text
old refresh credential fails after rotation
```

```text
normal user cannot access Server Health
```

```text
second first-run setup cannot create another Administrator
```

These are invariants, not implementation details.

---

# Debugging

## 91. Web Session Not Restoring

Check:

1. backend URL;
2. cookie exists;
3. cookie is sent;
4. CORS credentials;
5. session exists;
6. session not expired/revoked;
7. user active;
8. bootstrap/current-user response.

Do not move the Web session credential to localStorage to diagnose the issue.

---

## 92. Native Session Not Restoring

Check:

1. refresh credential exists in secure storage;
2. app points to correct backend;
3. corresponding `AuthSession` exists;
4. session is valid;
5. stored credential is the latest rotated value;
6. refresh response is mapped correctly.

---

## 93. Unexpected 401

Check:

- access token expired;
- Bearer header malformed;
- stale Bearer attached to Web request;
- Web cookie missing;
- session revoked;
- wrong backend/database.

---

## 94. Unexpected 403

Check:

- user authenticated;
- `is_admin`;
- route requires Administrator;
- account state;
- authorization dependency.

Do not convert a `403` into `401` in the frontend just to route to Login.

---

## 95. Setup Appears Again

Check whether the client is pointing to another/new SQLite database.

A different database can legitimately have no users and therefore report setup required.

Client uninstall/reinstall does not delete server accounts.

---

# Invariants

The following authentication invariants should remain true:

```text
[ ] no legacy local-user concept
[ ] first real user becomes Administrator
[ ] setup is unavailable after first account exists
[ ] Open Registration defaults to false
[ ] public registration obeys backend setting
[ ] passwords use Argon2
[ ] Web persistent auth uses HttpOnly cookie
[ ] native access tokens are short-lived
[ ] native refresh credentials rotate
[ ] old refresh credentials cannot be reused
[ ] persistent credentials are hashed server-side
[ ] explicit invalid Bearer does not fall back to cookie
[ ] logout revokes current session
[ ] logout everywhere revokes only current user's sessions
[ ] recovery credentials expire and are single-use
[ ] password recovery revokes existing user sessions
[ ] Administrator recovery exists server-side
[ ] Mobile-to-Web handoff is temporary and single-use
[ ] frontend Admin visibility never replaces backend authorization
```

---

## Related Documentation

- [API Overview](overview.md)
- [Frontend API Contract](frontend-contract.md)
- [Authentication Architecture](../architecture/authentication.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Configuration](../development/configuration.md)
- [Debugging](../development/debugging.md)
- [Testing](../development/testing.md)
- [Implementation Status](../features/implementation-status.md)
