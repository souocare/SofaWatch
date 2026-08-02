# Frontend API Contract

This document defines the API contract used by SofaWatch frontend clients.

It complements the generated OpenAPI documentation by describing:

- shared response conventions;
- endpoints required by each frontend flow;
- expected error codes;
- pagination behavior;
- dates and timestamps;
- image delivery;
- backend features that are still missing for planned screens.

The API is versioned under:

```text
/api/v1
```

---

## 1. General conventions

### 1.1 Internal identifiers

Local SofaWatch resources use UUID identifiers represented as strings.

Example:

```json
{
  "id": "8bdc4777-e2f8-4272-8a27-79677f76986e"
}
```

Provider identifiers remain separate:

```json
{
  "tmdb_id": 95396,
  "tvdb_id": null,
  "imdb_id": null
}
```

Frontend clients must use the internal SofaWatch UUID after a resource has been
imported.

### 1.2 Optional values

Missing optional values are returned as `null`.

```json
{
  "overview": null,
  "air_date": null,
  "poster_url": null
}
```

Empty collections are returned as empty arrays.

```json
[]
```

### 1.3 Dates

Calendar-only values use the ISO date format:

```text
YYYY-MM-DD
```

Example:

```json
{
  "air_date": "2026-08-02"
}
```

### 1.4 Timestamps

Timestamps use ISO 8601 and represent UTC instants.

Example:

```json
{
  "created_at": "2026-08-02T11:30:00+00:00"
}
```

The frontend is responsible for converting timestamps to the user's locale and
timezone.

The backend must not return display-formatted values such as:

```text
02/08/2026 12:30
```

### 1.5 Standard error response

Expected API errors use this envelope:

```json
{
  "error": {
    "code": "show_not_found",
    "message": "TV series not found."
  }
}
```

Errors may include additional details:

```json
{
  "error": {
    "code": "validation_error",
    "message": "The request contains invalid data.",
    "details": [
      {
        "field": "show_id",
        "message": "Input should be a valid UUID."
      }
    ]
  }
}
```

Frontend behavior must depend on `error.code`, not on the human-readable
message.

The message may be used as a fallback display value.

### 1.6 Common error codes

| Code | Meaning |
| --- | --- |
| `validation_error` | Invalid path, query or body data |
| `http_error` | Generic HTTP error without a more specific API code |
| `show_not_found` | Local TV series does not exist |
| `season_not_found` | Local season does not exist |
| `episode_not_found` | Local episode does not exist |
| `library_entry_not_found` | Show is not in the current user's library |
| `library_entry_already_exists` | Show is already in the library |
| `genre_already_exists` | Genre name or slug already exists |
| `local_user_not_configured` | Server local user is missing |
| `tmdb_not_found` | Resource was not found in TMDB |
| `tmdb_not_configured` | TMDB integration is not configured |
| `tmdb_unavailable` | TMDB could not be reached |
| `tmdb_invalid_response` | TMDB returned an invalid response |
| `image_not_found` | Resource has no available image |
| `image_download_failed` | Provider image could not be downloaded or cached |
| `background_job_not_found` | Background job is not registered |
| `background_job_already_running` | Background job is already running |

---

## 2. Pagination

### 2.1 SofaWatch pagination

Potentially large local collections use the following response:

```json
{
  "items": [],
  "total": 0,
  "offset": 0,
  "limit": 20,
  "has_next": false
}
```

Generic frontend type:

```ts
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  offset: number;
  limit: number;
  has_next: boolean;
}
```

The next offset can be calculated as:

```ts
const nextOffset = response.offset + response.items.length;
```

A next page must only be requested when:

```ts
response.has_next === true
```

### 2.2 Provider search pagination

TMDB search uses page-based pagination:

```json
{
  "page": 1,
  "results": [],
  "total_pages": 1,
  "total_results": 0
}
```

This is intentionally different from local SofaWatch pagination.

Frontend clients should use a separate type for provider search results.

---

## 3. Images

The frontend must never construct TMDB image URLs directly.

Local resources expose resolved SofaWatch image paths:

```json
{
  "poster_url": "/api/v1/images/shows/<show_id>/poster",
  "backdrop_url": "/api/v1/images/shows/<show_id>/backdrop"
}
```

Season responses may expose:

```json
{
  "poster_url": "/api/v1/images/seasons/<season_id>/poster"
}
```

Episode responses may expose:

```json
{
  "still_url": "/api/v1/images/episodes/<episode_id>/still"
}
```

These fields are `null` when no local or provider image is known.

The frontend combines the API server origin with the relative path:

```ts
export function resolveApiUrl(
  apiBaseUrl: string,
  relativeUrl: string | null,
): string | null {
  if (!relativeUrl) {
    return null;
  }

  return new URL(relativeUrl, apiBaseUrl).toString();
}
```

The backend image flow is:

1. return an existing cached file;
2. otherwise download it from the provider;
3. store it in the local image cache;
4. persist its relative storage path;
5. return the cached file.

The frontend does not need to know whether an image came from local storage or
TMDB.

### Image endpoints

```http
GET /api/v1/images/shows/{show_id}/poster
GET /api/v1/images/shows/{show_id}/backdrop
GET /api/v1/images/seasons/{season_id}/poster
GET /api/v1/images/episodes/{episode_id}/still
```

Expected errors:

- `show_not_found`
- `season_not_found`
- `episode_not_found`
- `image_not_found`
- `image_download_failed`
- `validation_error`

When an image URL is `null`, the frontend should show its own placeholder and
must not issue an image request.

---

## 4. Search and import flow

### 4.1 Search TV series

```http
GET /api/v1/search/shows
```

Query parameters:

| Parameter | Required | Description |
| --- | --- | --- |
| `query` | yes | Search text, between 1 and 200 characters |
| `page` | no | Page number, starting at `1` |
| `language` | no | Metadata language such as `en-US` or `pt-PT` |

Example:

```http
GET /api/v1/search/shows?query=Severance&page=1&language=en-US
```

Used by:

- global search;
- Explore search;
- add-to-library flow.

Expected errors:

- `validation_error`
- `tmdb_not_configured`
- `tmdb_unavailable`
- `tmdb_invalid_response`

### 4.2 Get provider show details

```http
GET /api/v1/shows/tmdb/{tmdb_id}
```

Optional query parameter:

```text
language
```

Used by:

- provider search result details;
- preview before import.

Expected errors:

- `validation_error`
- `tmdb_not_found`
- `tmdb_not_configured`
- `tmdb_unavailable`
- `tmdb_invalid_response`

### 4.3 Import TV series

```http
POST /api/v1/shows/import/tmdb/{tmdb_id}
```

Optional query parameters:

| Parameter | Description |
| --- | --- |
| `language` | Metadata language |
| `force_refresh` | Refresh even if local metadata is recent |

The endpoint returns the locally stored `ShowResponse`.

Used by:

- add-to-library flow;
- importing a search result;
- creating a local resource before tracking it.

Expected errors:

- `validation_error`
- `tmdb_not_found`
- `tmdb_not_configured`
- `tmdb_unavailable`
- `tmdb_invalid_response`

Importing a show does not automatically mean that the show is in the user's
library unless the frontend subsequently calls the library endpoint.

---

## 5. Shows

### 5.1 List local shows

```http
GET /api/v1/shows
```

Supported parameters include:

| Parameter | Description |
| --- | --- |
| `offset` | Pagination offset |
| `limit` | Maximum number of results |
| `sort_by` | Sort field |
| `sort_direction` | Ascending or descending order |
| `query` | Local title search |
| `genre` | Genre filter |
| `status` | Show status filter |

Response:

```ts
PaginatedResponse<ShowSummaryResponse>
```

Used by:

- Shows tab;
- local catalogue;
- local search;
- administration and debugging.

### 5.2 Get show details

```http
GET /api/v1/shows/{show_id}
```

Used by:

- show details screen;
- shared show header;
- library details flow.

Expected errors:

- `show_not_found`
- `validation_error`

### 5.3 List show seasons

```http
GET /api/v1/shows/{show_id}/seasons
```

Response:

```ts
SeasonResponse[]
```

Used by:

- show details screen;
- season selector.

Expected errors:

- `show_not_found`
- `validation_error`

### 5.4 Get show progress

```http
GET /api/v1/shows/{show_id}/progress
```

Used by:

- show details progress indicator;
- Home statistics;
- library progress display.

The response distinguishes:

- total regular episodes;
- watched regular episodes;
- aired regular episodes;
- watched aired episodes;
- overall progress percentage;
- aired progress percentage;
- whether the user is caught up.

Expected errors:

- `show_not_found`
- `validation_error`

### 5.5 Get next episode

```http
GET /api/v1/shows/{show_id}/next-episode
```

Returns the next aired, regular and unwatched episode for the current user.

A successful response may contain:

```json
{
  "show_id": "...",
  "next_episode": null
}
```

A `null` episode means the show exists but no matching episode is available.

Used by:

- Watch Next;
- Continue Watching;
- show details primary action.

Expected errors:

- `show_not_found`
- `validation_error`

### 5.6 Get next upcoming episode

```http
GET /api/v1/shows/{show_id}/next-upcoming
```

Returns the next known future regular episode.

A `null` episode means the show exists but no future episode is known.

Used by:

- Upcoming section;
- show details upcoming information.

Expected errors:

- `show_not_found`
- `validation_error`

### 5.7 Refresh show metadata

```http
POST /api/v1/shows/{show_id}/refresh
```

Optional query parameter:

```text
language
```

Used by:

- administrative refresh action;
- profile/server management;
- troubleshooting stale metadata.

Expected errors:

- `show_not_found`
- `tmdb_not_found`
- `tmdb_not_configured`
- `tmdb_unavailable`
- `tmdb_invalid_response`
- `validation_error`

This endpoint should not normally be called automatically by regular screens.

---

## 6. Seasons and episodes

### 6.1 List season episodes

```http
GET /api/v1/seasons/{season_id}/episodes
```

Response:

```ts
EpisodeResponse[]
```

Used by:

- season details;
- episode list;
- bulk progress interactions in a future version.

Expected errors:

- `season_not_found`
- `validation_error`

### 6.2 Get episode details

```http
GET /api/v1/episodes/{episode_id}
```

Used by:

- episode details screen;
- episode modal or sheet;
- next-episode navigation.

Expected errors:

- `episode_not_found`
- `validation_error`

### 6.3 Mark episode as watched

```http
POST /api/v1/episodes/{episode_id}/watched
```

Request body:

```json
{
  "watched_at": "2026-08-02T11:30:00+00:00"
}
```

`watched_at` may be optional according to the request schema. When omitted, the
backend records the current UTC time.

Used by:

- episode check action;
- Watch Next completion;
- episode details.

Expected errors:

- `episode_not_found`
- `validation_error`

### 6.4 Mark episode as unwatched

```http
DELETE /api/v1/episodes/{episode_id}/watched
```

Used by:

- undo watched action;
- episode details;
- correction of viewing history.

Expected errors:

- `episode_not_found`
- `validation_error`

---

## 7. Library

### 7.1 List library

```http
GET /api/v1/library
```

Optional query parameter:

```text
status
```

Possible statuses must be taken from the backend `LibraryStatus` enum.

Response:

```ts
LibraryEntryResponse[]
```

Used by:

- Shows tab;
- planning list;
- watching list;
- completed list;
- dropped list.

The current endpoint returns a simple array and is not paginated.

### 7.2 Add show to library

```http
POST /api/v1/library/shows/{show_id}
```

The initial status is currently:

```text
planning
```

Used by:

- provider import flow;
- local show details;
- search result actions.

Expected errors:

- `show_not_found`
- `library_entry_already_exists`
- `validation_error`

### 7.3 Remove show from library

```http
DELETE /api/v1/library/shows/{show_id}
```

Successful status:

```text
204 No Content
```

Expected errors:

- `library_entry_not_found`
- `validation_error`

### 7.4 Update library status

```http
PATCH /api/v1/library/shows/{show_id}/status
```

Request body:

```json
{
  "status": "watching"
}
```

Expected errors:

- `library_entry_not_found`
- `validation_error`

---

## 8. Genres

### 8.1 List genres

```http
GET /api/v1/genres
```

Used by:

- show filters;
- Explore genre selection.

### 8.2 Create genre

```http
POST /api/v1/genres
```

This endpoint is primarily administrative. Normal frontend flows should obtain
genres from imported provider metadata.

Expected errors:

- `genre_already_exists`
- `validation_error`

---

## 9. Background jobs

Background job endpoints are intended for server management and the Profile /
Server area, not for regular navigation.

The frontend may use them to:

- display registered jobs;
- show last execution status;
- show duration and errors;
- manually run a job;
- inspect structured job results.

The metadata synchronization result may include:

```json
{
  "checked": 10,
  "refreshed": 4,
  "skipped": 5,
  "failed": 1
}
```

Expected errors may include:

- `background_job_not_found`
- `background_job_already_running`
- `validation_error`

The exact list and detail endpoints should follow the registered background-jobs
router and OpenAPI documentation.

---

## 10. Frontend screen mapping

### Home

Currently available building blocks:

```http
GET /api/v1/library
GET /api/v1/shows/{show_id}/progress
GET /api/v1/shows/{show_id}/next-episode
GET /api/v1/shows/{show_id}/next-upcoming
```

The current backend does not yet provide one aggregated Home endpoint.

An initial frontend may compose Home from these endpoints, but an aggregated
endpoint may be preferable before optimizing production performance.

Potential future endpoint:

```http
GET /api/v1/home
```

Potential sections:

- user greeting and date;
- weekly statistics;
- continue watching;
- watch next;
- upcoming episodes;
- recommendations.

### Shows

Available:

```http
GET /api/v1/library
GET /api/v1/shows
GET /api/v1/shows/{show_id}
GET /api/v1/shows/{show_id}/progress
GET /api/v1/shows/{show_id}/next-episode
```

### Movies

Movie resources and endpoints are not implemented yet.

The frontend should not build production movie flows until the corresponding
backend models, services, schemas and routes exist.

### Explore

Available:

```http
GET /api/v1/search/shows
GET /api/v1/shows/tmdb/{tmdb_id}
POST /api/v1/shows/import/tmdb/{tmdb_id}
GET /api/v1/genres
```

Trending, personalized recommendations and discovery filters are not yet
represented by dedicated endpoints.

### Profile

Currently available backend concepts:

- local user;
- background jobs;
- application configuration;
- metadata refresh operations.

Dedicated profile, statistics, history, import/export and server health
contracts still need to be defined.

---

## 11. Loading, error and empty states

Every frontend query must distinguish these states.

### Loading

The request has not completed and no usable cached data exists.

### Refreshing

Existing data is visible while a background refresh is running.

### Error

The request failed and the error envelope is available.

Frontend error handling should first inspect:

```ts
error.error.code
```

### Empty

The request succeeded but contains no items or no relevant resource.

Examples:

- `items: []`;
- library array is empty;
- `next_episode: null`;
- `next_upcoming: null`;
- `poster_url: null`.

Empty is not an error.

### Not found

A `*_not_found` error means the requested owner resource does not exist.

This differs from:

```text
image_not_found
```

which means that the owner exists but has no image.

---

## 12. Known backend gaps before complete frontend coverage

The following planned frontend areas do not yet have complete backend contracts:

- aggregated Home response;
- Continue Watching collection;
- Watch Next collection across all shows;
- Upcoming collection across all shows;
- weekly user statistics;
- movies;
- recommendations;
- trending and discovery;
- ratings;
- viewing history;
- profile preferences;
- server health summary;
- import/export;
- notification settings.

These gaps do not prevent starting the frontend foundation and the currently
supported Shows, Search, Library, Progress and Image flows.