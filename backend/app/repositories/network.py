from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.network import Network


class NetworkRepository:
    """Persistence operations for television networks."""

    def __init__(
        self,
        session: Session,
    ) -> None:
        self._session = session

    def get_by_tmdb_id(
        self,
        tmdb_id: int,
    ) -> Network | None:
        """Return a network by its TMDB identifier."""

        return self._session.scalar(
            select(Network).where(
                Network.tmdb_id == tmdb_id,
            )
        )

    def get_or_create(
        self,
        *,
        tmdb_id: int,
        name: str,
        tmdb_logo_path: str | None,
        origin_country: str | None,
    ) -> Network:
        """Return an existing network or create it."""

        network = self.get_by_tmdb_id(
            tmdb_id,
        )

        if network is None:
            network = Network(
                tmdb_id=tmdb_id,
                name=name,
                tmdb_logo_path=tmdb_logo_path,
                origin_country=origin_country,
            )

            self._session.add(network)

            return network

        network.name = name
        network.tmdb_logo_path = tmdb_logo_path
        network.origin_country = origin_country

        return network
