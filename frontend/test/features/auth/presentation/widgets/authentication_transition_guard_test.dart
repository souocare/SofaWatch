import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/presentation/widgets/authentication_transition_guard.dart';

void main() {
  group('AuthenticationTransitionGuard', () {
    testWidgets('shows protected content while authenticated', (
      WidgetTester tester,
    ) async {
      final _FakeAuthRepository repository = _FakeAuthRepository();
      final AuthCubit authCubit = AuthCubit(repository: repository);

      addTearDown(authCubit.close);

      authCubit.authenticated(_authenticatedSession);

      await tester.pumpWidget(_buildApp(authCubit: authCubit));

      expect(
        find.byKey(const ValueKey<String>('protected-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('authentication-transition-guard')),
        findsNothing,
      );
    });

    testWidgets(
      'covers protected content immediately when authentication is lost',
      (WidgetTester tester) async {
        final _FakeAuthRepository repository = _FakeAuthRepository();
        final AuthCubit authCubit = AuthCubit(repository: repository);

        addTearDown(authCubit.close);

        authCubit.authenticated(_authenticatedSession);

        await tester.pumpWidget(_buildApp(authCubit: authCubit));

        authCubit.authenticationLost();

        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('authentication-transition-guard')),
          findsOneWidget,
        );

        //
        // Protected content remains mounted underneath the transition guard.
        //
        // This preserves its navigation and feature state while the router
        // replaces the protected route with the authentication flow.
        //
        expect(
          find.byKey(const ValueKey<String>('protected-content')),
          findsOneWidget,
        );
      },
    );
  });
}

const AuthSession _authenticatedSession = AuthSession(
  accessToken: 'access-token',
  expiresIn: Duration(minutes: 15),
);

Widget _buildApp({required AuthCubit authCubit}) {
  return BlocProvider<AuthCubit>.value(
    value: authCubit,
    child: const MaterialApp(
      home: AuthenticationTransitionGuard(
        child: Scaffold(
          body: SizedBox(key: ValueKey<String>('protected-content')),
        ),
      ),
    ),
  );
}

final class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restore() async {
    return null;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutEverywhere() async {}

  @override
  Future<void> clearLocalAuthentication() async {}

  @override
  Future<AuthSession> initialSetup({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) {
    throw UnimplementedError();
  }
}
