import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/app/theme/tokens/app_typography.dart';

class AppPlaceholderPage extends StatelessWidget {
  const AppPlaceholderPage({
    required this.title,
    required this.pageKey,
    this.showAppBar = false,
    super.key,
  });

  final String title;
  final Key pageKey;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final Widget body = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          title,
          key: pageKey,
          style: AppTypography.headlineLargeMobile,
        ),
      ),
    );

    if (!showAppBar) {
      return Scaffold(body: body);
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
