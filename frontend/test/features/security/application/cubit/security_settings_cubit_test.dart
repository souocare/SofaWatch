import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/security/application/cubit/security_settings_cubit.dart';
import 'package:sofawatch/features/security/application/cubit/security_settings_state.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';
import 'package:sofawatch/features/security/domain/repositories/security_settings_repository.dart';

void main() {
  group('SecuritySettingsCubit', () {
    test('starts in initial state', () async {
      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: _FakeSecuritySettingsRepository(),
      );

      expect(cubit.state, const SecuritySettingsInitial());

      await cubit.close();
    });

    test('loads Security settings successfully', () async {
      final _FakeSecuritySettingsRepository repository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: false),
          );

      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: repository,
      );

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<SecuritySettingsState>[
          const SecuritySettingsLoading(),
          const SecuritySettingsSuccess(
            settings: SecuritySettings(openRegistration: false),
          ),
        ]),
      );

      await cubit.load();

      await expectation;

      expect(repository.getSettingsCalls, 1);

      await cubit.close();
    });

    test('emits failure when loading throws AppException', () async {
      const AppException error = AppException.connection();

      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: _FakeSecuritySettingsRepository(getSettingsError: error),
      );

      await cubit.load();

      expect(cubit.state, const SecuritySettingsFailure(error));

      await cubit.close();
    });

    test('maps unexpected loading error to unknown failure', () async {
      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: _FakeSecuritySettingsRepository(
          getSettingsError: StateError('Unexpected failure.'),
        ),
      );

      await cubit.load();

      expect(cubit.state, isA<SecuritySettingsFailure>());

      final SecuritySettingsFailure state =
          cubit.state as SecuritySettingsFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('retries loading Security settings', () async {
      final _FakeSecuritySettingsRepository repository =
          _FakeSecuritySettingsRepository(
            getSettingsErrors: <Object>[const AppException.connection()],
            settings: const SecuritySettings(openRegistration: false),
          );

      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: repository,
      );

      await cubit.load();

      expect(cubit.state, isA<SecuritySettingsFailure>());

      await cubit.retry();

      expect(
        cubit.state,
        const SecuritySettingsSuccess(
          settings: SecuritySettings(openRegistration: false),
        ),
      );

      expect(repository.getSettingsCalls, 2);

      await cubit.close();
    });

    test('updates Open registration successfully', () async {
      final _FakeSecuritySettingsRepository repository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: false),
            updatedSettings: const SecuritySettings(openRegistration: true),
          );

      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: repository,
      );

      await cubit.load();

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<SecuritySettingsState>[
          const SecuritySettingsSuccess(
            settings: SecuritySettings(openRegistration: false),
            isUpdating: true,
          ),
          const SecuritySettingsSuccess(
            settings: SecuritySettings(openRegistration: true),
          ),
        ]),
      );

      await cubit.setOpenRegistration(true);

      await expectation;

      expect(repository.updateOpenRegistrationCalls, 1);
      expect(repository.lastOpenRegistrationValue, isTrue);

      await cubit.close();
    });

    test(
      'does not update when requested value already matches settings',
      () async {
        final _FakeSecuritySettingsRepository repository =
            _FakeSecuritySettingsRepository(
              settings: const SecuritySettings(openRegistration: false),
            );

        final SecuritySettingsCubit cubit = SecuritySettingsCubit(
          repository: repository,
        );

        await cubit.load();

        await cubit.setOpenRegistration(false);

        expect(repository.updateOpenRegistrationCalls, 0);

        expect(
          cubit.state,
          const SecuritySettingsSuccess(
            settings: SecuritySettings(openRegistration: false),
          ),
        );

        await cubit.close();
      },
    );

    test('does not update before settings have loaded', () async {
      final _FakeSecuritySettingsRepository repository =
          _FakeSecuritySettingsRepository();

      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: repository,
      );

      await cubit.setOpenRegistration(true);

      expect(repository.updateOpenRegistrationCalls, 0);

      expect(cubit.state, const SecuritySettingsInitial());

      await cubit.close();
    });

    test('blocks another update while an update is already running', () async {
      final Completer<SecuritySettings> updateCompleter =
          Completer<SecuritySettings>();

      final _FakeSecuritySettingsRepository repository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: false),
            updateCompleter: updateCompleter,
          );

      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: repository,
      );

      await cubit.load();

      final Future<void> firstUpdate = cubit.setOpenRegistration(true);

      await Future<void>.delayed(Duration.zero);

      expect(repository.updateOpenRegistrationCalls, 1);

      expect(
        cubit.state,
        const SecuritySettingsSuccess(
          settings: SecuritySettings(openRegistration: false),
          isUpdating: true,
        ),
      );

      await cubit.setOpenRegistration(true);

      expect(repository.updateOpenRegistrationCalls, 1);

      updateCompleter.complete(const SecuritySettings(openRegistration: true));

      await firstUpdate;

      expect(
        cubit.state,
        const SecuritySettingsSuccess(
          settings: SecuritySettings(openRegistration: true),
        ),
      );

      await cubit.close();
    });

    test(
      'keeps current settings and exposes update error when update fails',
      () async {
        const AppException error = AppException.connection();

        final _FakeSecuritySettingsRepository repository =
            _FakeSecuritySettingsRepository(
              settings: const SecuritySettings(openRegistration: false),
              updateError: error,
            );

        final SecuritySettingsCubit cubit = SecuritySettingsCubit(
          repository: repository,
        );

        await cubit.load();

        await cubit.setOpenRegistration(true);

        expect(
          cubit.state,
          const SecuritySettingsSuccess(
            settings: SecuritySettings(openRegistration: false),
            updateError: error,
          ),
        );

        expect(repository.updateOpenRegistrationCalls, 1);

        await cubit.close();
      },
    );

    test(
      'maps unexpected update error to unknown and preserves current settings',
      () async {
        final _FakeSecuritySettingsRepository repository =
            _FakeSecuritySettingsRepository(
              settings: const SecuritySettings(openRegistration: false),
              updateError: StateError('Unexpected failure.'),
            );

        final SecuritySettingsCubit cubit = SecuritySettingsCubit(
          repository: repository,
        );

        await cubit.load();

        await cubit.setOpenRegistration(true);

        expect(cubit.state, isA<SecuritySettingsSuccess>());

        final SecuritySettingsSuccess state =
            cubit.state as SecuritySettingsSuccess;

        expect(state.settings, const SecuritySettings(openRegistration: false));

        expect(state.isUpdating, isFalse);

        expect(state.updateError, isNotNull);

        expect(state.updateError!.type, AppExceptionType.unknown);

        await cubit.close();
      },
    );

    test('clears update error', () async {
      const AppException error = AppException.connection();

      final _FakeSecuritySettingsRepository repository =
          _FakeSecuritySettingsRepository(
            settings: const SecuritySettings(openRegistration: false),
            updateError: error,
          );

      final SecuritySettingsCubit cubit = SecuritySettingsCubit(
        repository: repository,
      );

      await cubit.load();

      await cubit.setOpenRegistration(true);

      expect((cubit.state as SecuritySettingsSuccess).updateError, error);

      cubit.clearUpdateError();

      expect(
        cubit.state,
        const SecuritySettingsSuccess(
          settings: SecuritySettings(openRegistration: false),
        ),
      );

      await cubit.close();
    });
  });
}

final class _FakeSecuritySettingsRepository
    implements SecuritySettingsRepository {
  _FakeSecuritySettingsRepository({
    this.settings = const SecuritySettings(openRegistration: false),
    this.updatedSettings,
    this.getSettingsError,
    this.updateError,
    List<Object>? getSettingsErrors,
    this.updateCompleter,
  }) : _getSettingsErrors = getSettingsErrors ?? <Object>[];

  final SecuritySettings settings;
  final SecuritySettings? updatedSettings;

  final Object? getSettingsError;
  final Object? updateError;

  final Completer<SecuritySettings>? updateCompleter;

  final List<Object> _getSettingsErrors;

  int getSettingsCalls = 0;
  int updateOpenRegistrationCalls = 0;

  bool? lastOpenRegistrationValue;

  @override
  Future<SecuritySettings> getSettings() async {
    getSettingsCalls += 1;

    if (_getSettingsErrors.isNotEmpty) {
      throw _getSettingsErrors.removeAt(0);
    }

    final Object? error = getSettingsError;

    if (error != null) {
      throw error;
    }

    return settings;
  }

  @override
  Future<SecuritySettings> updateOpenRegistration({
    required bool enabled,
  }) async {
    updateOpenRegistrationCalls += 1;
    lastOpenRegistrationValue = enabled;

    final Completer<SecuritySettings>? completer = updateCompleter;

    if (completer != null) {
      return completer.future;
    }

    final Object? error = updateError;

    if (error != null) {
      throw error;
    }

    return updatedSettings ?? SecuritySettings(openRegistration: enabled);
  }
}
