import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/theme/app_theme.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/password_recovery_cubit.dart';
import 'package:sofawatch/features/auth/domain/repositories/password_recovery_repository.dart';
import 'package:sofawatch/features/auth/presentation/pages/password_recovery_page.dart';

void main() {
  group('PasswordRecoveryPage', () {
    testWidgets('shows reset password form for valid token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          repository: _FakePasswordRecoveryRepository(),
          token: 'reset-token',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('password-recovery-page')),
        findsOneWidget,
      );

      expect(find.text('Reset your password'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('password-recovery-new-password-field'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('password-recovery-confirm-password-field'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows unavailable state when token is missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(repository: _FakePasswordRecoveryRepository(), token: null),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('password-recovery-invalid')),
        findsOneWidget,
      );

      expect(find.text('Recovery link unavailable'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('password-recovery-submit-button')),
        findsNothing,
      );
    });

    testWidgets('validates empty password fields', (WidgetTester tester) async {
      final _FakePasswordRecoveryRepository repository =
          _FakePasswordRecoveryRepository();

      await tester.pumpWidget(
        _buildApp(repository: repository, token: 'reset-token'),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('password-recovery-submit-button')),
      );

      await tester.pump();

      expect(find.text('Enter a new password.'), findsOneWidget);

      expect(find.text('Confirm your new password.'), findsOneWidget);

      expect(repository.completeCalls, 0);
    });

    testWidgets('validates mismatched passwords', (WidgetTester tester) async {
      final _FakePasswordRecoveryRepository repository =
          _FakePasswordRecoveryRepository();

      await tester.pumpWidget(
        _buildApp(repository: repository, token: 'reset-token'),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-new-password-field'),
        ),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-confirm-password-field'),
        ),
        'different-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('password-recovery-submit-button')),
      );

      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);

      expect(repository.completeCalls, 0);
    });

    testWidgets('completes password recovery successfully', (
      WidgetTester tester,
    ) async {
      final _FakePasswordRecoveryRepository repository =
          _FakePasswordRecoveryRepository();

      await tester.pumpWidget(
        _buildApp(repository: repository, token: 'reset-token'),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-new-password-field'),
        ),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-confirm-password-field'),
        ),
        'new-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('password-recovery-submit-button')),
      );

      await tester.pumpAndSettle();

      expect(repository.completeCalls, 1);
      expect(repository.lastToken, 'reset-token');
      expect(repository.lastNewPassword, 'new-password');

      expect(
        find.byKey(const ValueKey<String>('password-recovery-success')),
        findsOneWidget,
      );

      expect(find.text('Password changed'), findsOneWidget);
    });

    testWidgets('shows invalid state for invalid recovery token', (
      WidgetTester tester,
    ) async {
      final _FakePasswordRecoveryRepository repository =
          _FakePasswordRecoveryRepository(
            error: const AppException(
              type: AppExceptionType.badResponse,
              message: 'Invalid password recovery token.',
              code: 'password_recovery_invalid',
              statusCode: 400,
            ),
          );

      await tester.pumpWidget(
        _buildApp(repository: repository, token: 'invalid-token'),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-new-password-field'),
        ),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-confirm-password-field'),
        ),
        'new-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('password-recovery-submit-button')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('password-recovery-invalid')),
        findsOneWidget,
      );

      expect(
        find.text(
          'This password recovery link is invalid, expired, or has already been used.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows safe failure while preserving the form', (
      WidgetTester tester,
    ) async {
      final _FakePasswordRecoveryRepository repository =
          _FakePasswordRecoveryRepository(
            error: const AppException.connection(),
          );

      await tester.pumpWidget(
        _buildApp(repository: repository, token: 'reset-token'),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-new-password-field'),
        ),
        'new-password',
      );

      await tester.enterText(
        find.byKey(
          const ValueKey<String>('password-recovery-confirm-password-field'),
        ),
        'new-password',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('password-recovery-submit-button')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('password-recovery-failure')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('password-recovery-new-password-field'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('password-recovery-confirm-password-field'),
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _buildApp({
  required PasswordRecoveryRepository repository,
  required String? token,
}) {
  return BlocProvider<PasswordRecoveryCubit>(
    create: (BuildContext context) {
      return PasswordRecoveryCubit(repository: repository);
    },
    child: MaterialApp(
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: PasswordRecoveryPage(token: token),
    ),
  );
}

final class _FakePasswordRecoveryRepository
    implements PasswordRecoveryRepository {
  _FakePasswordRecoveryRepository({this.error});

  final AppException? error;

  int completeCalls = 0;

  String? lastToken;
  String? lastNewPassword;

  @override
  Future<void> complete({
    required String token,
    required String newPassword,
  }) async {
    completeCalls += 1;

    lastToken = token;
    lastNewPassword = newPassword;

    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }
  }
}
