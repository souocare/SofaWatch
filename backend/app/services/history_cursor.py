import base64
import json
from dataclasses import dataclass
from datetime import datetime
from typing import Literal
from uuid import UUID

HistoryMediaType = Literal["episode", "movie"]


@dataclass(frozen=True, slots=True)
class HistoryCursor:
    """Decoded position inside the combined History timeline."""

    watched_at: datetime
    media_type: HistoryMediaType
    event_id: UUID


class HistoryCursorCodec:
    """Encode and decode opaque combined History cursors."""

    @staticmethod
    def encode(cursor: HistoryCursor) -> str:
        payload = {
            "watched_at": cursor.watched_at.isoformat(),
            "media_type": cursor.media_type,
            "event_id": str(cursor.event_id),
        }

        raw_value = json.dumps(
            payload,
            separators=(",", ":"),
        ).encode("utf-8")

        return base64.urlsafe_b64encode(
            raw_value,
        ).decode("ascii")

    @staticmethod
    def decode(value: str) -> HistoryCursor:
        try:
            decoded = base64.urlsafe_b64decode(
                value.encode("ascii"),
            )

            payload = json.loads(
                decoded.decode("utf-8"),
            )

            watched_at = datetime.fromisoformat(
                payload["watched_at"],
            )

            media_type = payload["media_type"]

            if media_type not in {
                "episode",
                "movie",
            }:
                raise ValueError(
                    "Invalid History media type.",
                )

            return HistoryCursor(
                watched_at=watched_at,
                media_type=media_type,
                event_id=UUID(
                    payload["event_id"],
                ),
            )
        except (
            KeyError,
            TypeError,
            ValueError,
            UnicodeDecodeError,
            json.JSONDecodeError,
        ) as error:
            raise ValueError(
                "Invalid History cursor.",
            ) from error
