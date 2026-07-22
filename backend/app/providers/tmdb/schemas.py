from datetime import date
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator


class TMDBTVSearchResult(BaseModel):
    id: int
    name: str
    original_name: str
    overview: str
    first_air_date: date | None = None
    poster_path: str | None = None
    backdrop_path: str | None = None
    original_language: str
    genre_ids: list[int] = Field(default_factory=list)
    popularity: float
    vote_average: float
    vote_count: int

    model_config = ConfigDict(extra="ignore")

    @field_validator("first_air_date", mode="before")
    @classmethod
    def normalize_empty_first_air_date(
        cls,
        value: Any,
    ) -> Any:
        if value == "":
            return None

        return value


class TMDBTVSearchResponse(BaseModel):
    """Paginated response returned by the TMDB TV search endpoint."""

    page: int
    results: list[TMDBTVSearchResult]
    total_pages: int
    total_results: int

    model_config = ConfigDict(extra="ignore")


class TMDBCreatedBy(BaseModel):
    """Person credited as a creator of a TV series."""

    id: int
    credit_id: str
    name: str
    original_name: str
    gender: int
    profile_path: str | None = None


class TMDBGenre(BaseModel):
    """Genre returned by a TMDB TV series details response."""

    id: int
    name: str


class TMDBNetwork(BaseModel):
    """Television network associated with a TV series."""

    id: int
    name: str
    logo_path: str | None = None
    origin_country: str


class TMDBProductionCompany(BaseModel):
    """Production company associated with a TV series."""

    id: int
    name: str
    logo_path: str | None = None
    origin_country: str


class TMDBProductionCountry(BaseModel):
    """Country where a TV series was produced."""

    iso_3166_1: str
    name: str


class TMDBSpokenLanguage(BaseModel):
    """Language spoken in a TV series."""

    english_name: str
    iso_639_1: str
    name: str


class TMDBSeasonSummary(BaseModel):
    """Season summary included in a TV series details response."""

    id: int
    air_date: date | None = None
    episode_count: int
    name: str
    overview: str
    poster_path: str | None = None
    season_number: int
    vote_average: float

    @field_validator("air_date", mode="before")
    @classmethod
    def normalize_empty_air_date(
        cls,
        value: Any,
    ) -> Any:
        """Convert TMDB empty date strings into null values."""

        return None if value == "" else value


class TMDBEpisodeSummary(BaseModel):
    """Episode summary embedded in a TV series details response."""

    id: int
    name: str
    overview: str
    vote_average: float
    vote_count: int
    air_date: date | None = None
    episode_number: int
    episode_type: str | None = None
    production_code: str
    runtime: int | None = None
    season_number: int
    show_id: int
    still_path: str | None = None

    @field_validator("air_date", mode="before")
    @classmethod
    def normalize_empty_air_date(
        cls,
        value: Any,
    ) -> Any:
        """Convert TMDB empty date strings into null values."""

        return None if value == "" else value


class TMDBTVDetails(BaseModel):
    """Detailed TV series information returned by TMDB."""

    id: int
    name: str
    original_name: str
    overview: str
    tagline: str

    adult: bool
    backdrop_path: str | None = None
    poster_path: str | None = None
    homepage: str | None = None

    first_air_date: date | None = None
    last_air_date: date | None = None

    created_by: list[TMDBCreatedBy] = Field(default_factory=list)
    episode_run_time: list[int] = Field(default_factory=list)
    genres: list[TMDBGenre] = Field(default_factory=list)
    languages: list[str] = Field(default_factory=list)
    origin_country: list[str] = Field(default_factory=list)
    spoken_languages: list[TMDBSpokenLanguage] = Field(default_factory=list)

    in_production: bool
    status: str
    type: str
    original_language: str

    number_of_episodes: int
    number_of_seasons: int

    last_episode_to_air: TMDBEpisodeSummary | None = None
    next_episode_to_air: TMDBEpisodeSummary | None = None

    networks: list[TMDBNetwork] = Field(default_factory=list)
    production_companies: list[TMDBProductionCompany] = Field(default_factory=list)
    production_countries: list[TMDBProductionCountry] = Field(default_factory=list)
    seasons: list[TMDBSeasonSummary] = Field(default_factory=list)

    popularity: float
    vote_average: float
    vote_count: int

    @field_validator(
        "first_air_date",
        "last_air_date",
        mode="before",
    )
    @classmethod
    def normalize_empty_dates(
        cls,
        value: Any,
    ) -> Any:
        """Convert TMDB empty date strings into null values."""

        return None if value == "" else value
