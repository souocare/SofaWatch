import 'package:flutter/material.dart';

class AuthCheckingPage extends StatelessWidget {
  const AuthCheckingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          key: ValueKey<String>('auth-checking-progress'),
        ),
      ),
    );
  }
}
