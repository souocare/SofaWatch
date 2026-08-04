import 'package:flutter/material.dart';
import 'package:sofawatch/shared/widgets/app_placeholder_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPlaceholderPage(
      title: 'Profile',
      pageKey: ValueKey<String>('profile-page-title'),
    );
  }
}
