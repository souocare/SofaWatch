import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('home-page'),
      backgroundColor: AppColors.surface,
      body: const SafeArea(
        child: _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useDesktopLayout =
            constraints.maxWidth >= AppBreakpoints.tablet;

        return SingleChildScrollView(
          key: const ValueKey<String>('home-scroll-view'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            useDesktopLayout
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            AppSpacing.xxl,
            useDesktopLayout
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            AppSpacing.section,
          ),
          child: Center(
            child: ConstrainedBox(
              key: const ValueKey<String>('home-content'),
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: const _HomeContent(),
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    /*
     * Home intentionally starts with presentation structure only.
     *
     * The Header, Statistics and server-backed sections are introduced
     * independently in the following Home milestones.
     *
     * Keeping this container stable means those sections can evolve without
     * changing the page-level responsive layout or scroll ownership.
     */
    return Column(
      key: const ValueKey<String>('home-sections'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Home',
          key: const ValueKey<String>('home-page-title'),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}