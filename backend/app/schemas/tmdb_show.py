from datetime import date

from pydantic import BaseModel, Field


class ShowSearchResult(BaseModel):
    """TV series returned by the SofaWatch search API."""

    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    overview: str | None = None
    first_air_date: date | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None


    original_language: str
    genre_ids: list[int] = Field(default_factory=list)

    popularity: float = 0.0
    vote_average: float = 0.0
    vote_count: int = 0


class ShowSearchResponse(BaseModel):
    """Paginated TV series search response."""

    page: int = Field(ge=1)
    results: list[ShowSearchResult] = Field(default_factory=list)

    total_pages: int = Field(ge=0)
    total_results: int = Field(ge=0)


class ShowGenre(BaseModel):
    """Genre associated with a TV series."""

    tmdb_id: int = Field(gt=0)
    name: str


class ShowSeasonSummary(BaseModel):
    """Season summary included in TV series details."""

    tmdb_id: int = Field(gt=0)
    season_number: int = Field(ge=0)

    title: str
    overview: str = ""

    air_date: date | None = None
    episode_count: int = Field(ge=0)

    poster_url: str | None = None
    vote_average: float = 0.0


class ShowNetwork(BaseModel):
    """Television network associated with a TV series."""

    tmdb_id: int = Field(gt=0)
    name: str

    logo_url: str | None = None
    origin_country: str = ""


class ShowCountry(BaseModel):
    """Country associated with the production of a TV series."""

    code: str
    name: str


class ShowLanguage(BaseModel):
    """Language spoken in a TV series."""

    code: str
    name: str
    english_name: str


class ShowDetailsResponse(BaseModel):
    """Detailed TV series information returned by the SofaWatch API."""

    tmdb_id: int = Field(gt=0)

    title: str
    original_title: str

    overview: str | None = None

    tagline: str | None = None

    first_air_date: date | None = None
    last_air_date: date | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None
    poster_path: str | None = None
    backdrop_path: str | None = None

    poster_url: str | None = None
    backdrop_url: str | None = None
    homepage_url: str | None = None

    genres: list[ShowGenre] = Field(default_factory=list)
    seasons: list[ShowSeasonSummary] = Field(default_factory=list)
    networks: list[ShowNetwork] = Field(default_factory=list)

    origin_countries: list[str] = Field(default_factory=list)
    production_countries: list[ShowCountry] = Field(default_factory=list)

    languages: list[str] = Field(default_factory=list)
    spoken_languages: list[ShowLanguage] = Field(default_factory=list)
    original_language: str

    episode_run_times: list[int] = Field(default_factory=list)

    number_of_episodes: int = Field(ge=0)
    number_of_seasons: int = Field(ge=0)

    in_production: bool
    status: str
    show_type: str

    popularity: float = 0.0
    vote_average: float = 0.0
    vote_count: int = Field(default=0, ge=0)
