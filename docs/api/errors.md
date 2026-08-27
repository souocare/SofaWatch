# API Errors

This document defines the SofaWatch API error contract and the expected error-handling boundary between the FastAPI backend and Flutter clients.

The goals are:

- predictable machine-readable errors;
- safe human-readable messages;
- consistent HTTP semantics;
- structured validation details;
- separation between technical failures and UI messages;
- reliable retry behavior;
- compatibility as the API evolves.

For exact endpoint-specific responses, use the current FastAPI OpenAPI documentation and route tests.

---

## 1. Error Handling Principles

SofaWatch treats expected API failures as part of the application contract.

The backend should:

- use appropriate HTTP status codes;
- return a stable machine-readable error code;
- return a safe human-readable message;
- include structured details only when useful;
- avoid leaking implementation details or secrets.

The frontend should:

- map transport failures into application exceptions;
- prefer stable error codes over matching message text;
- classify network, validation, authorization, server, and data errors;
- display safe UI messages;
- preserve technical errors for logging/debugging only;
- retry only when retrying makes sense.

Conceptually:

```text
Backend failure
      |
      v
HTTP status + structured error
      |
      v
Dio
      |
      v
ApiExceptionMapper
      |
      v
AppException
      |
      v
AppErrorMessageMapper
      |
      v
Safe UI message
```

---

# Backend Error Contract

## 2. Canonical Error Envelope

Expected backend errors use this shape:

```json
{
  "error": {
    "code": "show_not_found",
    "message": "The requested TV show could not be found."
  }
}
```

The top-level `error` object is the stable error envelope.

Its core fields are:

| Field | Type | Purpose |
| --- | --- | --- |
| `code` | string | Stable machine-readable error identifier |
| `message` | string | Safe human-readable fallback message |
| `details` | array, optional | Structured additional information |

Clients should not assume `details` is present.

---

## 3. Error Code

`error.code` is intended for programmatic handling.

Example:

```json
{
  "error": {
    "code": "admin_required",
    "message": "Administrator access is required."
  }
}
```

Frontend logic may safely use:

```text
code == "admin_required"
```

when behavior must differ for that condition.

It should not depend on:

```text
message == "Administrator access is required."
```

Messages may evolve or eventually be localized.

---

## 4. Error Message

`error.message` is a safe fallback description.

It should:

- explain the failure without exposing internals;
- avoid stack traces;
- avoid SQL/database details;
- avoid provider secrets;
- avoid tokens or credentials;
- avoid unnecessary implementation details.

The Flutter UI may replace it with a friendlier message based on `code` or error type.

---

## 5. Error Details

Expected application errors may optionally include:

```json
{
  "error": {
    "code": "validation_error",
    "message": "The request contains invalid data.",
    "details": [
      {
        "field": "display_name",
        "message": "String should have at least 1 character."
      }
    ]
  }
}
```

Details are intended for structured context, especially validation.

They are not a place for arbitrary exception dumps.

---

# APIError

## 6. Expected Application Errors

The backend defines `APIError` as the shared exception for expected API failures.

Its conceptual contract is:

```python
APIError(
    status_code=...,
    code=...,
    message=...,
    details=...,
)
```

It carries:

```text
status_code
code
message
details
```

The global API error handler converts it into the canonical error envelope.

---

## 7. When to Use APIError

Use `APIError` when the failure is an expected application condition that should have a deliberate public API representation.

Examples:

- requested resource does not exist;
- Administrator permission is required;
- operation conflicts with current state;
- a provider-backed operation cannot be completed in a known way;
- an application validation/business rule fails.

Do not use it merely to hide programming bugs.

---

## 8. APIError Handler

The global handler converts:

```text
APIError
```

into:

```json
{
  "error": {
    "code": "...",
    "message": "...",
    "details": []
  }
}
```

`details` is omitted when it is `null`.

The HTTP status is taken from the exception.

---

# HTTP Exceptions

## 9. FastAPI / Starlette HTTP Exceptions

FastAPI and Starlette `HTTPException` failures are normalized by the global HTTP exception handler.

They use:

```json
{
  "error": {
    "code": "http_error",
    "message": "..."
  }
}
```

The original HTTP status is preserved.

If the original `detail` is not a string, SofaWatch falls back to a safe generic message.

---

## 10. `http_error` Is Generic

`http_error` represents a normalized framework-level HTTP error.

It is intentionally less specific than application error codes.

The Flutter message mapper therefore does not assign a special user-facing message to `http_error`; normal status/type mapping can provide the fallback behavior.

For application conditions where clients benefit from a stable semantic code, prefer `APIError` with a specific code.

---

# Request Validation

## 11. Pydantic / FastAPI Validation Errors

Request validation failures are normalized into the same error envelope.

HTTP status:

```text
422 Unprocessable Entity
```

Error code:

```text
validation_error
```

Response:

```json
{
  "error": {
    "code": "validation_error",
    "message": "The request contains invalid data.",
    "details": [
      {
        "field": "email",
        "message": "Value is not a valid email address."
      }
    ]
  }
}
```

---

## 12. Validation Detail Shape

A validation detail may contain:

```text
field
message
context
```

Example:

```json
{
  "field": "password",
  "message": "String should have at least 8 characters.",
  "context": {
    "min_length": 8
  }
}
```

`context` is optional.

---

## 13. Safe Validation Context

Only simple values are copied into validation context:

```text
string
integer
float
boolean
null
```

Complex internal objects are not serialized into the public error response.

This keeps validation output predictable and safer.

---

## 14. Validation Field Paths

Framework location prefixes such as:

```text
body
path
query
header
cookie
```

are removed when constructing the public field path.

Nested fields may therefore appear as:

```text
profile.display_name
```

rather than:

```text
body.profile.display_name
```

---

# HTTP Status Semantics

## 15. 400 — Bad Request

Use `400` for malformed or semantically invalid requests when the condition is not the standard FastAPI schema-validation case.

Do not use `400` as the universal error status.

---

## 16. 401 — Unauthorized

`401` means authentication is missing or invalid.

Examples:

- missing required authentication;
- invalid access token;
- expired/invalid session;
- unusable authentication credential.

Frontend classification:

```text
AppExceptionType.unauthorized
```

---

## 17. 403 — Forbidden

`403` means the request is authenticated but the user does not have permission.

Example:

```text
normal user
    |
    v
Administrator endpoint
    |
    v
403
```

Frontend classification:

```text
AppExceptionType.forbidden
```

Do not treat every `403` as a reason to show Login.

---

## 18. 404 — Not Found

`404` means the requested resource could not be found or is not accessible through that resource identity.

Examples of current frontend-recognized semantic codes include:

```text
show_not_found
season_not_found
episode_not_found
movie_not_found
library_entry_not_found
background_job_not_found
```

Frontend classification:

```text
AppExceptionType.notFound
```

---

## 19. 409 — Conflict

`409` represents an operation that conflicts with current server state.

Examples can include:

- state changed between read and mutation;
- setup was completed concurrently;
- operation cannot be applied to the current state.

Frontend classification:

```text
AppExceptionType.conflict
```

A conflict is not necessarily retryable without first refreshing state.

---

## 20. 422 — Validation

Standard request validation uses:

```text
422
```

Frontend classification:

```text
AppExceptionType.validation
```

The UI may use structured `details` for field-level feedback where appropriate.

---

## 21. 5xx — Server Errors

Responses with status:

```text
>= 500
```

are classified by Flutter as:

```text
AppExceptionType.server
```

These indicate that the server could not successfully complete an otherwise valid request.

Server errors are considered retryable by the shared frontend exception model.

Retry should still be user-controlled or feature-appropriate rather than an uncontrolled retry loop.

---

## 22. 503 — Service Unavailable

A temporarily unavailable SofaWatch service may use:

```text
service_unavailable
```

The current frontend message mapper recognizes this code and presents:

```text
The SofaWatch service is temporarily unavailable.
```

`503` remains a server-class failure.

---

# Health and Availability Errors

## 23. `server_unhealthy`

The frontend recognizes:

```text
server_unhealthy
```

and maps it to a user-safe message indicating that the server is reachable but unhealthy.

This distinction is useful because:

```text
connection failure
!=
reachable but degraded/unhealthy server
```

---

## 24. Connection Failure

If Dio cannot reach the backend, there is no backend error envelope.

Examples:

- server is offline;
- incorrect server address;
- network unavailable;
- connection refused.

Flutter maps this to:

```text
AppExceptionType.connection
```

Default application message:

```text
Could not connect to the server.
```

The user-facing mapper provides additional guidance to check the address/network.

---

# Timeouts

## 25. Connection Timeout

Dio:

```text
DioExceptionType.connectionTimeout
```

maps to:

```text
AppExceptionType.connectionTimeout
```

This is considered:

```text
network error = true
timeout = true
retryable = true
```

---

## 26. Send Timeout

Dio:

```text
DioExceptionType.sendTimeout
```

maps to:

```text
AppExceptionType.sendTimeout
```

This is also classified as a retryable network timeout.

Care is still required when retrying mutations if it is uncertain whether the server received/committed the request.

---

## 27. Receive Timeout

Dio:

```text
DioExceptionType.receiveTimeout
```

maps to:

```text
AppExceptionType.receiveTimeout
```

This means the server did not respond within the configured receive window.

It is considered retryable.

---

## 28. Transform Timeout

Dio transform timeouts currently map to:

```text
AppExceptionType.receiveTimeout
```

from the application's perspective.

This keeps the public error taxonomy simpler than Dio's full transport taxonomy.

---

# TLS and Cancellation

## 29. Bad Certificate

Dio:

```text
DioExceptionType.badCertificate
```

maps to:

```text
AppExceptionType.badCertificate
```

Safe UI message:

```text
The server certificate could not be verified.
```

Do not automatically bypass certificate verification to make this error disappear.

---

## 30. Cancelled Request

Dio:

```text
DioExceptionType.cancel
```

maps to:

```text
AppExceptionType.cancelled
```

Cancellation is not automatically retryable.

It may be an intentional consequence of:

- navigation;
- replacing a stale Search request;
- explicit cancellation.

---

# Invalid and Unexpected Responses

## 31. Bad HTTP Response

A non-success HTTP response that does not map to one of the explicitly classified status categories becomes:

```text
AppExceptionType.badResponse
```

This is distinct from:

```text
server returned successful HTTP but invalid application data
```

---

## 32. Invalid API Error Envelope

When a Dio bad response contains JSON that cannot be parsed as the SofaWatch error envelope, the frontend does not crash while trying to extract the error.

It falls back to status-based classification and a safe fallback message.

This provides compatibility with:

- reverse proxy error pages;
- malformed responses;
- unexpected server responses.

---

## 33. Invalid Successful Data

If a response cannot be converted into the expected application data, the frontend can represent this as:

```text
AppExceptionType.invalidData
```

For example, a `FormatException` encountered through Dio's unknown-error path maps to `invalidData`.

Safe message:

```text
The server returned data that SofaWatch could not understand.
```

---

## 34. Unknown Error

Unexpected client/transport errors that do not match another category map to:

```text
AppExceptionType.unknown
```

Safe message:

```text
An unexpected error occurred.
```

Unknown errors are currently considered retryable by the shared `AppException` model.

---

# Flutter Error Model

## 35. AppExceptionType

The current Flutter application defines these shared error types:

```text
connection
connectionTimeout
sendTimeout
receiveTimeout
badCertificate
cancelled
unauthorized
forbidden
notFound
conflict
validation
server
badResponse
invalidData
unknown
```

Feature code should normally work with `AppException`, not raw `DioException`.

---

## 36. AppException

`AppException` carries:

```text
type
code
message
statusCode
details
originalError
```

Conceptually:

```dart
AppException(
  type: AppExceptionType.notFound,
  code: 'show_not_found',
  message: '...',
  statusCode: 404,
  details: ...,
  originalError: ...,
)
```

---

## 37. `originalError`

`originalError` exists for technical debugging/logging.

It must not be displayed directly to users.

This is especially important because a raw `DioException` can contain:

- URLs;
- request information;
- network details;
- technical messages.

---

## 38. Network Error Classification

`AppException.isNetworkError` is true for:

```text
connection
connectionTimeout
sendTimeout
receiveTimeout
```

It is not currently true for every possible transport-adjacent condition such as `badCertificate`.

---

## 39. Timeout Classification

`AppException.isTimeout` is true for:

```text
connectionTimeout
sendTimeout
receiveTimeout
```

This allows features to present a more specific timeout state where useful.

---

## 40. Shared Retryability

The current shared exception model marks these types as retryable:

```text
connection
connectionTimeout
sendTimeout
receiveTimeout
server
unknown
```

Other error types are not globally retryable by default.

This is a baseline classification, not permission to blindly repeat every request.

---

# Dio Mapping

## 41. ApiExceptionMapper

`ApiExceptionMapper` is the transport-to-application boundary.

It maps:

```text
DioException
```

into:

```text
AppException
```

Feature repositories should use this shared behavior rather than creating inconsistent Dio mappings.

---

## 42. Bad Response Mapping

For a Dio bad response, the mapper:

1. reads the HTTP status;
2. attempts to parse `ApiErrorResponse`;
3. classifies the status;
4. preserves `error.code`;
5. preserves the safe backend `message`;
6. preserves structured `details`;
7. stores the original Dio error for debugging.

---

## 43. Status-to-Type Mapping

Current mapping:

| HTTP status | AppExceptionType |
| --- | --- |
| `401` | `unauthorized` |
| `403` | `forbidden` |
| `404` | `notFound` |
| `409` | `conflict` |
| `422` | `validation` |
| `>= 500` | `server` |
| other | `badResponse` |

This mapping is centralized and should remain centralized.

---

# Frontend Error Response DTO

## 44. ApiErrorResponse

The frontend represents the backend envelope with:

```text
ApiErrorResponse
  └── ApiErrorBody
        ├── code
        ├── message
        └── details
```

Each detail maps to:

```text
ApiErrorDetail
  ├── field
  ├── message
  └── context
```

This mirrors the normalized backend validation/application error contract.

---

## 45. Defensive Parsing

If the response does not contain a valid:

```text
error
```

object, DTO parsing fails safely and the exception mapper falls back to status-based behavior.

The frontend should not assume every reverse proxy or infrastructure failure returns SofaWatch JSON.

---

# User-Facing Messages

## 46. AppErrorMessageMapper

The shared `AppErrorMessageMapper` converts `AppException` into safe presentation text.

Resolution order:

```text
known backend code
        |
        v
code-specific message
        |
        +-- unknown code --> type-based message
```

This means semantic codes can provide more useful messages without making every widget aware of backend error codes.

---

## 47. Current Code-Specific Messages

The current shared frontend mapper explicitly recognizes:

| Error code | Meaning |
| --- | --- |
| `server_unhealthy` | Server reachable but unhealthy |
| `service_unavailable` | SofaWatch temporarily unavailable |
| `validation_error` | Submitted information is invalid |
| `show_not_found` | TV show not found |
| `season_not_found` | Season not found |
| `episode_not_found` | Episode not found |
| `movie_not_found` | Movie not found |
| `library_entry_not_found` | Library entry not found |
| `background_job_not_found` | Background job not found |

`http_error` intentionally falls through to type-based mapping.

This table documents frontend-special-cased codes, not every semantic code that may exist anywhere in the backend.

---

## 48. Type-Based Messages

When no code-specific message exists, Flutter maps by `AppExceptionType`.

Examples:

```text
connection
-> Could not connect to the server. Check the address and your network connection.

unauthorized
-> You need to sign in to continue.

forbidden
-> You do not have permission to perform this action.

server
-> The SofaWatch server encountered an error.

invalidData
-> The server returned data that SofaWatch could not understand.
```

Widgets should generally use this shared mapper instead of inventing slightly different generic messages.

---

# Feature-Specific Error Handling

## 49. Shared Mapping vs Feature Context

Shared error mapping should handle common technical semantics.

Features may add contextual UI when useful.

Example:

```text
shared:
notFound

feature context:
"The episode is no longer available."
```

Feature-specific messaging should not duplicate the entire network/error taxonomy.

---

## 50. Search Errors

Search should distinguish at least:

- initial loading failure;
- timeout;
- provider/backend failure;
- invalid response;
- pagination failure.

A pagination failure must not discard already loaded Search results.

---

## 51. Season Errors

Season/Episode lazy loading is isolated.

One failed Season should show an error/Retry for that Season rather than failing all Show Details.

---

## 52. Profile Section Errors

Profile resources should fail independently where possible.

Example:

```text
Statistics -> success
Library    -> success
History    -> failure
Server     -> success
```

Do not convert a secondary section error into a full-page failure unnecessarily.

---

## 53. Server Health Errors

Distinguish:

```text
cannot connect to SofaWatch
```

from:

```text
SofaWatch responds but reports degraded/unhealthy components
```

The second condition is health data, not necessarily a transport exception.

---

## 54. Background Job Errors

A job execution can contain failed items without necessarily meaning the HTTP request itself failed.

Keep distinct:

```text
API request failure
```

and:

```text
successful API response describing job partial failures
```

Structured job results remain domain data.

---

## 55. Import / Export Errors

Import can produce partial outcomes.

Do not reduce every partial item failure to a generic network error.

Where the backend returns structured import results, they should remain domain/application results rather than being transformed into transport exceptions.

---

# Provider Errors

## 56. Provider Boundary

TMDB failures should be normalized before reaching Flutter.

The Flutter client should not depend on raw TMDB error payloads.

Conceptually:

```text
TMDB failure
    |
    v
backend provider/client
    |
    v
SofaWatch application error
    |
    v
normalized API error
```

This becomes increasingly important with future TVDB/other providers.

---

## 57. Do Not Leak Provider Internals

Public API errors should not expose:

- provider access tokens;
- full provider request headers;
- raw authentication data;
- unnecessary upstream response dumps.

Technical provider information belongs in safe server logging.

---

## 58. Secondary Provider Failures

When multiple metadata providers exist in the future, failure of a secondary provider should not automatically become a fatal media error if SofaWatch can still satisfy the operation correctly.

Error behavior should follow explicit provider precedence/fallback rules.

---

# Retry Behavior

## 59. Retry the Failed Operation

Retry should target the operation that failed.

Examples:

```text
Search initial failure
-> repeat Search

Search pagination failure
-> repeat next-page request

Season failure
-> reload that Season

Server Health failure
-> reload Server Health
```

Avoid global page refresh as the default Retry implementation.

---

## 60. Preserve Existing Data

When refreshing/paginating data that already exists:

```text
old data
+
subtle loading state
```

is usually preferable to replacing the whole screen with a loading/error state.

If the refresh fails, preserve valid existing data where the feature design supports it.

---

## 61. Mutation Retry Safety

Network retryability does not automatically mean a mutation is safe to repeat.

Example:

```text
POST create watch event
```

If the client times out after the server commits the event, blindly retrying could create another viewing unless the endpoint provides idempotency semantics.

Feature-level retry behavior must consider mutation semantics.

---

## 62. No Infinite Automatic Retry

Do not implement uncontrolled retry loops for:

- invalid credentials;
- validation errors;
- forbidden operations;
- conflicts;
- invalid refresh credentials.

Retries should have a reason to succeed.

---

# Authentication Error Behavior

## 63. Unauthorized

An authenticated request returning `401` may mean the active authentication is no longer usable.

Native auth may attempt the defined refresh flow when appropriate.

If restoration/refresh fails, clear unusable auth state and return to the unauthenticated flow.

---

## 64. Forbidden

`403` does not mean the session is invalid.

Example:

```text
normal user calls Administrator endpoint
```

The user remains authenticated.

Do not automatically logout on `403`.

---

## 65. Invalid Bearer Precedence

If an explicit Bearer credential is invalid, the backend does not silently fall back to a valid Web cookie.

This authentication invariant must remain distinguishable from generic authorization errors.

---

# Logging

## 66. Backend Logging

Unexpected technical failures should be logged with enough context for diagnosis while keeping the API response safe.

Logs may contain technical exception information where appropriate, but must still avoid sensitive values.

---

## 67. Frontend Logging

Frontend logs may retain:

```text
AppException type
statusCode
safe code
technical original error where safely redacted
```

Do not log:

- passwords;
- access tokens;
- refresh credentials;
- Web cookies;
- recovery tokens;
- handoff tokens.

---

## 68. UI vs Logs

A useful rule:

```text
UI
-> safe and actionable

logs
-> technical and diagnostic
```

Do not make UI messages more technical just to make debugging easier.

---

# Security

## 69. Never Return Stack Traces

Production API responses must not return Python stack traces.

A stack trace can expose:

- filesystem paths;
- source structure;
- library versions;
- internal values.

---

## 70. Database Errors

Do not expose raw SQLAlchemy/SQLite exceptions directly.

Instead:

```text
database exception
    |
    v
server logging
    |
    v
safe application/server error response
```

when the failure crosses the API boundary.

---

## 71. Secrets

Error messages and details must never contain:

- TMDB tokens;
- future TVDB credentials;
- secret keys;
- passwords;
- auth session credentials;
- refresh credentials;
- recovery tokens.

---

# Compatibility and Evolution

## 72. Adding a New Error Code

A new semantic error code should:

1. use an appropriate HTTP status;
2. have a stable snake_case name;
3. have a safe fallback message;
4. be covered by backend tests;
5. only require frontend special handling if UX differs from the generic type.

Not every backend code needs an entry in `AppErrorMessageMapper`.

---

## 73. Unknown Error Codes

Frontend clients must tolerate backend codes they do not explicitly know.

Expected behavior:

```text
unknown code
    |
    v
status maps to AppExceptionType
    |
    v
type-based safe UI message
```

This supports forward-compatible server evolution.

---

## 74. Do Not Change Code Meaning

Once clients depend on an error code, do not silently reuse the same code for a different semantic condition.

Add a new code when the meaning is materially different.

---

## 75. Messages Are Not Stable Identifiers

Changing safe wording should not break client behavior.

Therefore:

```text
code = contract
message = fallback/presentation
```

---

# Testing

## 76. Backend Error Handler Tests

Global error tests should verify:

- `APIError` envelope;
- status preservation;
- optional details;
- normalized `HTTPException`;
- validation envelope;
- validation field path;
- safe validation context.

---

## 77. Route Error Tests

Routes/services should test important semantic errors.

Examples:

```text
missing Show
-> expected status + show_not_found

normal user on Admin route
-> 403 + admin_required
```

Tests should assert codes when codes are part of the public contract.

---

## 78. Frontend ApiExceptionMapper Tests

Tests should cover all Dio categories used by the mapper:

- connection timeout;
- send timeout;
- receive timeout;
- transform timeout;
- bad certificate;
- cancellation;
- connection error;
- bad response;
- unknown;
- invalid data.

---

## 79. HTTP Mapping Tests

Frontend tests should verify:

```text
401 -> unauthorized
403 -> forbidden
404 -> notFound
409 -> conflict
422 -> validation
5xx -> server
other -> badResponse
```

---

## 80. Error Envelope Parsing Tests

Test:

- valid envelope;
- details present;
- details absent;
- malformed `error`;
- non-map response;
- malformed details.

A malformed error response should degrade safely rather than causing a secondary crash.

---

## 81. Message Mapper Tests

Test both:

```text
known code -> code-specific message
```

and:

```text
unknown/no code -> type-based message
```

This protects the fallback behavior required for future backend codes.

---

## 82. Feature Error-State Tests

Features should test the states they actually expose.

Examples:

```text
Initial
-> Loading
-> Failure
-> Retry
-> Success
```

and pagination:

```text
Success(items)
-> LoadingMore(items)
-> PaginationFailure(items)
```

---

# Debugging

## 83. Inspect the First Broken Boundary

When an error appears incorrectly in Flutter, inspect:

```text
1. backend exception
2. backend HTTP response
3. HTTP status
4. error envelope
5. DioException
6. ApiExceptionMapper
7. AppException
8. AppErrorMessageMapper
9. feature state
10. widget
```

Do not patch the widget before identifying where semantics were lost.

---

## 84. Useful API Error Example

Expected:

```json
{
  "error": {
    "code": "episode_not_found",
    "message": "The requested episode could not be found."
  }
}
```

Expected Flutter representation:

```text
type       = notFound
code       = episode_not_found
statusCode = 404
```

Expected shared UI message:

```text
The requested episode could not be found.
```

---

## 85. Validation Example

Backend:

```json
{
  "error": {
    "code": "validation_error",
    "message": "The request contains invalid data.",
    "details": [
      {
        "field": "display_name",
        "message": "Invalid value."
      }
    ]
  }
}
```

Flutter:

```text
type    = validation
code    = validation_error
details = List<ApiErrorDetail>
```

A form may use the structured field detail where useful.

---

# Invariants

The following should remain true:

```text
[ ] expected API failures use a normalized error envelope
[ ] error codes are machine-readable and stable
[ ] messages are safe human-readable fallbacks
[ ] validation errors use the shared envelope
[ ] validation details are structured
[ ] framework HTTP exceptions are normalized
[ ] 401 and 403 remain semantically distinct
[ ] frontend maps Dio errors centrally
[ ] frontend features work with AppException rather than raw Dio errors
[ ] raw technical errors are not displayed directly
[ ] unknown backend codes degrade to type-based messages
[ ] malformed error bodies degrade safely
[ ] network and timeout failures are distinguishable
[ ] retryability is explicit
[ ] mutation retries consider idempotency
[ ] provider internals and secrets are not exposed
[ ] errors in one independently loaded section do not unnecessarily fail unrelated sections
```

---

## Current Implementation References

Backend:

```text
app/core/exceptions.py
app/api/error_handlers.py
app/main.py
```

Frontend:

```text
lib/core/api/api_exception_mapper.dart
lib/core/api/models/api_error_response.dart
lib/core/errors/app_exception.dart
lib/core/errors/app_error_message_mapper.dart
```

These files define the shared implementation behind this contract.

---

## Related Documentation

- [API Overview](overview.md)
- [Frontend API Contract](frontend-contract.md)
- [Authentication API](authentication.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Data Flow](../architecture/data-flow.md)
- [Debugging](../development/debugging.md)
- [Testing](../development/testing.md)
