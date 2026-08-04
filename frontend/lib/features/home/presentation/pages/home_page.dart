import 'package:flutter/material.dart';
import 'package:sofawatch/shared/widgets/app_placeholder_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPlaceholderPage(
      title: 'Home',
      pageKey: ValueKey<String>('home-page-title'),
    );
  }
}
