# SofaWatch Frontend Conventions

## 1. Architecture

The frontend follows:

- Feature First
- Clean Architecture Lite
- BLoC / Cubit for state management

Each feature may contain:

```text
feature/
├── presentation/
├── application/
├── domain/
└── data/
```

Only create layers and folders when they contain real code.

Presentation

Contains Flutter UI code:

* pages
* widgets
* dialogs
* modals
* visual state rendering
* BlocBuilder and BlocListener usage

Presentation must not call Dio or remote data sources directly.

Application

Contains state management and feature coordination:

* Bloc
* Cubit
* events
* states
* debounce
* pagination coordination
* asynchronous operation coordination

Use Cubit for simple state flows.

Use Bloc when the feature has multiple explicit events, debounce, pagination, retries or complex coordination.

Domain

Contains business concepts independent of Flutter and infrastructure:

* entities
* repository contracts
* value objects
* domain failures
* business rules

Domain must not depend on:

* Flutter
* Dio
* JSON
* storage implementations
* data layer classes

Data

Contains infrastructure implementations:

* remote data sources
* local data sources
* DTOs
* JSON parsing
* mappers
* repository implementations

Repository implementations must implement contracts declared in the domain layer.

---

## 2. Dependency direction

The intended dependency flow is:

```text
presentation
    ↓
application
    ↓
domain
    ↑
data
```

Typical remote data flow:

```text
Page
→ Bloc or Cubit
→ Repository contract
→ Repository implementation
→ Data source
→ API client
→ FastAPI backend
```
The UI must not call the API client directly.

---

## 3. Project folders

### lib/app

Application-wide configuration:

* root application widget
* bootstrap
* router
* theme
* dependency injection

### lib/core

Technical infrastructure shared across the application:

* API client
* configuration
* storage
* logging
* common exceptions
* technical utilities

### lib/features

Product features organized independently.

Examples:

* home
* shows
* movies
* explore
* profile
* search
* server_setup

### lib/shared

Reusable functional elements shared by multiple features:

* common widgets
* shared models
* formatters
* presentation utilities

Code must not be placed in shared merely because its final location is unclear.

---

## 4. Naming

### Files and folders

Use snake_case.
```text
show_details_page.dart
search_bloc.dart
server_setup_state.dart
```

### Classes, enums and extensions

Use PascalCase.
```text
ShowDetailsPage
SearchBloc
ServerSetupState
AppRoute
```

### Variables, methods and parameters

Use camelCase.
```text
showId
loadNextPage()
serverAddress
```


### Constants

Use camelCase, including static constants.
```dart
static const double desktopHorizontalPadding = 64;
```

Avoid uppercase underscore constant names.

### Private members

Prefix private members with _.
```dart
final ApiClient _apiClient;
```

---

## 5. BLoC conventions

### Bloc file structure

```text
search_bloc.dart
search_event.dart
search_state.dart
```

Cubit structure:
```text
server_setup_cubit.dart
server_setup_state.dart
```

### Events

Event names describe something that happened or was requested.

```text
SearchQueryChanged
SearchNextPageRequested
SearchRetryRequested
```

Avoid generic names such as:
```text
Load
Click
Update
```

### States

States describe the current condition of the feature.
```text
SearchInitial
SearchLoading
SearchSuccess
SearchEmpty
SearchFailure
```

Do not store BuildContext inside a Bloc or Cubit.

Do not perform navigation, show dialogs or display snackbars directly inside a Bloc.

Use BlocListener for presentation side effects.

Use BlocBuilder for rendering UI from state.

---

## 6. Repository conventions

Repository contracts belong in:
```text
domain/repositories/
```

Implementations belong in:
```text
data/repositories/
```

Example:
```text
domain/repositories/show_repository.dart
data/repositories/show_repository_impl.dart
```

Blocs and Cubits depend on repository contracts, not concrete implementations.

---

## 7. Models and entities

Do not create separate DTO and domain entity classes without a concrete reason.

A shared model may initially be used when:

* the API shape matches the application needs;
* there are no domain transformations;
* no infrastructure details leak into the UI.

Separate DTOs and entities when:

* API fields differ from domain concepts;
* several API responses must be combined;
* local and remote state are merged;
* JSON concerns would leak into domain code.

DTO names should use a clear suffix:
```text
ShowDto
SearchResultDto
```

---

## 8. Imports

Prefer package imports:
```dart
import 'package:sofawatch/features/shows/presentation/pages/shows_page.dart';
```

Avoid long relative imports:
```dart
import '../../../../shared/widgets/...';
``` 

Import sections should be ordered as:

1. Dart SDK
2. Flutter SDK
3. external packages
4. SofaWatch packages

Sort imports alphabetically inside each section.

Do not import private implementation details from another feature.

---

## 9. Design system

Do not hardcode design-system values inside widgets.

Prefer:
```text
AppColors.primary
AppSpacing.xxl
AppRadius.card
AppDurations.fast
AppTypography.bodyMedium
``` 

Avoid:
```dart
const Color(0xFFE24E42)
const EdgeInsets.all(24)
BorderRadius.circular(12)
const Duration(milliseconds: 150)
``` 

A literal may be used only when it is unique to that component and does not represent a reusable design token.

Use Theme.of(context) for standard Material values.

Use CupertinoTheme.of(context) for Cupertino values.

Use context.sofaWatchTheme for SofaWatch-specific semantic theme values.

---

## 10. Platform adaptation

The visual identity must remain consistent across platforms.

Platform-specific components should be used when their behaviour improves the native experience.

Current navigation rule:
```text
Web
→ top navigation

iOS and Android
→ bottom navigation
``` 

Cupertino components may be used on iOS when appropriate.

Material or custom adaptive components are used on Android and Web.

Do not create separate feature implementations per platform unless necessary.

---

## 11. Router conventions

Route names belong in:
```text
app_routes.dart
```
Route paths belong in:
```text
route_paths.dart
```
Use named routes for normal application navigation.
```text
context.pushNamed(
  AppRoute.showDetails.name,
  pathParameters: <String, String>{
    'showId': showId,
  },
);
```
Use push or pushNamed for details presented over the current context.

Use go or goNamed when replacing the active location.

Do not rely exclusively on extra for information required by deep links or browser refresh.

Routes should receive identifiers and load their required data independently.

---
## 12. Dependency injection

Application-wide repositories and infrastructure are provided above the router through AppDependencies.

Use:

* RepositoryProvider for repositories and infrastructure;
* BlocProvider for Bloc or Cubit instances.

Do not create a global service locator unless the existing provider approach becomes insufficient.

Do not add an empty MultiRepositoryProvider.

Until real dependencies exist, AppDependencies should return its child directly.

--- 

## 13. Error handling

Technical exceptions must not leak directly into presentation code.

Expected flow:
```text
DioException
→ API exception or failure
→ Bloc/Cubit failure state
→ reusable error UI
```

The frontend should use backend error codes for behaviour.

Human-readable backend messages may be shown when appropriate, but application logic must not depend on message text.

---

## 14. Widgets

Create a shared widget when:

* it is used by multiple features;
* it represents a design-system component;
* it encapsulates consistent platform behaviour.

Keep a widget inside its feature when it is feature-specific.

Prefer small widgets with clear responsibilities.

Avoid large page files containing many unrelated private widgets.

Move private widgets into separate files when:

* they become complex;
* they are independently testable;
* they are reused;
* the page becomes difficult to navigate.

---

## 15. Const usage

Use const constructors and widgets whenever possible.
```dart
const SizedBox(
  height: AppSpacing.lg,
)
``` 

Do not force const where values are calculated at runtime.

---

## 16. Logging

Use the configured logging or observer infrastructure.

Do not use print() in application code.

BLoC activity is observed by AppBlocObserver.

Logs must not expose:

* authentication tokens;
* private server addresses unnecessarily;
* passwords;
* personal data;
* complete API payloads containing sensitive information.

---

## 17. Testing

Use:

* unit tests for domain, data mapping, repositories and Blocs;
* widget tests for UI behaviour;
* router tests for navigation;
* integration tests for complete flows when needed.

Tests must describe behaviour.

Prefer:
```dart
testWidgets(
  'opens show details from a deep-link location',
  ...
);
``` 

Avoid vague descriptions:

```dart
testWidgets(
  'opens show details from a deep-link location',
  ...
);
``` 

Each test should arrange its own state and avoid depending on another test.

---

## 18. Code quality

Before committing frontend changes, run:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
``` 

For structural or release-related changes, also run:

```bash
flutter build web
flutter build ios --simulator
``` 


No analyzer warning should be ignored without a documented reason.

---

## 19. Simplicity

Do not create abstractions prematurely.

Avoid:

* empty use cases;
* unused repository interfaces;
* duplicate entities and DTOs;
* folders containing only .gitkeep;
* wrappers around Flutter widgets without real value.

Start with the simplest structure that keeps responsibilities separated.

Add abstraction when a concrete need appears.

