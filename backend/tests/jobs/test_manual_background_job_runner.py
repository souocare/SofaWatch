from unittest.mock import MagicMock, Mock, patch

from app.jobs.manual_runner import run_background_job_manually


def test_manual_runner_executes_registered_job() -> None:
    """Execute a registered job using the normal handler mode."""

    definition = Mock()

    session = MagicMock()
    session_context = MagicMock()
    session_context.__enter__.return_value = session
    session_context.__exit__.return_value = False

    executor = Mock()

    with (
        patch(
            "app.jobs.manual_runner.get_background_job",
            return_value=definition,
        ),
        patch(
            "app.jobs.manual_runner.SessionLocal",
            return_value=session_context,
        ),
        patch(
            "app.jobs.manual_runner.BackgroundJobRepository",
        ),
        patch(
            "app.jobs.manual_runner.BackgroundJobExecutor",
            return_value=executor,
        ),
    ):
        run_background_job_manually(
            "metadata_sync",
        )

    executor.execute.assert_called_once_with(
        definition,
        force=False,
    )


def test_manual_runner_forwards_force_mode() -> None:
    """Forward forced execution mode to the background job executor."""

    definition = Mock()

    session = MagicMock()
    session_context = MagicMock()
    session_context.__enter__.return_value = session
    session_context.__exit__.return_value = False

    executor = Mock()

    with (
        patch(
            "app.jobs.manual_runner.get_background_job",
            return_value=definition,
        ),
        patch(
            "app.jobs.manual_runner.SessionLocal",
            return_value=session_context,
        ),
        patch(
            "app.jobs.manual_runner.BackgroundJobRepository",
        ),
        patch(
            "app.jobs.manual_runner.BackgroundJobExecutor",
            return_value=executor,
        ),
    ):
        run_background_job_manually(
            "metadata_sync",
            force=True,
        )

    executor.execute.assert_called_once_with(
        definition,
        force=True,
    )


def test_manual_runner_returns_when_job_is_not_registered() -> None:
    """Do not create execution infrastructure for an unknown job."""

    with (
        patch(
            "app.jobs.manual_runner.get_background_job",
            return_value=None,
        ),
        patch(
            "app.jobs.manual_runner.SessionLocal",
        ) as session_local,
        patch(
            "app.jobs.manual_runner.BackgroundJobExecutor",
        ) as executor,
    ):
        run_background_job_manually(
            "missing-job",
            force=True,
        )

    session_local.assert_not_called()
    executor.assert_not_called()