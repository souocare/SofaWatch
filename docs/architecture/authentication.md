# Authentication Architecture

This document describes the authentication, session, authorization, setup, registration, and recovery architecture used by SofaWatch.

Authentication is designed for a self-hosted multi-user application with both browser and native Flutter clients.

The architecture deliberately uses different persistent credential mechanisms for Web and native clients while resolving both to the same backend `User` and `AuthSession` model.

> [!IMPORTANT]
> Authentication and authorization are backend responsibilities. Frontend visibility rules improve the user experience but are never security boundaries.

---

## 1. Goals

The authentication architecture is designed to provide:

- real multi-user accounts
- secure password storage
- persistent Web login
- persistent native/mobile login
- short-lived API access credentials
- revocable server-side sessions
- rotating mobile refresh credentials
- Administrator authorization
- secure first-run setup
- configurable public registration
- password recovery
- server-side Administrator recovery
- Mobile-to-Web authentication handoff
- logout of one session
- logout of all sessions

The architecture should remain understandable and maintainable for a self-hosted deployment.

---

## 2. High-Level Model

At a high level:

```text
                       ┌──────────────┐
                       │     User     │
                       └──────┬───────┘
                              │
                              │ owns
                              v
                       ┌──────────────┐
                       │ AuthSession  │
                       └──────┬───────┘
                              │
                  ┌───────────┴───────────┐
                  │                       │
                  v                       v
            Web Session             Mobile Session
                  │                       │
                  v                       v
          HttpOnly credential      Refresh credential
                                          │
                                          v
                                  Short-lived access token
```

`User` represents identity.

`AuthSession` represents a persistent authenticated session/device/browser context.

Access tokens represent short-lived API authorization rather than persistent login state.

---

## 3. User Accounts

SofaWatch uses real user accounts.

The old fixed/local-user concept has been removed and should not be reintroduced.

A user account can contain identity/security information such as:

- username
- email
- display name
- password hash
- active state
- Administrator state

User-owned application data remains associated with the internal SofaWatch user ID.

This includes data such as:

- Library
- progress
- watch history
- ratings
- sessions

---

## 4. Password Storage

Passwords are never stored in plaintext.

SofaWatch uses Argon2 for password hashing.

Conceptually:

```text
Password
   |
   v
Argon2
   |
   v
Password Hash
   |
   v
Database
```

Authentication compares the submitted password against the stored hash.

The original password must not be recoverable from the database.

Passwords must never be:

- written to logs
- returned through API responses
- printed by administrative tools
- stored in configuration
- passed as command-line arguments to recovery commands

---

## 5. Authentication vs Authorization

Authentication answers:

```text
Who is making this request?
```

Authorization answers:

```text
Is this user allowed to perform this operation?
```

These concerns should remain separate.

Example:

```text
Request
   |
   v
Authenticate
   |
   v
Current User
   |
   v
Authorize Administrator?
   |
   +-- yes --> operation
   |
   +-- no  --> 403
```

A successfully authenticated user is not automatically authorized for Administrator functionality.

---

## 6. AuthSession

Persistent login state is represented by `AuthSession`.

Sessions distinguish client types such as:

```text
WEB
MOBILE
```

A session can support lifecycle information such as:

- creation
- expiration
- revocation
- last use
- persistent credential validation

Persistent credentials should be stored server-side only in hashed form.

This allows sessions to be individually revoked without changing the user's password.

---

## 7. Access Tokens

Access tokens are short-lived credentials used to authenticate API requests.

They are not the persistent login mechanism.

Conceptually:

```text
Authenticated Session
        |
        v
Short-lived Access Token
        |
        v
Authenticated API Requests
```

Short lifetime limits the impact of a leaked access token.

Long-lived authentication should instead be backed by an `AuthSession`.

---

## 8. Unified Current User Resolution

Backend protected endpoints resolve authentication through a common current-user dependency.

Supported authentication methods include:

- Bearer access token
- Web HttpOnly session cookie

Both ultimately resolve to the same `User`.

Conceptually:

```text
HTTP Request
     |
     v
CurrentUserDependency
     |
     +---- Bearer token ----+
     |                      |
     +---- Web cookie ------+
                            |
                            v
                           User
```

Application services should not need separate Web-user and Mobile-user concepts.

---

## 9. Bearer Precedence

If an explicit Bearer credential is present, it takes precedence.

An invalid explicit Bearer token must not silently fall back to a valid Web cookie.

Correct behavior:

```text
Authorization: Bearer <invalid>
Cookie: valid_web_session

             |
             v

           401
```

Not:

```text
invalid Bearer
     |
     v
ignore it
     |
     v
authenticate using cookie
```

This avoids ambiguous authentication behavior and credential confusion.

---

# 10. Web Authentication

Web authentication is designed around a server-managed persistent session.

Persistent Web authentication uses an HttpOnly cookie.

Conceptually:

```text
Login
  |
  v
Backend validates credentials
  |
  v
Create WEB AuthSession
  |
  v
Set HttpOnly session cookie
  |
  v
Browser persists session
```

The browser automatically sends the cookie to the SofaWatch backend when allowed by cookie/CORS rules.

---

## 10.1 Web Session Cookie

The persistent Web credential should use security properties such as:

```text
HttpOnly
SameSite=Lax
Path=/
```

In production over HTTPS:

```text
Secure=true
```

`HttpOnly` prevents JavaScript from reading the persistent session credential.

The Flutter Web application therefore does not need direct access to the persistent cookie value.

---

## 10.2 Web Session Restoration

When the application starts, the Web client can ask the backend to restore the authenticated session.

Conceptually:

```text
Browser reload
     |
     v
Session restore request
     |
     +-- browser sends HttpOnly cookie automatically
     |
     v
Backend validates WEB AuthSession
     |
     v
Authenticated application state
```

This allows browser refreshes/restarts without storing a long-lived token in JavaScript-accessible storage.

---

## 10.3 Web API Access

The Web client may use short-lived access credentials for API requests after restoring/establishing a persistent session.

The important distinction is:

```text
Persistent login
    = HttpOnly Web session

API authorization
    = short-lived access credential / authenticated session flow
```

Persistent browser authentication should not depend on storing a long-lived access token in local storage.

---

# 11. Mobile Authentication

Native clients use a different persistence mechanism.

Mobile authentication uses:

```text
Short-lived access token
        +
Rotating refresh credential
```

Conceptually:

```text
Login
  |
  v
Create MOBILE AuthSession
  |
  +--> access token
  |
  +--> refresh credential
```

The access token is used for normal API requests.

The refresh credential allows the native client to obtain a new access token without asking for the password again.

---

## 11.1 Refresh Credential Storage

The persistent mobile credential belongs to the `AuthSession`.

The server stores only a hash of the refresh credential.

Conceptually:

```text
Mobile device
    |
    | actual refresh credential
    |
    v
Backend
    |
    | hash()
    |
    v
Stored credential hash
```

A database leak should not directly expose usable refresh credentials.

---

## 11.2 Refresh Rotation

Refresh credentials rotate on successful use.

Example:

```text
Credential A
     |
     | refresh
     v
Credential B
```

After successful rotation:

```text
Credential A = invalid
Credential B = current
```

The client must persist the new credential.

---

## 11.3 Old Credential Reuse

A previously rotated credential must not remain valid.

Conceptually:

```text
Credential A used successfully
        |
        v
Credential A invalidated
        |
        v
Credential A used again
        |
        v
       Reject
```

Rotation limits the useful lifetime of copied refresh credentials.

---

# 12. Authentication State in Flutter

The frontend exposes authentication through application state rather than requiring pages to understand credential mechanics.

Conceptually:

```text
AuthRepository
      |
      v
AuthCubit
      |
      v
Presentation / Router
```

The authentication application layer can represent states such as:

```text
Checking
Unauthenticated
Authenticated
Failure
```

Platform-specific persistence remains behind the repository/data boundary.

---

## 12.1 Web Repository Behavior

Web auth repository behavior can include:

- login
- restore Web session
- logout
- logout everywhere
- obtain/refresh short-lived API access where required

The persistent HttpOnly cookie remains browser/backend-managed.

---

## 12.2 Mobile Repository Behavior

Native auth repository behavior can include:

- login
- store refresh credential
- refresh access token
- rotate stored refresh credential
- logout
- clear local credential state

Presentation should not directly read/write the refresh credential.

---

# 13. Initial Setup

A new SofaWatch installation may have no users.

In that state:

```text
setup_required = true
```

The frontend should show Setup instead of Login.

Flow:

```text
No users
   |
   v
Setup Required
   |
   v
Create first account
   |
   v
Account becomes Administrator
   |
   v
Setup disabled
```

The first account is a normal persistent SofaWatch account, not a special temporary/local user.

---

## 13.1 First Administrator

The first successfully created account becomes Administrator automatically.

This bootstraps administration without requiring a hardcoded default account.

After the first account exists, the setup endpoint must no longer allow additional bootstrap accounts.

---

## 13.2 Concurrent Setup Protection

The backend must protect against concurrent first-user creation.

Two simultaneous requests must not both conclude that they are creating the first Administrator.

This guarantee belongs to the backend/database transaction boundary.

The frontend cannot provide this protection.

---

# 14. Public Registration

After initial setup, public account creation is controlled by:

```text
Open Registration
```

Default:

```text
false
```

Only an Administrator can change this setting.

---

## 14.1 Registration Closed

When registration is closed:

```text
Frontend
  |
  +-- does not show Sign Up

Backend
  |
  +-- rejects public registration
```

The backend rule is authoritative.

A client cannot bypass registration policy by manually calling the endpoint.

---

## 14.2 Registration Open

When enabled by an Administrator, the Login experience may expose Sign Up.

New registrations create normal non-Administrator accounts unless another explicit administrative rule says otherwise.

Public registration must never create another Administrator automatically.

---

# 15. Administrator Authorization

Administrative routes require explicit backend authorization.

Conceptually:

```text
Request
   |
   v
CurrentUserDependency
   |
   v
AdminUserDependency
   |
   +-- is_admin == true --> continue
   |
   +-- otherwise --------> 403
```

Administrator UI may include:

- server health
- diagnostics
- background jobs
- logs
- security settings
- administrative recovery
- future user management

Hiding these sections from non-Administrators is useful UX but not security.

---

# 16. Active/Inactive Users

User active state belongs to backend account policy.

A deactivated user should not be able to establish a valid authenticated state.

Future Administrator user-management work is expected to support account activation/deactivation.

When implemented, deactivation should revoke existing sessions so previously authenticated devices do not remain active.

> [!NOTE]
> Full Administrator user-management and activation/deactivation UI are planned work, not necessarily part of the current completed authentication feature set.

---

# 17. Logout

SofaWatch distinguishes normal logout from global logout.

---

## 17.1 Logout

Normal logout revokes the current `AuthSession`.

Conceptually:

```text
Current Device/Browser
        |
        v
Logout
        |
        v
Revoke current AuthSession
        |
        v
Clear client-side authentication state
```

Other sessions owned by the same user remain active.

---

## 17.2 Log Out Everywhere

`Log out everywhere` revokes all sessions owned by the current user.

Conceptually:

```text
User
 |
 +-- Session A
 +-- Session B
 +-- Session C

Log out everywhere

Session A -> revoked
Session B -> revoked
Session C -> revoked
```

Sessions belonging to other users are unaffected.

---

# 18. Password Change

An authenticated user can change their password when they know the current password.

Conceptually:

```text
Current password
New password
      |
      v
Verify current password
      |
      v
Hash new password
      |
      v
Persist new hash
```

The backend owns validation and persistence.

Username editing is deliberately deferred and should not be treated as missing password/account functionality.

---

# 19. Regular User Password Recovery

An Administrator can initiate password recovery for a regular user.

The backend creates a temporary recovery credential.

Properties:

- random
- short-lived
- user-bound
- stored as a hash
- single-use

Conceptually:

```text
Administrator
     |
     v
Create recovery
     |
     v
Temporary recovery link
     |
     v
User chooses new password
     |
     v
Token consumed
     |
     v
Existing sessions revoked
```

---

## 19.1 Recovery Credential Storage

The actual recovery token should not be stored in plaintext.

```text
Generated Token
    |
    +--> returned once for recovery URL
    |
    v
hash()
    |
    v
Database
```

Validation hashes the presented credential and compares it with the stored value.

---

## 19.2 Single Use

After successful recovery, the credential becomes invalid.

A second use must fail.

Expired credentials must also fail.

---

## 19.3 Session Revocation After Recovery

Successful password recovery revokes existing sessions for the affected user.

This prevents a previously authenticated device from remaining trusted after account recovery.

---

# 20. Administrator Password Recovery

An Administrator must not depend on being able to log into the Web UI to recover their own account.

SofaWatch therefore provides a server-side command:

```bash
python -m app.admin.reset_password <username-or-email>
```

The new password is requested interactively through `getpass`.

It must not be passed as a CLI argument.

---

## 20.1 CLI Security Rules

The recovery command must not:

- echo the password
- include the password in process arguments
- log the password
- print the resulting password hash unnecessarily

After changing the password, existing sessions for the account are revoked.

---

# 21. Mobile-to-Web Authentication Handoff

A user authenticated on mobile can open SofaWatch Web without manually entering credentials again.

The flow uses a dedicated temporary handoff credential.

Conceptually:

```text
Authenticated Mobile App
          |
          v
Request Web handoff
          |
          v
Temporary credential
          |
          v
Open browser URL
          |
          v
Web exchanges credential
          |
          v
Create WEB AuthSession
          |
          v
Authenticated Web client
```

---

## 21.1 Handoff Properties

The handoff credential is:

- temporary
- short-lived
- user-bound
- single-use

It is not:

- a long-lived access token
- a mobile refresh credential
- a reusable Web session credential

---

## 21.2 Handoff Failure Cases

The backend rejects a handoff credential that is:

- invalid
- expired
- already consumed

The browser should show a safe authentication failure rather than expose token details.

---

# 22. Session Revocation

Session revocation is central to the authentication model.

Revocation supports:

- logout
- logout everywhere
- password recovery
- future account deactivation
- administrative/security responses

Because persistent authentication is represented server-side, revocation can take effect without waiting for a long-lived client token to expire.

Short-lived access tokens may still have a limited remaining lifetime depending on the exact validation strategy, which is one reason their lifetime should remain short.

---

# 23. Session Last-Used Tracking

`AuthSession` can track usage information such as last-used time.

This can support:

- operational visibility
- future session management UI
- identifying stale sessions
- user security controls

Tracking should not become unnecessary surveillance or collect more device information than required for the product.

---

# 24. Cookie and CORS Relationship

Web authentication relies on browser cookies.

Therefore the backend CORS configuration must support credentials for approved frontend origins.

Conceptually:

```text
Flutter Web Origin
       |
       | credentialed request
       v
FastAPI
       |
       +-- allowed origin?
       +-- credentials allowed?
       |
       v
Web session cookie accepted
```

CORS does not replace authentication or authorization.

---

# 25. Production HTTPS

Production Web authentication should run behind HTTPS.

The persistent Web cookie should use:

```text
Secure=true
```

when served over HTTPS.

A future production/self-hosting guide should document the reverse-proxy and HTTPS setup.

Development over localhost may require different cookie behavior.

---

# 26. Authentication Error Handling

Authentication errors should be explicit and safe.

Typical outcomes include:

```text
401 Unauthorized
403 Forbidden
```

Use:

- `401` when valid authentication is missing or cannot be established
- `403` when the user is authenticated but lacks permission

The frontend should map these into appropriate user-facing states without exposing internal token/session details.

---

# 27. Sensitive Data Rules

Never expose sensitive authentication material through:

- logs
- diagnostics
- Administrator UI
- API errors
- analytics
- debug output
- exported application data unless explicitly and safely required

Sensitive material includes:

- passwords
- password hashes
- access tokens
- refresh credentials
- refresh credential hashes
- Web session credentials
- recovery credentials
- handoff credentials
- authentication signing secrets

---

# 28. API Boundary

Authentication routes are intentionally separate from ordinary application resources.

Some authentication endpoints must be public because authentication cannot already be required to use them.

Examples include flows for:

- setup status
- initial setup
- login
- registration where allowed
- refresh/session restoration where applicable
- recovery token consumption
- Web handoff exchange

Other operations require an authenticated user.

Examples include:

- logout
- logout everywhere
- password change
- creating a Mobile-to-Web handoff
- account-specific operations

Administrative security operations require Administrator authorization.

---

# 29. Frontend Routing Boundary

The frontend should derive navigation from authentication/setup state.

Conceptually:

```text
Application Startup
       |
       v
Check server/setup/auth state
       |
       +-- setup required --> Setup
       |
       +-- authenticated --> Application
       |
       +-- otherwise -----> Login
```

The router should not assume that every configured server already contains users.

---

# 30. Registration UI Boundary

The frontend may query server state to determine whether registration is available.

When registration is closed, Sign Up should not be offered.

However:

```text
UI hidden != authorization
```

The registration endpoint must independently enforce the current security setting.

---

# 31. Credential Ownership

Credential responsibilities should remain clear.

| Credential | Persistent? | Client | Server storage |
| --- | --- | --- | --- |
| Password | User knowledge | Web/Mobile | Argon2 hash |
| Access token | Short-lived | Web/Mobile API use | Validated through token security model |
| Web session credential | Persistent session | Browser cookie | Hash/server session state |
| Mobile refresh credential | Persistent session | Native client | Hash/server session state |
| Recovery credential | Temporary | Recovery flow | Hash |
| Web handoff credential | Temporary | Mobile → Browser | Hash/state required for one-time validation |

This separation prevents one credential type from gradually becoming a universal long-lived token.

---

# 32. Why Web and Mobile Differ

Browser and native applications have different security/storage capabilities.

For Web:

```text
HttpOnly cookie
```

provides a strong boundary because JavaScript cannot directly read the persistent session credential.

For native applications:

```text
rotating refresh credential
```

provides persistent authentication while allowing short-lived access tokens.

Trying to force both platforms into the same persistent-token storage model would weaken the design.

---

# 33. Why Access Tokens Stay Short-Lived

Access tokens are frequently presented to API endpoints.

Keeping them short-lived reduces the impact of accidental exposure.

Persistent authentication remains tied to revocable server-side sessions instead.

Conceptually:

```text
Long-lived trust
      |
      v
AuthSession
      |
      v
Short-lived API credential
```

---

# 34. Why Persistent Credentials Are Hashed

Persistent credentials function similarly to high-value secrets.

If stored in plaintext, database access could immediately reveal usable session credentials.

Hashing changes the validation model to:

```text
Presented Credential
        |
        v
Hash
        |
        v
Compare with stored hash
```

This is used for persistent session/recovery-style credentials where the server does not need to recover the original secret.

---

# 35. Why the First User Becomes Administrator

Self-hosted installations need a secure bootstrap path.

Hardcoded default credentials would be undesirable.

Instead:

```text
Empty installation
       |
       v
User chooses credentials
       |
       v
First account becomes Administrator
```

Afterward, normal security policy takes over.

---

# 36. Why Open Registration Defaults to Off

A self-hosted service may be reachable beyond the local machine.

Automatically allowing anyone who can reach the server to create an account would be an unsafe default.

Therefore:

```text
Open Registration = false
```

The Administrator explicitly opts in if public registration is wanted.

---

# 37. Why Administrator Recovery Exists Outside the UI

If the only Administrator forgets their password, requiring Administrator Web access to recover the account creates a circular dependency.

A server-side recovery command provides an operational escape hatch for the person who controls the self-hosted installation.

---

# 38. Testing Strategy

Authentication should be tested at multiple layers.

---

## 38.1 Password Tests

Validate:

- hashing
- correct password verification
- incorrect password rejection
- password changes

---

## 38.2 Token Tests

Validate:

- access token creation
- validation
- expiration
- invalid credentials
- wrong token type where applicable

---

## 38.3 Session Tests

Validate:

- creation
- lookup
- expiration
- revocation
- last-used behavior
- user ownership
- Web vs Mobile session behavior

---

## 38.4 Refresh Tests

Validate:

- successful refresh
- rotation
- old credential rejection
- expired session rejection
- revoked session rejection

---

## 38.5 Current User Dependency Tests

Validate:

- valid Bearer
- invalid Bearer
- valid Web cookie
- expired/revoked Web session
- Bearer precedence
- no silent fallback after invalid explicit Bearer
- inactive user rejection

---

## 38.6 Authorization Tests

Validate:

- Administrator access succeeds
- normal user receives 403
- frontend visibility is not required for backend protection

---

## 38.7 Setup Tests

Validate:

- setup required when no users exist
- first account becomes Administrator
- setup unavailable afterward
- concurrent first-user protection

---

## 38.8 Registration Tests

Validate:

- closed by default
- closed registration rejected by backend
- Administrator can change setting
- normal user cannot change setting
- registration works when open
- new public user does not become Administrator

---

## 38.9 Recovery Tests

Validate:

- recovery credential generation
- expiration
- single use
- wrong-user behavior
- password replacement
- session revocation

---

## 38.10 Handoff Tests

Validate:

- creation for authenticated mobile user
- successful Web exchange
- expiration
- invalid credential
- single use
- user binding

---

## 38.11 Frontend Tests

Validate:

- setup vs Login routing
- login success/failure
- session restoration
- registration visibility
- mobile refresh behavior
- logout
- logout everywhere
- Administrator-only UI visibility
- handoff behavior where applicable

---

# 39. Anti-Patterns to Avoid

Do not:

- reintroduce the legacy local user
- store passwords in plaintext
- store persistent server credentials in plaintext
- use long-lived access tokens as session persistence
- expose Web session cookies to JavaScript
- silently fall back to cookie auth after an invalid Bearer token
- trust frontend Administrator visibility as authorization
- allow setup after the first user exists
- make public registration open by default
- pass Administrator recovery passwords through CLI arguments
- reuse consumed recovery credentials
- reuse rotated refresh credentials
- use the Mobile-to-Web handoff as a permanent token
- log authentication secrets
- duplicate platform credential logic throughout presentation code

---

# 40. Future Authentication Work

Known future work includes:

- full Administrator user-management UI
- account activation/deactivation
- richer session-management UI if useful
- production cookie/HTTPS deployment documentation
- additional security audit before stable release

Username editing remains deliberately deferred unless the product decision changes.

---

## Related Documentation

- [Architecture Overview](overview.md)
- [Backend Architecture](backend.md)
- [Frontend Architecture](frontend.md)
- [Implementation Status](../features/implementation-status.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
