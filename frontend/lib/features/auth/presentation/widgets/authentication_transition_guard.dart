import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/presentation/pages/auth_checking_page.dart';

final class AuthenticationTransitionGuard extends StatelessWidget {
  const AuthenticationTransitionGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            child,
            if (authState is AuthUnauthenticated)
              const Positioned.fill(
                child: AuthCheckingPage(
                  key: ValueKey<String>('authentication-transition-guard'),
                ),
              ),
          ],
        );
      },
    );
  }
}
