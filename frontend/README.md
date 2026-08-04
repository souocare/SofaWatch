# SofaWatch Frontend

Flutter client for **SofaWatch**, a self-hosted application for tracking
TV shows, movies, episodes, progress, upcoming releases, and personal
watch activity.

## Platforms

-   iOS
-   Android
-   Web

## Current status

Implemented foundation:

-   Adaptive navigation
-   Persistent navigation
-   Deep links
-   Server setup flow
-   API client
-   Error handling
-   Design system
-   Remote state
-   Automated tests

Next milestone: **Search**.

## Architecture

``` text
lib/
├── app/
├── core/
└── features/
```

Feature structure:

``` text
feature/
├── application/
├── data/
├── domain/
└── presentation/
```

## Technologies

-   Flutter
-   Dart
-   Cubit / BLoC
-   go_router
-   Dio
-   Equatable

## Routes

``` text
/home
/shows
/movies
/explore
/profile
/server-setup
```

## Server Setup

1.  Validate URL
2.  Call `/api/v1/health`
3.  Save configuration
4.  Configure API client
5.  Open application

## API

-   Automatic `/api/v1`
-   Timeouts
-   JSON headers
-   GET / POST / PUT / PATCH / DELETE
-   Centralized exception mapping

## Remote State

Uses `RemoteStatus` and `RemoteState<T>`.

## Development

``` bash
flutter pub get
flutter run -d chrome
```

Validation:

``` bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test --test-randomize-ordering-seed=random
flutter build web
flutter build ios --simulator
```

## Backend

Located in:

``` text
backend/
```
