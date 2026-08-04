import 'package:flutter/material.dart';
import 'package:sofawatch/shared/widgets/app_placeholder_page.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPlaceholderPage(
      title: 'Explore',
      pageKey: ValueKey<String>('explore-page-title'),
    );
  }
}
