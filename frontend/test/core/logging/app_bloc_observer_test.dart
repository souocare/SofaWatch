import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/logging/app_bloc_observer.dart';

class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void increment() {
    emit(state + 1);
  }
}

void main() {
  test('AppBlocObserver can observe a Cubit lifecycle', () async {
    const AppBlocObserver observer = AppBlocObserver();

    Bloc.observer = observer;

    final _TestCubit cubit = _TestCubit();

    cubit.increment();

    expect(cubit.state, 1);

    await cubit.close();
  });
}
