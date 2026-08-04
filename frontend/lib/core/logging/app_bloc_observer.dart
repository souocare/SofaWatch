import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);

    _log('Created ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);

    _log('${bloc.runtimeType} received ${event.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    _log(
      '${bloc.runtimeType} changed: '
      '${change.currentState.runtimeType} → '
      '${change.nextState.runtimeType}',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);

    _log(
      '${bloc.runtimeType} transitioned after '
      '${transition.event.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      'Unhandled error in ${bloc.runtimeType}',
      name: 'SofaWatch.BLoC',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );

    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    _log('Closed ${bloc.runtimeType}');

    super.onClose(bloc);
  }

  void _log(String message) {
    if (!kDebugMode) {
      return;
    }

    developer.log(message, name: 'SofaWatch.BLoC');
  }
}
