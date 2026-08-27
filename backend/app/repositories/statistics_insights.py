from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True, slots=True)
class ShowViewingInsight:
    show_id: UUID
    tmdb_id: int
    title: str
    poster_url: str | None
    watch_count: int
    rewatch_count: int = 0


@dataclass(frozen=True, slots=True)
class EpisodeViewingInsight:
    episode_id: UUID
    show_tmdb_id: int
    show_title: str
    season_number: int
    episode_number: int
    episode_title: str
    still_url: str | None
    watch_count: int
    rewatch_count: int


@dataclass(frozen=True, slots=True)
class MovieViewingInsight:
    movie_id: UUID
    tmdb_id: int
    title: str
    poster_url: str | None
    watch_count: int
    rewatch_count: int


@dataclass(frozen=True, slots=True)
class GenreViewingInsight:
    genre_id: int
    name: str
    watch_count: int
