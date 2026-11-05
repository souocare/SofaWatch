import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sofawatch/features/auth/presentation/widgets/registration_signup_link.dart';

void main() {
  group('RegistrationSignupLink', () {
    testWidgets('shows the link when registration is open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(availability: Future<bool>.value(true)),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-login-register-link')),
        findsOneWidget,
      );
    });

    testWidgets('hides the link when registration is closed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(availability: Future<bool>.value(false)),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-login-register-link')),
        findsNothing,
      );
    });

    testWidgets('hides the link when availability fails', (
      WidgetTester tester,
    ) async {
      final Completer<bool> completer = Completer<bool>();

      await tester.pumpWidget(_buildApp(availability: completer.future));

      expect(
        find.byKey(const ValueKey<String>('auth-login-register-link')),
        findsNothing,
      );

      completer.completeError(Exception('Connection failed'));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-login-register-link')),
        findsNothing,
      );
    });

    testWidgets('does not show the link while loading', (
      WidgetTester tester,
    ) async {
      final Completer<bool> completer = Completer<bool>();

      await tester.pumpWidget(_buildApp(availability: completer.future));

      expect(
        find.byKey(const ValueKey<String>('auth-login-register-link')),
        findsNothing,
      );

      completer.complete(true);

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-login-register-link')),
        findsOneWidget,
      );
    });

    testWidgets('executes navigation callback when tapped', (
      WidgetTester tester,
    ) async {
      int navigationCalls = 0;

      await tester.pumpWidget(
        _buildApp(
          availability: Future<bool>.value(true),
          onPressed: () {
            navigationCalls++;
          },
        ),
      );

      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('auth-login-register-link')),
      );

      expect(navigationCalls, 1);
    });
  });
}

Widget _buildApp({
  required Future<bool> availability,
  VoidCallback? onPressed,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: RegistrationSignupLink(
          availability: availability,
          onPressed: onPressed ?? () {},
        ),
      ),
    ),
  );
}
