import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';

void main() {
  group('ViewingStateChangeNotifier', () {
    test('notifies every active listener when viewing state changes', () async {
      final ViewingStateChangeNotifier notifier = ViewingStateChangeNotifier();

      int firstListenerCalls = 0;
      int secondListenerCalls = 0;

      final StreamSubscription<void> firstSubscription = notifier.changes
          .listen((_) {
            firstListenerCalls++;
          });

      final StreamSubscription<void> secondSubscription = notifier.changes
          .listen((_) {
            secondListenerCalls++;
          });

      notifier.notifyChanged();

      expect(firstListenerCalls, 1);
      expect(secondListenerCalls, 1);

      await firstSubscription.cancel();
      await secondSubscription.cancel();
      await notifier.dispose();
    });

    test('stopped listeners do not receive later changes', () async {
      final ViewingStateChangeNotifier notifier = ViewingStateChangeNotifier();

      int listenerCalls = 0;

      final StreamSubscription<void> subscription = notifier.changes.listen((
        _,
      ) {
        listenerCalls++;
      });

      notifier.notifyChanged();

      await subscription.cancel();

      notifier.notifyChanged();

      expect(listenerCalls, 1);

      await notifier.dispose();
    });
  });
}
