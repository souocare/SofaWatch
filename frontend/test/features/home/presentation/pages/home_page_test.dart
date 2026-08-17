import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/presentation/pages/home_page.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders the Home page structure', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

      expect(find.byKey(const ValueKey<String>('home-header')), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('home-greeting')),
        findsOneWidget,
      );

      expect(find.byKey(const ValueKey<String>('home-date')), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('home-user-avatar')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('home-sections')),
        findsOneWidget,
      );
    });

    testWidgets('uses a scrollable Home layout', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('home-scroll-view')),
        findsOneWidget,
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses mobile horizontal padding on a narrow viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(
        const Size(AppBreakpoints.mobile - 100, 800),
      );

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final SingleChildScrollView scrollView = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey<String>('home-scroll-view')),
          );

      expect(
        scrollView.padding,
        const EdgeInsets.fromLTRB(
          AppSpacing.mobileHorizontalPadding,
          AppSpacing.xxl,
          AppSpacing.mobileHorizontalPadding,
          AppSpacing.section,
        ),
      );
    });

    testWidgets('uses desktop horizontal padding on a wide viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(
        const Size(AppBreakpoints.desktop + 200, 900),
      );

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final SingleChildScrollView scrollView = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey<String>('home-scroll-view')),
          );

      expect(
        scrollView.padding,
        const EdgeInsets.fromLTRB(
          AppSpacing.desktopHorizontalPadding,
          AppSpacing.xxl,
          AppSpacing.desktopHorizontalPadding,
          AppSpacing.section,
        ),
      );
    });

    testWidgets('limits Home content width on an ultrawide viewport', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(2200, 1000));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      final ConstrainedBox content = tester.widget<ConstrainedBox>(
        find.byKey(const ValueKey<String>('home-content')),
      );

      expect(content.constraints.maxWidth, AppSpacing.maxContentWidth);

      final Size contentSize = tester.getSize(
        find.byKey(const ValueKey<String>('home-content')),
      );

      expect(contentSize.width, lessThanOrEqualTo(AppSpacing.maxContentWidth));
    });
  });
}

Widget _buildTestApp() {
  return const MaterialApp(home: HomePage());
}
