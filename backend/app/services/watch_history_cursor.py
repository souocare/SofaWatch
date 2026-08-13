import base64
import json
from dataclasses import dataclass
from datetime import datetime
from uuid import UUID
import binascii


@dataclass(frozen=True, slots=True)
class WatchHistoryCursor:
    watched_at: datetime
    progress_id: UUID


class WatchHistoryCursorCodec:
    """Encode and decode opaque Watch History pagination cursors."""

    @staticmethod
    def encode(cursor: WatchHistoryCursor) -> str:
        payload = {
            "watched_at": cursor.watched_at.isoformat(),
            "progress_id": str(cursor.progress_id),
        }

        raw = json.dumps(
            payload,
            separators=(",", ":"),
        ).encode("utf-8")

        return base64.urlsafe_b64encode(raw).decode("ascii")

    @staticmethod
    def decode(value: str) -> WatchHistoryCursor:
        try:
            raw = base64.urlsafe_b64decode(
                value.encode("ascii"),
            )

            payload = json.loads(
                raw.decode("utf-8"),
            )

            watched_at = datetime.fromisoformat(
                payload["watched_at"],
            )

            progress_id = UUID(
                payload["progress_id"],
            )
        except (
            ValueError,
            TypeError,
            KeyError,
            UnicodeDecodeError,
            json.JSONDecodeError,
            binascii.Error,
        ) as error:
            raise ValueError(
                "Invalid Watch History cursor."
            ) from error

        return WatchHistoryCursor(
            watched_at=watched_at,
            progress_id=progress_id,
        )