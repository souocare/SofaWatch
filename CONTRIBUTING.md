# Contributing to SofaWatch

Thank you for your interest in contributing to SofaWatch.

SofaWatch is currently under active development. Contributions, bug reports,
ideas, and suggestions are welcome.

Because the project is still evolving, architecture and APIs may change as
development continues.

## Getting Started

Fork the repository and clone your fork:

```bash
git clone https://github.com/<your-username>/SofaWatch.git
cd SofaWatch
```

Create a branch for your changes:

```bash
git checkout -b feature/your-feature
```

For backend development, move into the backend directory:

```bash
cd backend
```

Create and activate a Python virtual environment:

```bash
python -m venv .sofawatchvenv
source .sofawatchvenv/bin/activate
```

Install the project dependencies:

```bash
pip install -e .
```

Apply database migrations:

```bash
alembic upgrade head
```

For more information, see the
[Development Setup](docs/development/setup.md).

## Development Guidelines

Keep changes focused and consistent with the existing project architecture.

The backend generally follows:

```text
API Routes
    ↓
Services
    ↓
Repositories
    ↓
SQLAlchemy Models
    ↓
Database
```

External integrations should be implemented through provider components
rather than directly inside API routes or repositories.

When adding or changing functionality:

- Keep API routes focused on HTTP concerns.
- Keep business logic inside services.
- Keep database queries inside repositories.
- Use Pydantic schemas for API data.
- Add or update tests for changed behaviour.
- Add Alembic migrations when the database schema changes.
- Update documentation when behaviour or architecture changes.

See the [Backend Architecture](docs/architecture/backend.md) for more details.

## Testing

Run the complete backend test suite before submitting a pull request:

```bash
cd backend
python -m pytest
```

Tests should not depend on live external services.

TMDB and other external integrations should be mocked where appropriate.

See [Testing](docs/development/testing.md) for more information.

## Code Quality

Ruff is used for linting and formatting.

Before submitting changes, run:

```bash
ruff check .
ruff format --check .
```

Code should follow the existing structure and naming conventions of the
project.

## Database Changes

Database schema changes must include an Alembic migration.

After changing SQLAlchemy models:

```bash
alembic revision --autogenerate -m "describe change"
```

Review the generated migration before applying it:

```bash
alembic upgrade head
```

See [Database Migrations](docs/development/migrations.md).

## Commits

Use clear and focused commit messages.

SofaWatch generally follows Conventional Commit-style messages:

```text
feat: add viewing progress tracking
fix: prevent duplicate network associations
test: add metadata synchronization tests
docs: document background job architecture
refactor: simplify show import service
```

Keep unrelated changes in separate commits where practical.

## Pull Requests

Before opening a pull request:

- Make sure the application runs correctly.
- Run the complete relevant test suite.
- Run the code quality checks.
- Include migrations for database schema changes.
- Update documentation where necessary.
- Keep the pull request focused on one feature, fix, or related set of changes.

The pull request description should explain what changed and why.

## Reporting Bugs

When reporting a bug, include enough information to reproduce the problem,
where possible:

- What happened
- What you expected to happen
- Steps to reproduce it
- Relevant logs or error messages
- Environment information when relevant

Do not include API keys, tokens, passwords, or other sensitive information.

## Feature Requests

Feature suggestions are welcome.

When proposing a significant feature, describe the problem it solves and the
expected behaviour rather than only the implementation you would prefer.

Large architectural changes should ideally be discussed before substantial
implementation work begins.

## Documentation

Technical documentation is available under [`docs/`](docs/).

Changes that introduce significant new behaviour or architectural decisions
should update the relevant documentation.

Important architectural decisions may also be documented as an
[Architecture Decision Record](docs/decisions/README.md).

## License

By contributing to SofaWatch, you agree that your contributions will be
licensed under the project's [MIT License](LICENSE).