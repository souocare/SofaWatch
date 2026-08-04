import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';

import 'bloc_state_matchers.dart';

void main() {
  group('RemoteState matchers', () {
    test('matches an initial state', () {
      const RemoteState<String> state = RemoteState<String>.initial();

      expect(state, isRemoteInitial<String>());
    });

    test('matches an initial loading state', () {
      const RemoteState<String> state = RemoteState<String>.loading();

      expect(state, isRemoteLoading<String>(isRefreshing: false));
    });

    test('matches a refreshing state', () {
      const RemoteState<String> state = RemoteState<String>.loading(
        data: 'existing data',
      );

      expect(state, isRemoteLoading<String>(isRefreshing: true));
    });

    test('matches successful data', () {
      const RemoteState<List<String>> state = RemoteState<List<String>>.success(
        <String>['first', 'second'],
      );

      expect(state, isRemoteSuccess<List<String>>(data: hasLength(2)));
    });

    test('matches a failure by type', () {
      const RemoteState<String> state = RemoteState<String>.failure(
        AppException.connection(),
      );

      expect(
        state,
        isRemoteFailure<String>(
          type: AppExceptionType.connection,
          hasData: false,
        ),
      );
    });

    test('matches a failed refresh preserving data', () {
      const RemoteState<String> state = RemoteState<String>.failure(
        AppException.receiveTimeout(),
        data: 'cached data',
      );

      expect(
        state,
        isRemoteFailure<String>(
          type: AppExceptionType.receiveTimeout,
          hasData: true,
        ),
      );
    });
  });
}
