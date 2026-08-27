# Configuration

This document describes how SofaWatch backend configuration is loaded, which settings currently exist, and how configuration should be handled across development and future production deployments.

The canonical backend settings model lives in:

```text
app/core/config.py
```

A repository-level example environment file is available at:

```text
.env.example
```

> [!IMPORTANT]
> Never commit real secrets, provider credentials, session credentials, passwords, recovery tokens, or production `.env` files.

---

## 1. Configuration Model

SofaWatch uses `pydantic-settings`.

Configuration is loaded into the `Settings` model and exposed through the cached `get_settings()` function.

Conceptually:

```text
Environment / .env
       |
       v
Pydantic Settings
       |
       v
Validation + Defaults
       |
       v
Settings
       |
       v
Application / Services / Providers
```

This gives the backend one typed configuration boundary instead of reading environment variables throughout the codebase.

---

## 2. Environment Variable Prefix

Backend environment variables use:

```text
SOFAWATCH_
```

For example:

```text
SOFAWATCH_DATABASE_URL
SOFAWATCH_SECRET_KEY
SOFAWATCH_TMDB_API_TOKEN
```

The `Settings` field:

```text
database_url
```

maps to:

```text
SOFAWATCH_DATABASE_URL
```

Environment-variable names are case-insensitive under the current settings configuration.

---

## 3. `.env` Location

The backend configuration resolves the environment file from the project root:

```text
SofaWatch/
├── .env
├── backend/
└── frontend/
```

This is important even when the backend process is started from inside `backend/`.

The configuration code derives the project root from the backend source path and explicitly points Pydantic Settings at the root `.env`.

---

## 4. Creating Local Configuration

From the project root, copy the example file:

```bash
cp .env.example .env
```

Then edit `.env` and provide the required local values.

At minimum, a valid `SOFAWATCH_SECRET_KEY` is required by the current settings model.

TMDB functionality requires a TMDB API token.

---

## 5. Generating a Secret Key

`SOFAWATCH_SECRET_KEY` must be at least 32 characters.

For development or production, generate a random value rather than using the example placeholder.

One option:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Store the generated value only in the deployment environment or local `.env`.

Do not put the generated secret in:

- Git
- documentation examples
- screenshots
- logs
- issue reports

---

# 6. Application Settings

## `SOFAWATCH_APP_NAME`

Default:

```text
SofaWatch
```

Controls the application name exposed through backend configuration.

Example:

```dotenv
SOFAWATCH_APP_NAME=SofaWatch
```

---

## `SOFAWATCH_ENVIRONMENT`

Default:

```text
development
```

Example:

```dotenv
SOFAWATCH_ENVIRONMENT=development
```

The current settings model provides helpers for:

```text
development
production
```

Environment-specific behavior should use the centralized settings object rather than reading the environment variable directly.

---

## `SOFAWATCH_DEBUG`

Backend default:

```text
false
```

The current `.env.example` enables it for local development:

```dotenv
SOFAWATCH_DEBUG=true
```

Production deployments should not enable debug behavior without a deliberate reason.

---

# 7. API Settings

## `SOFAWATCH_API_HOST`

Default:

```text
0.0.0.0
```

Example:

```dotenv
SOFAWATCH_API_HOST=0.0.0.0
```

Listening on `0.0.0.0` allows the development server to be reached through the host's LAN address when testing physical mobile devices.

It does not itself make the service safely internet-accessible.

---

## `SOFAWATCH_API_PORT`

Default:

```text
8000
```

Example:

```dotenv
SOFAWATCH_API_PORT=8000
```

The current settings model stores this as an integer.

Further explicit port-range validation may be added during the planned configuration audit.

---

# 8. Database Settings

## `SOFAWATCH_DATABASE_URL`

Default:

```text
sqlite:///./data/sofawatch.db
```

Example:

```dotenv
SOFAWATCH_DATABASE_URL=sqlite:///./data/sofawatch.db
```

SQLite is SofaWatch's intended self-hosted database.

PostgreSQL is not part of the current roadmap.

Schema changes are managed through Alembic rather than by manually editing an existing database.

See [Database Architecture](../architecture/database.md) and [Database Migrations](migrations.md).

---

# 9. Storage Settings

## `SOFAWATCH_DATA_STORAGE_PATH`

Default:

```text
./data
```

Example:

```dotenv
SOFAWATCH_DATA_STORAGE_PATH=./data
```

This is the general SofaWatch data-storage location.

If omitted from `.env`, the backend default is used.

---

## `SOFAWATCH_IMAGE_STORAGE_PATH`

Default:

```text
./data/images
```

Example:

```dotenv
SOFAWATCH_IMAGE_STORAGE_PATH=./data/images
```

This path is used for image-related local storage/cache functionality.

Production deployments must ensure that the configured storage paths are writable by the SofaWatch process and included appropriately in operational backup planning.

---

# 10. Authentication and Security Settings

## `SOFAWATCH_SECRET_KEY`

Required.

Example placeholder:

```dotenv
SOFAWATCH_SECRET_KEY=replace-with-a-long-random-secret
```

The current settings model requires a minimum length of:

```text
32 characters
```

The example value must be replaced.

This value is security-sensitive and must remain backend-only.

---

## `SOFAWATCH_ACCESS_TOKEN_EXPIRE_MINUTES`

Default:

```text
15
```

Allowed by the current settings model:

```text
1..1440
```

Example:

```dotenv
SOFAWATCH_ACCESS_TOKEN_EXPIRE_MINUTES=15
```

Access tokens are intentionally short-lived.

They are not the persistent authentication mechanism.

---

## `SOFAWATCH_SESSION_IDLE_EXPIRE_DAYS`

Default:

```text
180
```

Allowed by the current settings model:

```text
1..3650
```

Example:

```dotenv
SOFAWATCH_SESSION_IDLE_EXPIRE_DAYS=180
```

This controls the idle lifetime policy for persistent authenticated sessions.

Web and mobile persistence is based on `AuthSession`, not long-lived access tokens.

See [Authentication Architecture](../architecture/authentication.md).

---

# 11. Localization Settings

## `SOFAWATCH_DEFAULT_LANGUAGE`

Default:

```text
en-US
```

Example:

```dotenv
SOFAWATCH_DEFAULT_LANGUAGE=en-US
```

This represents the default metadata/application language used by backend flows where applicable.

---

## `SOFAWATCH_SUPPORTED_LANGUAGES`

Default:

```text
en-US,pt-PT
```

Example:

```dotenv
SOFAWATCH_SUPPORTED_LANGUAGES=en-US,pt-PT
```

The backend currently parses this comma-separated value into a trimmed list.

Example:

```text
en-US,pt-PT
```

becomes conceptually:

```text
["en-US", "pt-PT"]
```

Full application localization remains planned work.

---

# 12. TMDB Configuration

TMDB is the current primary metadata provider.

## `SOFAWATCH_TMDB_API_TOKEN`

Default:

```text
not configured
```

Example:

```dotenv
SOFAWATCH_TMDB_API_TOKEN=
```

Set this to a valid TMDB API read-access token to use TMDB-backed functionality.

The token is represented as a secret value by backend configuration and must never be returned by diagnostics or API responses.

---

## `SOFAWATCH_TMDB_BASE_URL`

Default:

```text
https://api.themoviedb.org/3
```

Example:

```dotenv
SOFAWATCH_TMDB_BASE_URL=https://api.themoviedb.org/3
```

Normally this should not need to be changed.

Keeping it configurable helps testing and provider isolation.

---

## `SOFAWATCH_TMDB_IMAGE_BASE_URL`

Default:

```text
https://image.tmdb.org/t/p
```

Example:

```dotenv
SOFAWATCH_TMDB_IMAGE_BASE_URL=https://image.tmdb.org/t/p
```

Used when constructing/resolving TMDB image resources.

---

## `SOFAWATCH_TMDB_TIMEOUT_SECONDS`

Default:

```text
20
```

Current validation requires:

```text
> 0
```

Example:

```dotenv
SOFAWATCH_TMDB_TIMEOUT_SECONDS=20
```

Provider requests must have finite timeouts.

A provider request should never be allowed to block indefinitely.

---

# 13. TVDB Configuration

The current settings model already reserves configuration fields for future TVDB integration.

> [!NOTE]
> TVDB is not yet an active metadata provider in SofaWatch. The existence of configuration fields does not mean the provider integration or health diagnostics are implemented.

## `SOFAWATCH_TVDB_API_KEY`

Default:

```text
not configured
```

Example:

```dotenv
SOFAWATCH_TVDB_API_KEY=
```

---

## `SOFAWATCH_TVDB_PIN`

Default:

```text
not configured
```

Example:

```dotenv
SOFAWATCH_TVDB_PIN=
```

---

## `SOFAWATCH_TVDB_BASE_URL`

Default:

```text
https://api4.thetvdb.com/v4
```

Example:

```dotenv
SOFAWATCH_TVDB_BASE_URL=https://api4.thetvdb.com/v4
```

Do not expose TVDB credentials through diagnostics or Flutter configuration when the provider is implemented.

See [Provider Architecture](../architecture/provider-architecture.md).

---

# 14. Metadata Refresh Configuration

## `SOFAWATCH_METADATA_REFRESH_DAYS`

Default:

```text
7
```

Current validation requires:

```text
>= 1
```

Example:

```dotenv
SOFAWATCH_METADATA_REFRESH_DAYS=7
```

This controls the metadata freshness policy used to determine when provider-backed media is eligible for refresh.

It is distinct from the background worker's scheduling/check interval.

For example:

```text
Background job checks every 8 hours
            |
            v
Show metadata age >= refresh policy?
       /                 \
     no                   yes
     |                     |
    skip                 refresh
```

See [Background Jobs](../architecture/background-jobs.md).

---

# 15. CORS Configuration

## `SOFAWATCH_CORS_ORIGINS`

The current backend setting is a comma-separated list.

Default:

```text
http://localhost:8081,http://127.0.0.1:8081,http://localhost:19006,http://127.0.0.1:19006
```

Example:

```dotenv
SOFAWATCH_CORS_ORIGINS=http://localhost:8081,http://127.0.0.1:8081
```

The backend converts the string into a trimmed list.

CORS configuration matters particularly for Flutter Web because browser requests are subject to browser origin policy.

Native mobile applications do not use browser CORS in the same way.

---

## 15.1 Production CORS

Production should list only the origins that genuinely need browser access.

Avoid permissive production configuration such as allowing arbitrary origins, particularly when credentialed Web sessions are involved.

Web authentication uses HttpOnly cookies, so CORS and credential policy must be configured deliberately.

---

# 16. Current `.env.example`

The repository-level example currently covers:

```text
Application
API
Database
Security
Localization
TMDB
TVDB placeholders
Metadata refresh
CORS
Image storage
Access-token lifetime
Session idle lifetime
```

The example file is a starting point, not a production configuration.

It intentionally must not contain real credentials.

---

# 17. Configuration Precedence

Conceptually, Pydantic Settings combines:

```text
Model defaults
      |
      v
.env values
      |
      v
Process environment variables
```

Explicit environment values should be preferred for real deployments because they allow deployment-specific configuration without modifying repository files.

The application code should depend on the resulting `Settings` object rather than care where a value originated.

---

# 18. Cached Settings

`get_settings()` is cached.

Conceptually:

```python
@lru_cache
def get_settings() -> Settings:
    return Settings()
```

This avoids rebuilding configuration repeatedly during normal application execution.

Tests that change environment variables may need to clear the settings cache before constructing settings again.

---

# 19. Secrets

Secret configuration values are represented with Pydantic `SecretStr` where appropriate.

Current examples include:

- `secret_key`
- `tmdb_api_token`
- `tvdb_api_key`
- `tvdb_pin`

This reduces accidental plaintext representation, but it is not a substitute for correct secret handling.

Code should only unwrap a secret at the narrow boundary where the underlying library/provider actually requires the raw value.

---

# 20. Backend-Only Configuration

The following categories must remain backend-only:

```text
secret key
TMDB token
TVDB credentials
future provider credentials
database credentials/URLs if they contain secrets
authentication signing/session secrets
```

Do not pass them through Flutter `--dart-define`.

Do not expose them through Server Health.

---

# 21. Flutter Server URL

The Flutter client's backend URL is configured separately from backend environment settings.

Example for Web on the same Mac:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

This value tells Flutter where SofaWatch is reachable.

It is not the same thing as:

```text
SOFAWATCH_API_HOST
```

`SOFAWATCH_API_HOST` controls where FastAPI listens.

`SOFAWATCH_SERVER_URL` controls where the client connects.

---

# 22. iOS Simulator

For the iOS Simulator on the same Mac:

```bash
flutter run -d "<iPhone Simulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

---

# 23. Android Emulator

The Android Emulator normally reaches the host machine through:

```text
10.0.2.2
```

Example:

```bash
flutter run -d "<Android Emulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://10.0.2.2:8000
```

---

# 24. Physical Mobile Devices

A physical iPhone or Android device cannot use the Mac's:

```text
127.0.0.1
```

to reach SofaWatch.

`127.0.0.1` on the phone means the phone itself.

Find the Mac's LAN address, for example:

```bash
ipconfig getifaddr en0
```

Run the backend on:

```text
0.0.0.0
```

and configure Flutter with:

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://<LAN-IP>:8000
```

The device and development machine must be able to reach each other over the network.

---

# 25. Development Configuration Example

A typical development `.env` may look conceptually like:

```dotenv
SOFAWATCH_APP_NAME=SofaWatch
SOFAWATCH_ENVIRONMENT=development
SOFAWATCH_DEBUG=true

SOFAWATCH_API_HOST=0.0.0.0
SOFAWATCH_API_PORT=8000

SOFAWATCH_DATABASE_URL=sqlite:///./data/sofawatch.db
SOFAWATCH_DATA_STORAGE_PATH=./data
SOFAWATCH_IMAGE_STORAGE_PATH=./data/images

SOFAWATCH_SECRET_KEY=<generated-secret>

SOFAWATCH_ACCESS_TOKEN_EXPIRE_MINUTES=15
SOFAWATCH_SESSION_IDLE_EXPIRE_DAYS=180

SOFAWATCH_DEFAULT_LANGUAGE=en-US
SOFAWATCH_SUPPORTED_LANGUAGES=en-US,pt-PT

SOFAWATCH_TMDB_API_TOKEN=<tmdb-token>
SOFAWATCH_TMDB_BASE_URL=https://api.themoviedb.org/3
SOFAWATCH_TMDB_IMAGE_BASE_URL=https://image.tmdb.org/t/p
SOFAWATCH_TMDB_TIMEOUT_SECONDS=20

SOFAWATCH_METADATA_REFRESH_DAYS=7

SOFAWATCH_CORS_ORIGINS=http://localhost:8081,http://127.0.0.1:8081
```

Values shown with angle brackets are placeholders and must not be copied literally as secrets.

---

# 26. Production Configuration

A final production deployment guide is still planned.

At minimum, production configuration should eventually address:

- `SOFAWATCH_ENVIRONMENT=production`
- debug disabled
- strong unique secret key
- HTTPS
- reverse proxy
- correct Web origin
- restricted CORS
- secure Web cookies
- persistent writable data directory
- SQLite/WAL-aware backup strategy
- image/data storage permissions
- worker deployment
- provider credentials
- production logging
- upgrade/migration process

Do not treat the development `.env.example` as a production-hardening guide.

---

# 27. Configuration Validation

Pydantic validates configuration when `Settings` is created.

Current explicit validation includes:

```text
secret_key
  -> minimum length 32

access_token_expire_minutes
  -> 1..1440

session_idle_expire_days
  -> 1..3650

tmdb_timeout_seconds
  -> > 0

metadata_refresh_days
  -> >= 1
```

Other fields rely primarily on their declared type or parsing behavior.

---

# 28. Planned Configuration Audit

Before a stable release, configuration should receive a dedicated validation audit.

Known areas include:

- API port range
- environment accepted values
- secret-key production requirements
- supported-language parsing
- default-language membership
- CORS parsing/validation
- provider base URLs
- provider timeout limits
- metadata-refresh bounds
- writable storage paths
- production debug safety

Validation should be added where it prevents real configuration mistakes, not merely for theoretical completeness.

---

# 29. Configuration Tests

Configuration tests should instantiate the real `Settings` model.

Prefer testing:

```text
input environment
       |
       v
Settings validation/parsing
       |
       v
expected result/error
```

rather than duplicating validation rules manually in tests.

Useful cases include:

- required secret missing
- secret too short
- token expiration bounds
- session expiration bounds
- provider timeout
- metadata refresh interval
- language parsing
- CORS parsing

---

# 30. Testing Environment Overrides

Tests may need to override configuration.

Prefer dependency injection or controlled settings construction where available.

When directly changing process environment variables in a test, remember that `get_settings()` is cached.

A test must not leak environment changes into unrelated tests.

---

# 31. Provider Configuration Failure

A missing optional provider credential should be represented as:

```text
provider not configured
```

rather than as a fake network failure.

For example, TMDB Server Health can distinguish:

```text
configured = false
```

from:

```text
configured = true
reachable = false
```

Future TVDB health should only exist once the provider itself is implemented.

---

# 32. Configuration and Logs

Never log complete secret-bearing configuration.

Avoid patterns such as:

```python
logger.info(settings.model_dump())
```

unless secrets and sensitive values have been explicitly excluded/redacted.

Even values represented by `SecretStr` should not be assumed safe in every serialization path.

---

# 33. Configuration and Server Diagnostics

Administrator diagnostics may safely expose operational information such as:

```text
environment
storage path status
provider configured/reachable
database engine
```

only when useful and safe.

They must not expose:

```text
secret key
provider token
TVDB PIN
session credentials
password hashes
recovery credentials
```

"Configured" should be a boolean, not the credential itself.

---

# 34. Adding a New Setting

When adding a backend setting:

1. add it to `Settings`
2. choose a safe default only if one genuinely exists
3. add validation where useful
4. add it to `.env.example` when operators need to know about it
5. add focused configuration tests
6. document it here if operationally relevant
7. inject/use `Settings` through the existing configuration boundary
8. never read the environment variable independently in feature code

Secret values should use an appropriate secret type.

---

# 35. Removing a Setting

Before removing a setting:

- search for runtime usage
- search tests
- search `.env.example`
- search documentation
- consider existing self-hosted deployments
- consider whether ignoring an old variable creates confusing behavior

Configuration is part of the operational contract even when it is not part of the HTTP API.

---

# 36. Naming Rules

Backend environment variables should follow:

```text
SOFAWATCH_<SETTING_NAME>
```

Prefer names that describe the value rather than the implementation detail consuming it.

Good:

```text
SOFAWATCH_METADATA_REFRESH_DAYS
```

Avoid ambiguous names such as:

```text
SOFAWATCH_TIMEOUT
```

when several independent timeout concepts exist.

---

# 37. Anti-Patterns to Avoid

Avoid:

- committing `.env`
- real credentials in `.env.example`
- secrets in Flutter `--dart-define`
- reading `os.environ` throughout feature code
- duplicated defaults in several modules
- silently accepting dangerous production configuration
- exposing secret values in health endpoints
- assuming `0.0.0.0` is a client URL
- using `127.0.0.1` from a physical phone to reach the Mac
- adding configuration switches for behavior that should simply have one correct implementation
- adding settings before there is a real need for configurability

---

# 38. Current vs Future Configuration

Current configuration includes placeholders for TVDB even though TVDB integration is future work.

This is acceptable as reserved provider configuration, but application behavior must not imply that TVDB is active merely because these settings exist.

Potential future configuration may include:

- TVDB request timeout
- provider-specific synchronization behavior
- production cookie/security settings
- backup target and retention
- background-job stale timeout
- logging configuration

Each should be introduced only with the feature that consumes it.

---

## Related Documentation

- [Development Setup](setup.md)
- [Testing](testing.md)
- [Database Migrations](migrations.md)
- [Backend Architecture](../architecture/backend.md)
- [Authentication Architecture](../architecture/authentication.md)
- [Provider Architecture](../architecture/provider-architecture.md)
- [Database Architecture](../architecture/database.md)
- [Background Jobs](../architecture/background-jobs.md)
- [Backend README](../../backend/README.md)
