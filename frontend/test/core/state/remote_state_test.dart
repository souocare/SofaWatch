import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/core/state/remote_state_extensions.dart';
import 'package:sofawatch/core/state/remote_status.dart';

void main() {
  group('RemoteState', () {
    test('starts in the initial state', () {
      const RemoteState<String> state = RemoteState<String>();

      expect(state.status, RemoteStatus.initial);

      expect(state.isInitial, isTrue);

      expect(state.hasData, isFalse);

      expect(state.hasError, isFalse);
    });

    test('represents an initial loading state', () {
      const RemoteState<String> state = RemoteState<String>.loading();

      expect(state.isLoading, isTrue);

      expect(state.isRefreshing, isFalse);

      expect(state.data, isNull);
    });

    test('represents a refresh while preserving data', () {
      const RemoteState<String> state = RemoteState<String>.loading(
        data: 'existing data',
      );

      expect(state.isLoading, isTrue);

      expect(state.isRefreshing, isTrue);

      expect(state.data, 'existing data');
    });

    test('represents a successful request', () {
      const RemoteState<String> state = RemoteState<String>.success(
        'loaded data',
      );

      expect(state.isSuccess, isTrue);

      expect(state.data, 'loaded data');

      expect(state.error, isNull);
    });

    test('represents a failed request', () {
      const AppException exception = AppException.connection();

      const RemoteState<String> state = RemoteState<String>.failure(exception);

      expect(state.isFailure, isTrue);

      expect(state.hasError, isTrue);

      expect(state.error, exception);

      expect(state.data, isNull);
    });

    test('preserves existing data after a failed refresh', () {
      const AppException exception = AppException.receiveTimeout();

      const RemoteState<String> state = RemoteState<String>.failure(
        exception,
        data: 'cached data',
      );

      expect(state.isFailure, isTrue);

      expect(state.data, 'cached data');

      expect(state.error, exception);
    });

    test('copyWith updates the status and clears the error', () {
      const RemoteState<String> failure = RemoteState<String>.failure(
        AppException.connection(),
      );

      final RemoteState<String> loading = failure.copyWith(
        status: RemoteStatus.loading,
        clearError: true,
      );

      expect(loading.isLoading, isTrue);

      expect(loading.error, isNull);
    });

    test('copyWith can clear existing data', () {
      const RemoteState<String> success = RemoteState<String>.success(
        'loaded data',
      );

      final RemoteState<String> cleared = success.copyWith(clearData: true);

      expect(cleared.data, isNull);
    });
  });

  group('RemoteCollectionStateExtension', () {
    test('identifies an empty successful collection', () {
      const RemoteState<List<String>> state = RemoteState<List<String>>.success(
        <String>[],
      );

      expect(state.isEmpty, isTrue);

      expect(state.isNotEmpty, isFalse);
    });

    test('identifies a non-empty successful collection', () {
      const RemoteState<List<String>> state = RemoteState<List<String>>.success(
        <String>['item'],
      );

      expect(state.isEmpty, isFalse);

      expect(state.isNotEmpty, isTrue);
    });

    test('does not report loading as empty', () {
      const RemoteState<List<String>> state =
          RemoteState<List<String>>.loading();

      expect(state.isEmpty, isFalse);
    });
  });
}
