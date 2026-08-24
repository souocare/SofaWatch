import 'package:flutter/material.dart';

class InitialSetupPage extends StatelessWidget {
  const InitialSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Create your SofaWatch account',
          key: ValueKey<String>('auth-initial-setup-page-title'),
        ),
      ),
    );
  }
}
