# Viewing Progress

SofaWatch tracks viewing progress at episode level.

Progress belongs to a user and an episode.

## Watched state

An episode can be marked as watched or unwatched.

When an episode is marked as watched, SofaWatch stores the date and time it was watched.

The viewing date can also be provided explicitly by the client.

## Season progress

Season progress is calculated from locally stored episodes.

The backend exposes:

- watched episode count;
- total episode count;
- progress percentage.

Progress is calculated dynamically rather than stored as duplicated aggregate data.

## Show progress

Show progress is calculated across all locally stored seasons and episodes.

## Next episode

SofaWatch determines the next unwatched regular episode using:

1. season number;
2. episode number.

Season zero (`Specials`) is excluded from the normal next-episode sequence.

When all regular episodes have been watched, the series has no next episode.