# Viewing Progress

SofaWatch tracks viewing progress at episode level.

Progress belongs to a user and an episode.

## Watched state

An episode can be marked as watched or unwatched.

When an episode is marked as watched, SofaWatch stores the date and time it was watched.

The viewing date can also be provided explicitly by the client.

## Progress

SofaWatch exposes two complementary progress concepts.

### Overall progress

Overall progress compares watched episodes with all known regular episodes.

Future episodes are included in the total.

For example, if a show has ten known episodes and five have been watched:

```text
5 / 10 = 50%
```
At show level, season zero (Specials) is excluded.

### Aired progress

Aired progress considers only episodes that are currently available according to their air date.

An episode is considered aired when:
```text
air_date is not null
and
air_date <= today
```

Episodes without a known air date are not considered aired.

For example, if ten episodes are known, five have aired, and all five aired episodes have been watched:

```text
overall progress = 5 / 10 = 50%
aired progress   = 5 / 5  = 100%
caught_up        = true
```

### Season progress
Season progress exposes:

- watched episode count;
- total episode count;
- overall progress percentage;
- aired episode count;
- watched aired episode count;
- aired progress percentage;
- caught-up state.

Season-level progress can also be requested for season zero.

### Show progress
Show progress is calculated across regular seasons only.

Season zero (Specials) is excluded from:

- overall show progress;
- aired show progress;
- caught-up state;
- next-to-watch calculation;
- next-upcoming calculation.

Progress is calculated dynamically rather than stored as duplicated aggregate data.

### Caught-up state

A show or season is considered caught up when at least one episode has aired and every aired episode has been watched.

```text
caught_up =
    aired_episodes > 0
    and
    watched_aired_episodes == aired_episodes
```
The caught-up state is calculated dynamically.

A show with known future episodes can therefore be caught up while its overall progress is below 100%.

### Next episode

The next episode to watch is the earliest regular episode that:

- has a known air date;
- has already aired;
- has not been watched by the current user.

Episodes are ordered by season number and episode number.

Future episodes, episodes without a known air date, and specials are not returned as the next episode to watch.

When the user has watched every currently aired regular episode, next_episode is null.


### Next upcoming episode
The next upcoming episode is the earliest known regular episode with an air date later than today.
It is independent of the user’s watched state.
This allows SofaWatch to distinguish:
```text
What can I watch now?
What airs next?
``` 
For a caught-up show:

```text
next episode     = null
next upcoming    = next future episode
``` 


## Bulk Watched Actions

SofaWatch supports bulk watched mutations at Season and Show level.

### Season

A Season can be marked as watched in a single operation.

Only Episodes that are currently watchable are affected:

- `air_date` must be known;
- `air_date` must be today or earlier.

Future Episodes and Episodes without a known air date are not marked as watched.

Episodes that are already watched remain unchanged. Bulk operations do not
create additional watch events for already-watched Episodes and therefore do
not implicitly create rewatches.

Season zero can still be handled independently where appropriate, but
Show-level bulk watched operations exclude Specials by default.

### Show

A Show can be marked as watched across all regular Seasons.

The operation:

- excludes Season zero / Specials;
- includes only aired Episodes with a known air date;
- leaves future Episodes untouched;
- leaves Episodes without a known air date untouched;
- does not create duplicate watch events for Episodes already watched.

The backend owns these eligibility rules. Flutter does not independently
reimplement them.

## Previous Unwatched Episodes

When a user marks a regular Episode as watched, SofaWatch can determine whether
earlier regular Episodes remain unwatched.

Only earlier Episodes that:

- belong to regular Seasons;
- have already aired;
- have a known air date;
- remain unwatched;

are considered.

Specials and future Episodes are excluded.

If eligible previous Episodes exist, the client offers the user two choices:

1. mark the selected Episode only; or
2. mark the eligible previous Episodes and the selected Episode as watched.

Already-watched previous Episodes are never converted into additional
rewatches.

The catch-up mutation is handled by the backend so eligibility and viewing
history semantics remain consistent across clients.

## Viewing-State Synchronization

Persisted viewing state is owned by the backend.

After a successful viewing mutation, the Flutter application announces that
server-owned viewing state has changed. Features that expose viewing-derived
collections can then refresh their own data independently.

Current consumers include:

- Home viewing sections;
- History;
- History Preview.

This keeps features decoupled: Show Details does not directly depend on Home
or History Cubits.

The notification occurs after the backend mutation succeeds and before
post-mutation local read-back. Therefore, if the mutation succeeds but a later
local refresh fails, other loaded features can still refresh from the
authoritative backend state.

A failed mutation does not emit a viewing-state change notification.