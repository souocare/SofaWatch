import 'package:flutter/material.dart';
import 'package:sofawatch/shared/widgets/app_placeholder_page.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPlaceholderPage(
      title: 'Movies',
      pageKey: ValueKey<String>('movies-page-title'),
    );
  }
}
