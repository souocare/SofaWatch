import 'package:matcher/matcher.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/state/remote_state.dart';
import 'package:sofawatch/core/state/remote_status.dart';

Matcher isRemoteInitial<T>() {
  return isA<RemoteState<T>>().having(
    (RemoteState<T> state) => state.status,
    'status',
    RemoteStatus.initial,
  );
}

Matcher isRemoteLoading<T>({bool? isRefreshing}) {
  Matcher matcher = isA<RemoteState<T>>().having(
    (RemoteState<T> state) => state.status,
    'status',
    RemoteStatus.loading,
  );

  if (isRefreshing != null) {
    matcher = allOf(
      matcher,
      isA<RemoteState<T>>().having(
        (RemoteState<T> state) => state.isRefreshing,
        'isRefreshing',
        isRefreshing,
      ),
    );
  }

  return matcher;
}

Matcher isRemoteSuccess<T>({Matcher? data}) {
  Matcher matcher = isA<RemoteState<T>>().having(
    (RemoteState<T> state) => state.status,
    'status',
    RemoteStatus.success,
  );

  if (data != null) {
    matcher = allOf(
      matcher,
      isA<RemoteState<T>>().having(
        (RemoteState<T> state) => state.data,
        'data',
        data,
      ),
    );
  }

  return matcher;
}

Matcher isRemoteFailure<T>({AppExceptionType? type, bool? hasData}) {
  Matcher matcher = isA<RemoteState<T>>().having(
    (RemoteState<T> state) => state.status,
    'status',
    RemoteStatus.failure,
  );

  if (type != null) {
    matcher = allOf(
      matcher,
      isA<RemoteState<T>>().having(
        (RemoteState<T> state) => state.error?.type,
        'error type',
        type,
      ),
    );
  }

  if (hasData != null) {
    matcher = allOf(
      matcher,
      isA<RemoteState<T>>().having(
        (RemoteState<T> state) => state.hasData,
        'hasData',
        hasData,
      ),
    );
  }

  return matcher;
}
