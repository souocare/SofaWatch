import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_state.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';

final class AuthRouterRefreshNotifier extends ChangeNotifier {
  AuthRouterRefreshNotifier({
    required Stream<AuthState> authStates,
    required Stream<AuthEntryState> authEntryStates,
  }) {
    _authSubscription = authStates.listen((_) => notifyListeners());

    _authEntrySubscription = authEntryStates.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<AuthEntryState> _authEntrySubscription;

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    unawaited(_authEntrySubscription.cancel());

    super.dispose();
  }
}
