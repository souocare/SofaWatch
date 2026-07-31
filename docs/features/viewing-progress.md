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