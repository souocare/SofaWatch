import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/router/auth_router_refresh_notifier.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_state.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';

void main() {
  group('AuthRouterRefreshNotifier', () {
    test('notifies when authentication state changes', () async {
      final StreamController<AuthState> authStates =
          StreamController<AuthState>();

      final StreamController<AuthEntryState> authEntryStates =
          StreamController<AuthEntryState>();

      final AuthRouterRefreshNotifier notifier = AuthRouterRefreshNotifier(
        authStates: authStates.stream,
        authEntryStates: authEntryStates.stream,
      );

      var notificationCount = 0;

      notifier.addListener(() {
        notificationCount += 1;
      });

      authStates.add(const AuthUnauthenticated());

      await Future<void>.delayed(Duration.zero);

      expect(notificationCount, 1);

      notifier.dispose();

      await authStates.close();
      await authEntryStates.close();
    });

    test('notifies when authentication entry state changes', () async {
      final StreamController<AuthState> authStates =
          StreamController<AuthState>();

      final StreamController<AuthEntryState> authEntryStates =
          StreamController<AuthEntryState>();

      final AuthRouterRefreshNotifier notifier = AuthRouterRefreshNotifier(
        authStates: authStates.stream,
        authEntryStates: authEntryStates.stream,
      );

      var notificationCount = 0;

      notifier.addListener(() {
        notificationCount += 1;
      });

      authEntryStates.add(const AuthEntryLoginRequired());

      await Future<void>.delayed(Duration.zero);

      expect(notificationCount, 1);

      notifier.dispose();

      await authStates.close();
      await authEntryStates.close();
    });

    test('notifies for both authentication and entry state changes', () async {
      final StreamController<AuthState> authStates =
          StreamController<AuthState>();

      final StreamController<AuthEntryState> authEntryStates =
          StreamController<AuthEntryState>();

      final AuthRouterRefreshNotifier notifier = AuthRouterRefreshNotifier(
        authStates: authStates.stream,
        authEntryStates: authEntryStates.stream,
      );

      var notificationCount = 0;

      notifier.addListener(() {
        notificationCount += 1;
      });

      authEntryStates.add(const AuthEntryLoginRequired());
      authStates.add(const AuthUnauthenticated());

      await Future<void>.delayed(Duration.zero);

      expect(notificationCount, 2);

      notifier.dispose();

      await authStates.close();
      await authEntryStates.close();
    });
  });
}
