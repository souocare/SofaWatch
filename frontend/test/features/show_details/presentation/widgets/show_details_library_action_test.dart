import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/show_details/presentation/widgets/show_details_library_action.dart';

void main() {
  group('ShowDetailsLibraryAction', () {
    testWidgets('shows Add to Watchlist initially', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();
      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      expect(
        find.byKey(const ValueKey<String>('show-details-library-add')),
        findsOneWidget,
      );

      expect(find.text('Add to Watchlist'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('imports and adds Show to Library', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();
      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-add')),
      );

      await tester.pumpAndSettle();

      expect(repository.importShowCalls, 1);
      expect(repository.requestedTmdbIds, <int>[95396]);

      expect(repository.addShowCalls, 1);
      expect(repository.requestedShowIds, <String>['show-local-uuid']);

      expect(
        find.byKey(const ValueKey<String>('show-details-library-added')),
        findsOneWidget,
      );

      expect(find.text('In Watchlist'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows loading state while Show is being added', (
      WidgetTester tester,
    ) async {
      final _ControlledLibraryRepository repository =
          _ControlledLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-add')),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('show-details-library-adding')),
        findsOneWidget,
      );

      expect(find.text('Adding…'), findsOneWidget);

      repository.completeImport();

      await tester.pump();

      repository.completeAdd();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-library-added')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows current Watchlist state when Show is already added', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        showEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadShowState(
        const LibraryMediaKey(mediaType: LibraryMediaType.show, tmdbId: 95396),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-library-added')),
        findsOneWidget,
      );

      expect(find.text('In Watchlist'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('removes Show from Watchlist', (WidgetTester tester) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();
      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-add')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-added')),
      );

      await tester.pumpAndSettle();

      expect(repository.removeShowCalls, 1);
      expect(repository.requestedRemovedShowIds, <String>['show-local-uuid']);

      expect(
        find.byKey(const ValueKey<String>('show-details-library-add')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows removing state while Show is being removed', (
      WidgetTester tester,
    ) async {
      final _ControlledRemoveLibraryRepository repository =
          _ControlledRemoveLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-add')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-added')),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('show-details-library-removing')),
        findsOneWidget,
      );

      expect(find.text('Removing…'), findsOneWidget);

      repository.completeRemove();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-library-add')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows failure when removing Show fails', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        removeError: const AppException.connection(),
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-add')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-added')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-library-failure')),
        findsOneWidget,
      );

      expect(find.text('Retry'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-library-added')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows updating state while changing Show status', (
      WidgetTester tester,
    ) async {
      final _ControlledStatusLibraryRepository repository =
          _ControlledStatusLibraryRepository(showEntry: _libraryEntry);

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadShowState(
        const LibraryMediaKey(mediaType: LibraryMediaType.show, tmdbId: 95396),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-status')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-library-status-paused'),
        ),
      );

      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('show-details-library-status-updating'),
        ),
        findsOneWidget,
      );

      expect(find.text('Updating to Paused…'), findsOneWidget);

      expect(repository.updateShowStatusCalls, 1);

      repository.completeStatusUpdate(status: LibraryStatus.paused);

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('show-details-library-status-updating'),
        ),
        findsNothing,
      );

      expect(find.text('Paused'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      'preserves previous Show status when update fails and Retry succeeds',
      (WidgetTester tester) async {
        final _RetryStatusLibraryRepository repository =
            _RetryStatusLibraryRepository(showEntry: _libraryEntry);

        final LibraryCubit cubit = LibraryCubit(repository);

        await tester.pumpWidget(_buildTestApp(cubit: cubit));

        await cubit.loadShowState(
          const LibraryMediaKey(
            mediaType: LibraryMediaType.show,
            tmdbId: 95396,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Watching'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('show-details-library-status')),
        );

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey<String>('show-details-library-status-paused'),
          ),
        );

        await tester.pumpAndSettle();

        expect(repository.updateShowStatusCalls, 1);

        // Failed update must preserve the old LibraryEntry/status.
        expect(find.text('Watching'), findsOneWidget);
        expect(find.text('Paused'), findsNothing);

        expect(
          find.byKey(const ValueKey<String>('show-details-library-failure')),
          findsOneWidget,
        );

        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));

        await tester.pumpAndSettle();

        expect(repository.updateShowStatusCalls, 2);

        expect(find.text('Paused'), findsOneWidget);
        expect(find.text('Watching'), findsNothing);

        await cubit.close();
      },
    );
    testWidgets('only exposes manual Show statuses as selectable actions', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        showEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadShowState(
        const LibraryMediaKey(mediaType: LibraryMediaType.show, tmdbId: 95396),
      );

      await tester.pumpAndSettle();

      expect(find.text('Watching'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-status')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('show-details-library-status-planning'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-library-status-watching'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-library-status-completed'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-library-status-paused'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-library-status-dropped'),
        ),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('allows manually changing Show status to Dropped', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        showEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadShowState(
        const LibraryMediaKey(mediaType: LibraryMediaType.show, tmdbId: 95396),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-library-status')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-library-status-dropped'),
        ),
      );

      await tester.pumpAndSettle();

      expect(repository.updateShowStatusCalls, 1);
      expect(repository.requestedStatuses, <LibraryStatus>[
        LibraryStatus.dropped,
      ]);

      expect(
        find.byKey(const ValueKey<String>('show-details-library-status-label')),
        findsOneWidget,
      );

      expect(find.text('Dropped'), findsOneWidget);

      await cubit.close();
    });
    testWidgets(
      'displays automatic Completed status without exposing it as action',
      (WidgetTester tester) async {
        final LibraryEntry completedEntry = LibraryEntry(
          id: 'library-entry-uuid',
          mediaId: 'show-local-uuid',
          mediaType: LibraryMediaType.show,
          status: LibraryStatus.completed,
          createdAt: DateTime(2026, 8, 11),
          updatedAt: DateTime(2026, 8, 15),
        );

        final _FakeLibraryRepository repository = _FakeLibraryRepository(
          showEntry: completedEntry,
        );

        final LibraryCubit cubit = LibraryCubit(repository);

        await tester.pumpWidget(_buildTestApp(cubit: cubit));

        await cubit.loadShowState(
          const LibraryMediaKey(
            mediaType: LibraryMediaType.show,
            tmdbId: 95396,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Completed'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('show-details-library-status')),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('show-details-library-status-completed'),
          ),
          findsNothing,
        );

        expect(
          find.byKey(
            const ValueKey<String>('show-details-library-status-paused'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('show-details-library-status-dropped'),
          ),
          findsOneWidget,
        );

        await cubit.close();
      },
    );
  });
}

Widget _buildTestApp({required LibraryCubit cubit}) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<LibraryCubit>.value(
        value: cubit,
        child: const ShowDetailsLibraryAction(tmdbId: 95396),
      ),
    ),
  );
}

const ImportedLibraryMedia _importedShow = ImportedLibraryMedia(
  id: 'show-local-uuid',
  tmdbId: 95396,
  mediaType: LibraryMediaType.show,
);

final LibraryEntry _libraryEntry = LibraryEntry(
  id: 'library-entry-uuid',
  mediaId: 'show-local-uuid',
  mediaType: LibraryMediaType.show,
  status: LibraryStatus.watching,
  createdAt: DateTime(2026, 8, 11),
  updatedAt: DateTime(2026, 8, 11),
);

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({this.showEntry, this.removeError});

  final LibraryEntry? showEntry;
  final AppException? removeError;

  int importShowCalls = 0;
  int addShowCalls = 0;
  int removeShowCalls = 0;
  int updateShowStatusCalls = 0;

  final List<int> requestedTmdbIds = <int>[];
  final List<String> requestedShowIds = <String>[];
  final List<String> requestedRemovedShowIds = <String>[];
  final List<LibraryStatus> requestedStatuses = <LibraryStatus>[];

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) async {
    importShowCalls++;
    requestedTmdbIds.add(tmdbId);

    return _importedShow;
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) async {
    return showEntry;
  }

  @override
  Future<LibraryEntry> addShow(String showId) async {
    addShowCalls++;
    requestedShowIds.add(showId);

    return _libraryEntry;
  }

  @override
  Future<void> removeShow(String showId) async {
    removeShowCalls++;
    requestedRemovedShowIds.add(showId);

    final AppException? error = removeError;

    if (error != null) {
      throw error;
    }
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateShowStatus(
    String showId,
    LibraryStatus status,
  ) async {
    updateShowStatusCalls++;
    requestedStatuses.add(status);

    return LibraryEntry(
      id: 'library-entry-uuid',
      mediaId: showId,
      mediaType: LibraryMediaType.show,
      status: status,
      createdAt: DateTime(2026, 8, 11),
      updatedAt: DateTime(2026, 8, 11),
    );
  }

  @override
  Future<LibraryEntry> recordMovieWatch(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> clearMovieWatchHistory(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryPreview> getPreview() {
    throw UnimplementedError();
  }
}

final class _ControlledStatusLibraryRepository extends _FakeLibraryRepository {
  _ControlledStatusLibraryRepository({required super.showEntry});

  final Completer<LibraryEntry> _statusCompleter = Completer<LibraryEntry>();

  void completeStatusUpdate({required LibraryStatus status}) {
    _statusCompleter.complete(
      LibraryEntry(
        id: 'library-entry-uuid',
        mediaId: 'show-local-uuid',
        mediaType: LibraryMediaType.show,
        status: status,
        createdAt: DateTime(2026, 8, 11),
        updatedAt: DateTime(2026, 8, 11),
      ),
    );
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    updateShowStatusCalls++;
    requestedStatuses.add(status);

    return _statusCompleter.future;
  }
}

final class _RetryStatusLibraryRepository extends _FakeLibraryRepository {
  _RetryStatusLibraryRepository({required super.showEntry});

  int _attempts = 0;

  @override
  Future<LibraryEntry> updateShowStatus(
    String showId,
    LibraryStatus status,
  ) async {
    updateShowStatusCalls++;
    requestedStatuses.add(status);

    _attempts++;

    if (_attempts == 1) {
      throw const AppException.connection();
    }

    return LibraryEntry(
      id: 'library-entry-uuid',
      mediaId: showId,
      mediaType: LibraryMediaType.show,
      status: status,
      createdAt: DateTime(2026, 8, 11),
      updatedAt: DateTime(2026, 8, 11),
    );
  }
}

final class _ControlledLibraryRepository extends _FakeLibraryRepository {
  final Completer<ImportedLibraryMedia> _importCompleter =
      Completer<ImportedLibraryMedia>();

  final Completer<LibraryEntry> _addCompleter = Completer<LibraryEntry>();

  void completeImport() {
    _importCompleter.complete(_importedShow);
  }

  void completeAdd() {
    _addCompleter.complete(_libraryEntry);
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    importShowCalls++;
    requestedTmdbIds.add(tmdbId);

    return _importCompleter.future;
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    addShowCalls++;
    requestedShowIds.add(showId);

    return _addCompleter.future;
  }
}

final class _ControlledRemoveLibraryRepository extends _FakeLibraryRepository {
  final Completer<void> _removeCompleter = Completer<void>();

  void completeRemove() {
    _removeCompleter.complete();
  }

  @override
  Future<void> removeShow(String showId) {
    removeShowCalls++;
    requestedRemovedShowIds.add(showId);

    return _removeCompleter.future;
  }
}
