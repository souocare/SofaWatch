import 'package:flutter/material.dart';
import 'package:sofawatch/shared/widgets/app_placeholder_page.dart';

class ShowsPage extends StatelessWidget {
  const ShowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPlaceholderPage(
      title: 'Shows',
      pageKey: ValueKey<String>('shows-page-title'),
    );
  }
}
