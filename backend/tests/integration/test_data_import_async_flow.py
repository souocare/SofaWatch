from unittest.mock import Mock
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import Settings
from app.jobs.data_import_processor import DataImportProcessor
from app.models.data_import_run import DataImportRun
from app.models.user import User
from app.providers.tmdb import TMDBClient
from app.services.data_import_builder import build_data_import_service


def _empty_export_payload(
    *,
    display_name: str,
) -> dict[str, object]:
    """Build the smallest valid portable SofaWatch export."""

    return {
        "format": "sofawatch-export",
        "version": 1,
        "exported_at": "2026-09-08T05:00:00Z",
        "user": {
            "display_name": display_name,
        },
        "library": {
            "shows": [],
            "movies": [],
        },
        "history": {
            "episodes": [],
            "movies": [],
        },
    }


def test_accepted_import_remains_queued_until_worker_processes_it(
    client: TestClient,
    db_session: Session,
) -> None:
    """Submitting an import must return before any import work is executed."""

    user = User(
        display_name="Async Queue User",
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.post(
        "/api/v1/users/me/import",
        json=_empty_export_payload(
            display_name=user.display_name,
        ),
    )

    assert response.status_code == 202

    submitted = response.json()

    assert submitted["status"] == "queued"
    assert submitted["phase"] == "queued"
    assert submitted["progress_current"] == 0
    assert submitted["progress_total"] == 0
    assert submitted["result"] is None
    assert submitted["started_at"] is None
    assert submitted["finished_at"] is None

    run_id = submitted["id"]

    active_response = client.get(
        "/api/v1/users/me/imports/active",
    )

    assert active_response.status_code == 200

    active = active_response.json()

    assert active is not None
    assert active["id"] == run_id
    assert active["status"] == "queued"
    assert active["phase"] == "queued"

    status_response = client.get(
        f"/api/v1/users/me/imports/{run_id}",
    )

    assert status_response.status_code == 200
    assert status_response.json()["status"] == "queued"


def test_worker_completes_persisted_import_after_http_request_returns(
    client: TestClient,
    db_session: Session,
    db_session_factory: sessionmaker[Session],
    settings: Settings,
) -> None:
    """Process a persisted HTTP import independently from the request."""

    user = User(
        display_name="Async Worker User",
    )

    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    submit_response = client.post(
        "/api/v1/users/me/import",
        json=_empty_export_payload(
            display_name=user.display_name,
        ),
    )

    assert submit_response.status_code == 202

    submitted = submit_response.json()

    assert submitted["status"] == "queued"

    run_id = submitted["id"]

    tmdb_client = Mock(
        spec=TMDBClient,
    )

    def service_factory(
        session: Session,
    ):
        return build_data_import_service(
            session=session,
            settings=settings,
            tmdb_client=tmdb_client,
        )

    processor = DataImportProcessor(
        service_factory=service_factory,
        session_factory=db_session_factory,
    )

    processed = processor.run_once()

    assert processed is True

    # The HTTP client fixture keeps its original SQLAlchemy Session.
    # Expire its identity map so subsequent requests observe changes
    # committed independently by the worker Session.
    db_session.expire_all()

    status_response = client.get(
        f"/api/v1/users/me/imports/{run_id}",
    )

    assert status_response.status_code == 200

    completed = status_response.json()

    assert completed["id"] == run_id
    assert completed["status"] == "completed"
    assert completed["phase"] == "finalizing"
    assert completed["result"] is not None
    assert completed["error_code"] is None
    assert completed["error_message"] is None
    assert completed["started_at"] is not None
    assert completed["finished_at"] is not None

    active_response = client.get(
        "/api/v1/users/me/imports/active",
    )

    assert active_response.status_code == 200
    assert active_response.json() is None

    db_session.expire_all()

    stored = db_session.get(
        DataImportRun,
        UUID(run_id),
    )

    assert stored is not None
    assert stored.payload is None
    assert stored.result is not None

    assert tmdb_client.method_calls == []
