import 'package:sofawatch/core/state/remote_state.dart';

extension RemoteCollectionStateExtension<T extends Iterable<Object?>>
    on RemoteState<T> {
  bool get isEmpty {
    return isSuccess && data?.isEmpty == true;
  }

  bool get isNotEmpty {
    return isSuccess && data?.isNotEmpty == true;
  }
}
