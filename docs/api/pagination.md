# Pagination API

This document describes pagination conventions used by SofaWatch APIs and the corresponding Flutter client behavior.

SofaWatch does not force every paginated resource into one universal pagination model. Different resources have different semantics, and the API preserves those differences where doing so keeps the contract clearer.

The two main pagination styles are:

```text
Page-based pagination
```

and:

```text
Offset/limit pagination
```

For exact endpoint-specific fields, use the current FastAPI OpenAPI documentation.

---

## 1. Goals

Pagination should:

- keep large result sets manageable;
- avoid loading unnecessary data;
- provide deterministic ordering;
- preserve already loaded data during subsequent loads;
- expose retryable pagination failures separately from initial failures;
- avoid duplicate items/pages;
- preserve query/filter context;
- remain understandable in both backend and Flutter code.

---

## 2. Two Pagination Families

SofaWatch currently uses two conceptual pagination families.

### Provider / Search Pagination

Page-based.

Conceptually:

```text
page
total_pages
total_results
```

Typical use:

- global Search;
- provider-backed discovery where provider semantics are page-based.

### Local Collection Pagination

Offset/limit based.

Conceptually:

```text
offset
limit
total
has_next
```

Typical use:

- large local histories;
- administrative lists;
- other locally queried collections where offset/limit is natural.

Do not merge both models into one abstraction if doing so makes semantics less clear.

---

# Page-Based Pagination

## 3. Concept

Page-based pagination asks for a logical page number.

Example:

```text
page = 1
page = 2
page = 3
```

A typical response conceptually looks like:

```json
{
  "page": 1,
  "results": [],
  "total_pages": 10,
  "total_results": 194
}
```

Exact field names depend on the endpoint/schema.

---

## 4. Search Uses Page-Based Pagination

Global Search follows provider-style page pagination.

The request context includes:

- query;
- media filter;
- language;
- page.

Conceptually:

```text
(query, filter, language, page)
```

identifies one Search request/cache entry.

---

## 5. Page Numbering

Provider APIs commonly use one-based pages.

Frontend code should not assume zero-based indexing unless the current endpoint explicitly documents it.

When mapping into Dart models, keep the API semantics explicit.

---

## 6. First Page

The first page establishes the result set for the current Search context.

Changing any of these should normally reset pagination:

```text
query
filter
language
```

and request the first page again.

Do not append page 1 from a new filter to results from the previous filter.

---

## 7. Next Page

The frontend should only request the next page when:

```text
currentPage < totalPages
```

or when the contract otherwise indicates more data exists.

Avoid speculative page requests past the known end.

---

## 8. Search Pagination State

A useful conceptual Flutter state includes:

```text
query
filter
items
currentPage
totalPages
totalResults
isLoadingMore
paginationError
```

The exact implementation may differ, but these semantics should remain visible somewhere in application state.

---

## 9. Initial Loading vs Pagination Loading

These are different states.

Initial loading:

```text
no current results
+
fetch page 1
```

Pagination loading:

```text
existing results
+
fetch next page
```

The UI should not replace existing content with a full-screen loader during pagination.

---

## 10. Pagination Failure

If the next page fails:

```text
existing items remain
+
pagination error is shown
+
retry loads the same next page
```

Do not discard already loaded results.

---

## 11. Pagination Retry

Retry should repeat the failed page request using the same:

```text
query
filter
language
next page
```

context.

If query/filter changed before retry, the previous pagination failure is stale and should not be replayed into the new Search context.

---

## 12. Duplicate Page Requests

The frontend should prevent concurrent requests for the same next page.

Example to avoid:

```text
scroll event A -> page 3
scroll event B -> page 3
```

This can create duplicate results or unnecessary provider traffic.

Use application-state guards.

---

## 13. Stale Page Responses

Search already protects against stale/out-of-order responses.

That protection also matters for pagination.

Example:

```text
query = "dark"
request page 2

user changes query = "dark matter"

old page 2 arrives late
```

The old result must not be appended to the new query.

---

## 14. Deduplication

Pagination should not normally depend on frontend deduplication to correct duplicate backend/provider pages.

Backend/provider normalization should produce coherent pages.

The frontend may still defensively guard against duplicate entity/result identity when the provider contract makes duplicates possible.

Do not hide a server pagination bug with broad title-based deduplication.

---

## 15. Search Cache and Page

Search cache keys should include page when pagination is page-based.

Conceptually:

```text
cache key =
query
+
filter
+
language
+
page
```

Without page, page 1 and page 2 could incorrectly collide.

---

# Offset / Limit Pagination

## 16. Concept

Offset/limit pagination asks for a slice of an ordered local collection.

Example:

```text
offset = 0
limit = 20

offset = 20
limit = 20

offset = 40
limit = 20
```

A conceptual response:

```json
{
  "items": [],
  "total": 72,
  "offset": 20,
  "limit": 20,
  "has_next": true
}
```

Exact fields depend on the endpoint/schema.

---

## 17. Offset

`offset` represents how many ordered items are skipped before the current page begins.

Initial request:

```text
offset = 0
```

Next request often becomes:

```text
offset = current loaded item count
```

or:

```text
offset = previous offset + previous limit
```

depending on the feature implementation.

---

## 18. Limit

`limit` is the maximum number of items requested.

The backend may impose:

- a default;
- a maximum.

Clients should not request arbitrarily large limits simply to avoid pagination.

---

## 19. Total

`total` represents the total number of items matching the current filter/context at query time.

It is useful for:

- UI counts;
- deciding whether more data exists;
- progress indicators.

Because data can mutate between requests, `total` should be treated as a snapshot rather than an immutable lifetime guarantee.

---

## 20. `has_next`

Where provided:

```text
has_next = true
```

means another request is expected to produce additional data under the current ordering/filter context.

The frontend can prefer `has_next` over recalculating:

```text
offset + items.length < total
```

when the backend contract already supplies it.

---

## 21. Local History

Full History is a natural candidate for local collection pagination.

Context may include:

```text
filter = All / Episodes / Movies
ordering = watched_at DESC
```

Pagination must preserve the selected filter.

---

## 22. History Ordering

History ordering is:

```text
watched_at DESC
```

This ordering is part of the business contract.

The backend should paginate after applying the correct ordering.

The frontend should not request unordered chunks and sort only the currently loaded items.

---

## 23. Stable Ordering

Pagination requires deterministic ordering.

If multiple items can share the same primary sort value, the backend should use a stable secondary key where necessary.

Conceptually:

```text
ORDER BY watched_at DESC, id DESC
```

if appropriate to the resource.

This prevents items from moving unpredictably between pages.

---

# Filtering and Pagination

## 24. Filter Changes Reset Pagination

Changing a filter changes the result set.

Examples:

```text
History:
All -> Movies

Search:
All -> TV Shows

Explore:
Genre A -> Genre B
```

The client should reset the pagination state rather than append data from incompatible filters.

---

## 25. Filter Is Part of Request Identity

Conceptually:

```text
pagination request identity =
resource
+
filter
+
sort/order
+
query
+
language
+
page/offset
```

Any input that changes which items belong in the collection must be treated as part of pagination context.

---

# Sorting

## 26. Backend-Owned Business Ordering

When ordering is a business rule, the backend is authoritative.

Examples:

```text
Watch History
-> watched_at DESC

Upcoming
-> chronological

Haven't Watched in a While
-> inactivity ordering
```

Do not paginate one ordering server-side and then completely reorder the loaded subset client-side.

---

## 27. Presentation Sorting

A purely presentation-oriented local rearrangement may be valid if it does not change pagination semantics.

Use caution.

If the ordering changes which items should be on page 1 vs page 2, it belongs on the backend/request contract.

---

# Mutations While Paginated

## 28. Mutation Can Change Membership

A mutation may change whether an item belongs in the current collection.

Examples:

- delete History event;
- remove Library entry;
- change status;
- mark watched;
- import/add media.

The frontend should reconcile the current page state with the authoritative result.

---

## 29. Removing an Item

For local paginated lists, after deleting one item the UI may:

- remove it locally after successful backend mutation;
- decrement known total if safe;
- optionally fetch more data to fill the visible page.

Do not invent a replacement item without querying the backend if ordering/membership may have changed.

---

## 30. Mutation Can Reorder Items

Creating a new watch event can move media/history to the top of a `watched_at DESC` list.

A paginated History view may need:

- reload first page;
- prepend the returned authoritative item;
- invalidate later page assumptions.

Choose the simplest correct behavior.

---

## 31. Offset Pagination and Concurrent Mutations

Offset pagination is sensitive to inserts/deletes between page requests.

Example:

```text
load items 0..19

new item inserted at top

request offset 20
```

An item may shift and be skipped/duplicated.

For current self-hosted usage, this may be acceptable for some lists.

If a resource becomes highly mutation-sensitive, cursor pagination may be evaluated later.

Do not introduce cursor complexity preemptively without need.

---

# Load More UX

## 32. Infinite Scroll vs Explicit Load More

Either presentation can use the same API pagination.

The frontend may trigger next page through:

```text
scroll threshold
```

or:

```text
Load More button
```

The API should not be coupled to one UI mechanism.

---

## 33. Loading Indicator

Pagination loading should normally appear near the end of the list.

Existing content remains usable.

Avoid blocking the entire page.

---

## 34. Retry Indicator

A pagination failure should ideally show Retry near the failed continuation point.

Example:

```text
[existing items]

Could not load more.
[Retry]
```

This is preferable to replacing the whole screen with a generic error.

---

# Empty Results

## 35. First Page Empty

If page 1 returns no results:

```text
empty state
```

is appropriate.

Search empty state may mention the query/filter.

History/Library empty state may explain the absence of items.

---

## 36. Later Page Empty

A later page returning no items should normally mean:

```text
no more results
```

not:

```text
whole collection is empty
```

The frontend should preserve existing loaded items.

---

# API Error Handling

## 37. Initial Request Error

If the initial page fails and no prior data exists, the feature may show a full error state with Retry.

---

## 38. Next Page Error

If a continuation request fails:

```text
retain loaded data
```

and expose a pagination-specific error.

Do not map both failure modes into the same destructive state.

---

## 39. Unauthorized During Pagination

If authentication becomes invalid during pagination, the normal authentication flow applies.

Do not simply render "could not load more" forever if the underlying session is invalid.

---

## 40. Conflict During Pagination

A `409` may indicate the current state changed.

Depending on the feature, the correct response may be:

```text
refresh the collection
```

rather than retrying the exact same offset/page blindly.

---

# Frontend Architecture

## 41. Repository Boundary

Pagination parameters belong to repository/application contracts.

Widgets should not build API query strings.

Conceptually:

```text
Widget
  |
  v
Cubit / Bloc
  |
  v
Repository
  |
  v
API request
```

---

## 42. Pagination Models

Keep pagination models meaningful to their source semantics.

Possible domain/data concepts:

```text
SearchPage<T>
OffsetPage<T>
PaginatedResult<T>
```

Use the simplest model that prevents ambiguity.

Do not create one giant pagination abstraction with dozens of nullable fields such as:

```text
page?
offset?
limit?
totalPages?
hasNext?
cursor?
```

unless a real shared abstraction emerges.

---

## 43. Data vs Application State

Backend pagination metadata belongs in data/domain result models.

Transient UI state belongs in Cubit/BLoC state.

Example:

```text
API:
current page / total pages

UI:
isLoadingMore
paginationFailure
```

Keep these responsibilities distinct.

---

# SearchBloc Behavior

## 44. SearchBloc Owns Search Pagination State

Global Search pagination is part of Search application state.

SearchBloc may coordinate:

- next-page eligibility;
- duplicate request prevention;
- stale response protection;
- append behavior;
- pagination failure;
- retry.

This is appropriate because Search already has event-driven asynchronous complexity.

---

## 45. SearchBloc Does Not Own Library Business Logic

A Search result may expose a Library action, but Search pagination state and Library mutation ownership remain distinct.

Do not put Library business rules into SearchBloc merely because a paginated Search list displays the action.

---

# History / Local Pagination

## 46. Local Cubit Pagination

A local paginated feature can often use Cubit if the workflow is direct:

```text
load initial
load more
retry load more
refresh
```

BLoC is not required solely because pagination exists.

---

## 47. Preserve Previous Items During Refresh

When refreshing a paginated local collection:

```text
current items
+
refreshing state
```

can provide better UX than clearing everything.

If refresh succeeds:

```text
replace with new authoritative first-page state
```

If it fails:

```text
preserve old usable data
+
surface refresh failure appropriately
```

---

# API Design Guidance

## 48. Choose Pagination by Resource Semantics

Use page-based pagination when:

- the upstream/provider API is naturally page-based;
- page identity is meaningful.

Use offset/limit when:

- querying ordered local database collections;
- jumping to an offset is useful;
- existing repository queries naturally use limit/offset.

Do not choose based on fashion.

---

## 49. Cursor Pagination

Cursor pagination is not currently required as the default SofaWatch strategy.

It may become useful for highly mutable, large event streams where offset pagination causes real consistency problems.

Potential future candidate:

```text
very large Watch History
```

Only introduce it when measured product behavior justifies it.

---

## 50. Maximum Limits

Local endpoints should apply reasonable maximum limits.

A client should not be able to request:

```text
limit = 1000000
```

merely to bypass pagination.

Exact maximums belong to endpoint schemas/configuration.

---

## 51. Invalid Pagination Input

Invalid values should be rejected through request validation.

Examples:

```text
page < 1
limit <= 0
offset < 0
limit above allowed maximum
```

Expected error contract:

```text
422
validation_error
```

unless a specific endpoint defines otherwise.

---

## 52. Default Values

Endpoints may define defaults such as:

```text
page = 1
offset = 0
limit = 20
```

Clients should generally send explicit values when maintaining application pagination state, rather than relying on defaults after the initial request if doing so improves clarity.

---

# Caching

## 53. Pagination and Cache Keys

Any server/client cache for paginated data must include the pagination coordinate.

For page pagination:

```text
page
```

For offset pagination:

```text
offset
limit
```

plus all query/filter/language inputs.

---

## 54. Cache Invalidation

Do not add complex cache invalidation to every paginated feature by default.

Current Search cache is small, bounded, and short-lived.

Other lists should use normal application state unless caching solves a demonstrated problem.

---

# Performance

## 55. Avoid Loading Everything

Pagination exists to avoid:

- large API responses;
- large JSON decoding;
- unnecessary DB reads;
- excessive memory use;
- slow rendering.

Do not replace pagination with "load all" because it is easier initially if the collection can grow substantially.

---

## 56. Avoid Tiny Page Sizes Without Reason

Extremely small pages increase request overhead.

Choose practical defaults based on the feature and visual density.

---

## 57. Prefetch

Automatic prefetch is not currently a general SofaWatch pagination requirement.

It may be considered for a specific feature if measurements show clear UX benefit.

Do not add prefetch globally.

---

# Testing

## 58. Backend Page-Based Tests

Test:

- default page;
- explicit page;
- invalid page;
- correct total metadata;
- final page;
- page beyond available results according to endpoint behavior;
- filters included in query identity;
- deterministic ordering.

---

## 59. Backend Offset Tests

Test:

- default offset/limit;
- explicit offset;
- explicit limit;
- invalid negative offset;
- invalid limit;
- maximum limit;
- `total`;
- `has_next`;
- deterministic ordering.

---

## 60. Frontend Initial Pagination Tests

Test:

```text
Initial
-> Loading
-> Success(first page)
```

and:

```text
Initial
-> Loading
-> Failure
```

---

## 61. Frontend Load-More Tests

Test:

```text
Success(page 1)
-> LoadingMore
-> Success(page 1 + page 2)
```

Verify page metadata advances correctly.

---

## 62. Frontend Pagination Failure Tests

Test:

```text
Success(existing)
-> LoadingMore
-> PaginationFailure(existing)
```

Existing items must remain.

---

## 63. Retry Tests

Retry should request the same failed continuation coordinate.

Example:

```text
page 3 failed
-> retry page 3
```

not:

```text
restart page 1
```

unless the feature intentionally refreshes instead.

---

## 64. Stale Response Tests

For Search, verify that a late response for an old query/filter/page cannot mutate the current results.

---

## 65. Duplicate Request Tests

Verify repeated scroll triggers while loading do not initiate duplicate next-page calls.

---

## 66. Filter Reset Tests

Changing filter should reset:

```text
items
page/offset
pagination error
has-next state
```

appropriately.

---

## 67. Mutation Reconciliation Tests

Where a paginated list supports item mutation/removal, test that:

- target item updates/removes;
- total is updated where the model guarantees it;
- other loaded items remain coherent;
- pagination state is not corrupted.

---

# Debugging

## 68. Missing Items

If items disappear between pages, inspect:

1. backend ordering;
2. offset/page calculation;
3. mutations between requests;
4. duplicate filtering;
5. stale response protection.

Do not immediately increase page size.

---

## 69. Duplicate Items

Inspect:

- duplicate page request;
- provider duplicates;
- unstable ordering;
- offset shift after mutation;
- frontend append called twice.

Identify the source before deduplicating.

---

## 70. Load More Never Triggers

Check:

- `hasNext`/`totalPages`;
- scroll threshold;
- loading guard;
- current page;
- state equality;
- whether the first page incorrectly reports no more data.

---

## 71. Endless Loading More

Check that all completion paths clear:

```text
isLoadingMore
```

including:

- success;
- failure;
- cancellation/stale response.

---

## 72. Wrong Total

For provider pagination, verify the upstream provider total is normalized correctly.

For local pagination, verify `COUNT` uses the same filters as the item query.

A classic bug is:

```text
items query filtered
total query unfiltered
```

---

## 73. Pagination After Filter Change

If old items remain after changing filter, inspect whether the application state is appending instead of replacing page 1.

---

# Invariants

The following should remain true:

```text
[ ] Search/provider pagination remains page-based where appropriate
[ ] local DB collections may use offset/limit
[ ] first-page loading and load-more loading are separate
[ ] load-more failure preserves existing results
[ ] filters/query/language are part of pagination context
[ ] stale page responses cannot mutate a new context
[ ] concurrent duplicate next-page requests are blocked
[ ] ordering is deterministic
[ ] backend-owned ordering is not redefined client-side
[ ] invalid pagination input is validated
[ ] pagination caches include page/offset coordinates
[ ] mutations reconcile paginated state deliberately
[ ] pagination abstractions remain simple and semantic
[ ] cursor pagination is deferred until a real need appears
```

---

## Related Documentation

- [API Overview](overview.md)
- [Frontend API Contract](frontend-contract.md)
- [API Errors](errors.md)
- [Architecture Data Flow](../architecture/data-flow.md)
- [Frontend Architecture](../architecture/frontend.md)
- [Backend Architecture](../architecture/backend.md)
- [Debugging](../development/debugging.md)
- [Testing](../development/testing.md)
