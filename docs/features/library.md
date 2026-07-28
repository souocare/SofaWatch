# Personal Library

The personal library stores which TV series a user is tracking.

Each library entry belongs to a user and a locally stored TV series.

## Tracking states

Library entries can represent different tracking states, such as:

- planning;
- watching;
- completed;
- paused;
- dropped.

## User isolation

Library entries are associated with a user.

Although SofaWatch currently creates a single local user, the data model is already prepared for multiple users.

This means the same TV series can appear in different users' libraries with independent state.

## Operations

The backend supports:

- adding a show to the library;
- removing a show;
- changing its tracking state;
- listing library entries;
- filtering by state.