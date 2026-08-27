# Development Setup

This guide explains how to set up SofaWatch for local development and run the backend, background worker, and Flutter client.

SofaWatch is under active development. These instructions describe the development environment, not a hardened production deployment.

For configuration details, see [Configuration](configuration.md).

---

## 1. Repository Layout

The main development layout is:

```text
SofaWatch/
├── backend/
├── frontend/
├── docs/
├── .env.example
└── README.md
```

Backend and frontend commands in this guide are normally run from their respective directories.

---

## 2. Prerequisites

You need:

- Git
- Python
- Flutter SDK
- a supported browser for Flutter Web
- Xcode for iOS development on macOS
- Android Studio / Android SDK for Android development

Useful checks:

```bash
git --version
python3 --version
flutter --version
flutter doctor
```

`flutter doctor` is particularly useful for identifying missing platform tooling.

---

## 3. Clone the Repository

```bash
git clone https://github.com/souocare/SofaWatch.git
cd SofaWatch
```

---

# Backend Setup

## 4. Create a Python Virtual Environment

From the repository root, one option is:

```bash
python3 -m venv .sofawatchvenv
```

Activate it:

```bash
source .sofawatchvenv/bin/activate
```

If you prefer to keep the environment inside `backend/`, create and activate it there instead.

When working from `backend/`, a root-level environment can be activated with:

```bash
source ../.sofawatchvenv/bin/activate
```

---

## 5. Install Backend Dependencies

Enter the backend directory:

```bash
cd backend
```

Install the project and its development dependencies using the dependency workflow defined by the backend project configuration.

If using pip with the current project metadata:

```bash
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
```

Keeping the project installed in editable mode is convenient during development because source changes are immediately reflected without reinstalling the package.

> [!NOTE]
> Dependency and lock-file strategy is still subject to a future packaging/reproducibility audit. Follow the repository's current `pyproject.toml` if this section and the package metadata ever diverge.

---

## 6. Create Local Configuration

SofaWatch reads its `.env` from the repository root.

From the repository root:

```bash
cp .env.example .env
```

If you are currently inside `backend/`:

```bash
cp ../.env.example ../.env
```

At minimum, replace the example secret key.

Generate one with:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Then set it in the root `.env`:

```dotenv
SOFAWATCH_SECRET_KEY=<generated-secret>
```

TMDB-backed features also require:

```dotenv
SOFAWATCH_TMDB_API_TOKEN=<your-tmdb-read-access-token>
```

Do not commit `.env`.

For every supported setting, see [Configuration](configuration.md).

---

## 7. Data Directory

The default backend configuration uses:

```text
./data
```

for SofaWatch data and:

```text
./data/images
```

for image storage/cache.

The default SQLite URL is:

```text
sqlite:///./data/sofawatch.db
```

Because these are relative paths, run backend development commands consistently from `backend/` unless you deliberately configure absolute paths.

If required, create the data directory:

```bash
mkdir -p data/images
```

---

## 8. Apply Database Migrations

From `backend/`, with the virtual environment active:

```bash
alembic upgrade head
```

This brings the local SQLite schema to the latest Alembic revision.

Useful checks:

```bash
alembic current
alembic heads
```

Do not manually modify the schema of an existing development database as a substitute for a migration.

See [Database Migrations](migrations.md).

---

## 9. Start the Backend API

From `backend/`:

```bash
uvicorn app.main:app \
  --reload \
  --host 0.0.0.0 \
  --port 8000
```

The API is then available locally at:

```text
http://127.0.0.1:8000
```

Interactive Swagger documentation:

```text
http://127.0.0.1:8000/docs
```

ReDoc:

```text
http://127.0.0.1:8000/redoc
```

Using:

```text
--host 0.0.0.0
```

also allows physical devices on the local network to reach the development server through the computer's LAN address.

It does not make the development server a production-ready public deployment.

---

## 10. Start the Background Worker

Background jobs run separately from the FastAPI process.

Open another terminal, activate the same virtual environment, enter `backend/`, and run:

```bash
python -m app.jobs.worker
```

During normal development, the processes are therefore:

```text
Terminal 1
└── FastAPI

Terminal 2
└── Background Worker

Terminal 3
└── Flutter
```

The application can be developed without constantly exercising scheduled jobs, but the worker should be running when testing background-job behavior or metadata synchronization.

See [Background Jobs](../architecture/background-jobs.md).

---

# Frontend Setup

## 11. Install Flutter Dependencies

Open another terminal and enter:

```bash
cd frontend
```

Install packages:

```bash
flutter pub get
```

Check the Flutter environment if necessary:

```bash
flutter doctor
```

---

## 12. Backend URL

The Flutter application receives the SofaWatch backend URL through:

```text
SOFAWATCH_SERVER_URL
```

using Dart's compile-time configuration.

Example:

```bash
--dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

This is separate from the backend setting:

```text
SOFAWATCH_API_HOST
```

The distinction is:

```text
SOFAWATCH_API_HOST
    Backend listens here

SOFAWATCH_SERVER_URL
    Flutter connects here
```

---

# Flutter Web

## 13. Run Web Locally

From `frontend/`:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

In development, the backend accepts HTTP browser origins using:

```text
localhost
127.0.0.1
```

on arbitrary ports, allowing Flutter Web's development server to use a dynamically assigned port.

---

# iOS

## 14. Check Available Devices

```bash
flutter devices
```

Start an iOS Simulator through Xcode or:

```bash
open -a Simulator
```

---

## 15. Run on iOS Simulator

The iOS Simulator can normally reach the Mac through `127.0.0.1`.

Run:

```bash
flutter run -d "<iPhone Simulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

Replace `<iPhone Simulator>` with a device identifier/name reported by:

```bash
flutter devices
```

---

## 16. Completely Remove the Simulator App

When testing installation, authentication, secure storage, or first-run behavior, a normal rebuild may preserve application state.

To completely uninstall SofaWatch from the currently booted simulator:

```bash
xcrun simctl uninstall booted com.souocare.sofawatch
```

Then run the application again.

---

# Android

## 17. Run on Android Emulator

An Android Emulator normally reaches the host computer through:

```text
10.0.2.2
```

Run:

```bash
flutter run -d "<Android Emulator>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://10.0.2.2:8000
```

Use:

```bash
flutter devices
```

to find the emulator identifier.

---

# Physical Devices

## 18. Why `127.0.0.1` Does Not Work

On a physical phone:

```text
127.0.0.1
```

means the phone itself.

It does not refer to the Mac running SofaWatch.

The mobile device must connect to the Mac through its LAN address.

---

## 19. Find the Mac LAN Address

On a typical Wi-Fi connection:

```bash
ipconfig getifaddr en0
```

For example, this may return:

```text
192.168.1.50
```

The exact address depends on the local network.

---

## 20. Backend for Physical Devices

The backend should listen on all interfaces:

```bash
uvicorn app.main:app \
  --reload \
  --host 0.0.0.0 \
  --port 8000
```

The physical device then connects to:

```text
http://<LAN-IP>:8000
```

Example:

```text
http://192.168.1.50:8000
```

---

## 21. Run Flutter on a Physical Device

From `frontend/`:

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://<LAN-IP>:8000
```

Example:

```bash
flutter run -d "<device>" \
  --dart-define=SOFAWATCH_SERVER_URL=http://192.168.1.50:8000
```

The computer and mobile device must be able to reach each other on the network.

Local firewall or network isolation settings can prevent the connection.

---

# First Run

## 22. Initial Setup

A fresh SofaWatch database contains no users.

The backend reports that setup is required, and the frontend should present the initial setup flow rather than the normal login flow.

The first account created:

- is a normal persistent SofaWatch user;
- becomes the initial Administrator;
- completes first-run setup.

After this:

```text
setup_required = false
```

and the setup flow is no longer available.

Public registration remains disabled by default.

---

## 23. Existing Development Database

If your development database already contains users, SofaWatch will not show first-run setup.

You should instead see the normal authentication flow or have an existing authenticated session restored.

Deleting frontend application state is not equivalent to deleting backend users.

Likewise, deleting the SQLite development database creates a genuinely new backend installation and should only be done deliberately.

---

# Verify the Installation

## 24. Backend

With FastAPI running, open:

```text
http://127.0.0.1:8000/docs
```

If Swagger loads, the API process is reachable.

---

## 25. Database

Check the current migration revision:

```bash
alembic current
```

The database should be at the expected head revision after:

```bash
alembic upgrade head
```

---

## 26. Backend Tests

From `backend/`:

```bash
pytest -q
```

For normal development, focused tests should be run before the full suite.

See [Testing](testing.md).

---

## 27. Backend Linting

From `backend/`:

```bash
ruff check .
```

Formatting can be checked/applied according to the repository workflow with:

```bash
ruff format .
```

---

## 28. Frontend Analysis

From `frontend/`:

```bash
flutter analyze
```

---

## 29. Frontend Tests

```bash
flutter test
```

---

# Typical Development Session

A normal local session can be started as follows.

## Terminal 1 — Backend

From `backend/`:

```bash
source ../.sofawatchvenv/bin/activate

alembic upgrade head

uvicorn app.main:app \
  --reload \
  --host 0.0.0.0 \
  --port 8000
```

If your virtual environment is stored inside `backend/`, use:

```bash
source .sofawatchvenv/bin/activate
```

instead.

---

## Terminal 2 — Worker

From `backend/`:

```bash
source ../.sofawatchvenv/bin/activate

python -m app.jobs.worker
```

---

## Terminal 3 — Flutter Web

From `frontend/`:

```bash
flutter run -d chrome \
  --dart-define=SOFAWATCH_SERVER_URL=http://127.0.0.1:8000
```

---

# Common Problems

## 30. Flutter Cannot Reach the Backend

First verify that FastAPI is running.

On the Mac:

```bash
curl http://127.0.0.1:8000/docs
```

Then confirm that the Flutter URL matches the platform:

| Client | Backend URL |
| --- | --- |
| Flutter Web on Mac | `http://127.0.0.1:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Physical device | `http://<Mac-LAN-IP>:8000` |

---

## 31. Physical Device Cannot Connect

Check:

- FastAPI is using `--host 0.0.0.0`;
- the LAN IP is current;
- phone and Mac are on compatible networks;
- the Mac firewall is not blocking the connection;
- the Wi-Fi network does not isolate clients;
- the URL uses the Mac LAN IP rather than `127.0.0.1`.

You can also test the backend URL from the device's browser where appropriate.

---

## 32. Flutter Web CORS Error

For local Web development using:

```text
localhost
127.0.0.1
```

the development CORS policy should accept arbitrary local ports.

If accessing Flutter Web through another hostname or LAN IP, that browser origin is not automatically covered by the localhost development rule.

Configure the required origin explicitly when appropriate.

See [Configuration](configuration.md#15-cors-configuration).

---

## 33. Configuration Validation Error

Check:

```text
SofaWatch/.env
```

Common causes include:

- missing `SOFAWATCH_SECRET_KEY`;
- secret key shorter than 32 characters;
- invalid numeric values;
- malformed environment configuration.

See [Configuration](configuration.md#27-configuration-validation).

---

## 34. TMDB Features Fail

Confirm:

```dotenv
SOFAWATCH_TMDB_API_TOKEN=<valid-token>
```

is present in the root `.env`.

Then restart the backend so configuration is reloaded.

A missing provider credential should not be confused with a network/provider outage.

---

## 35. Database Schema Errors

Run:

```bash
alembic current
alembic heads
```

and then:

```bash
alembic upgrade head
```

Do not fix migration problems by manually altering an existing database unless you are specifically investigating database recovery.

See [Database Migrations](migrations.md).

---

## 36. Authentication State Looks Stale

Authentication persistence differs by platform.

Web uses server-managed sessions through an HttpOnly cookie.

Native clients use access tokens plus rotating refresh credentials.

Reinstalling or clearing a frontend can remove client-side state, but it does not necessarily remove server-side sessions or users.

When testing authentication behavior, distinguish between:

```text
frontend application state
browser cookies
native secure credentials
backend AuthSession records
backend User records
```

---

## 37. Worker Is Not Running

FastAPI and the background worker are separate processes.

If normal API functionality works but scheduled background work does not execute, verify:

```bash
python -m app.jobs.worker
```

is running in another terminal.

---

# Development Workflow

SofaWatch development should remain incremental.

A typical change follows:

1. inspect the current implementation;
2. make a focused change;
3. run focused tests;
4. run static analysis/linting where relevant;
5. run the relevant full suite;
6. fix regressions;
7. commit the coherent change.

Avoid combining unrelated architectural changes into one implementation step.

---

# Production

This document intentionally does not describe a final production deployment.

Development conveniences such as:

```text
uvicorn --reload
HTTP
development CORS behavior
local LAN access
```

must not be treated as production configuration.

A future production/self-hosting guide should cover:

- reverse proxy;
- HTTPS;
- secure cookies;
- production CORS;
- persistent data paths;
- SQLite backup and restore;
- WAL-aware backup handling;
- process supervision;
- worker deployment;
- logging;
- upgrades and migrations;
- Web builds;
- mobile release builds.

---

## Related Documentation

- [Configuration](configuration.md)
- [Testing](testing.md)
- [Database Migrations](migrations.md)
- [Architecture Overview](../architecture/overview.md)
- [Backend Architecture](../architecture/backend.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Database Architecture](../architecture/database.md)
- [Authentication Architecture](../architecture/authentication.md)
- [Background Jobs](../architecture/background-jobs.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
