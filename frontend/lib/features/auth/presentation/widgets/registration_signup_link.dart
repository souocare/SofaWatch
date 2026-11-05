import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';

class RegistrationSignupLink extends StatelessWidget {
  const RegistrationSignupLink({
    required this.availability,
    required this.onPressed,
    super.key,
  });

  final Future<bool> availability;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: availability,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data != true || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        return Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.xxl),
            TextButton(
              key: const ValueKey<String>('auth-login-register-link'),
              onPressed: onPressed,
              child: const Text("Don't have an account? Create an account"),
            ),
          ],
        );
      },
    );
  }
}
