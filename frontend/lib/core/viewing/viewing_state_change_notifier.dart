import 'dart:async';

/// Announces that server-owned viewing state has changed.
///
/// This notifier deliberately carries no feature-specific payload.
///
/// Consumers such as Home and History remain responsible for deciding which
/// of their server-owned collections need to be refreshed. Producers only
/// announce that a successful viewing mutation occurred.
///
/// A broadcast stream allows multiple independently scoped features to listen
/// at the same time without introducing direct dependencies between them.
final class ViewingStateChangeNotifier {
  ViewingStateChangeNotifier();

  final StreamController<void> _controller = StreamController<void>.broadcast(
    sync: true,
  );

  Stream<void> get changes => _controller.stream;

  void notifyChanged() {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(null);
  }

  Future<void> dispose() {
    return _controller.close();
  }
}
