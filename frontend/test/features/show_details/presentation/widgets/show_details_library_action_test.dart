import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/show_details/presentation/widgets/show_details_library_action.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';

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

  final List<int> requestedTmdbIds = <int>[];
  final List<String> requestedShowIds = <String>[];
  final List<String> requestedRemovedShowIds = <String>[];

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
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    throw UnimplementedError();
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
