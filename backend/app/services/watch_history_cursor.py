import base64
import binascii
import json
from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass(frozen=True, slots=True)
class WatchHistoryCursor:
    """Position within the cursor-paginated Watch History."""

    watched_at: datetime
    event_id: UUID


class WatchHistoryCursorCodec:
    """Encode and decode opaque Watch History pagination cursors."""

    @staticmethod
    def encode(
        cursor: WatchHistoryCursor,
    ) -> str:
        payload = {
            "watched_at": cursor.watched_at.isoformat(),
            "event_id": str(cursor.event_id),
        }

        raw = json.dumps(
            payload,
            separators=(",", ":"),
        ).encode("utf-8")

        return base64.urlsafe_b64encode(
            raw,
        ).decode("ascii")

    @staticmethod
    def decode(
        value: str,
    ) -> WatchHistoryCursor:
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

            event_id = UUID(
                payload["event_id"],
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
            event_id=event_id,
        )