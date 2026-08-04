import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/theme/app_theme.dart';
import 'package:sofawatch/app/theme/extensions/sofawatch_theme_extension.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme dark', () {
    test('uses the SofaWatch dark color scheme', () {
      final ThemeData theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);

      expect(theme.colorScheme.primary, AppColors.primary);

      expect(theme.colorScheme.surface, AppColors.surface);

      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('uses Manrope typography', () {
      final ThemeData theme = AppTheme.dark;

      expect(theme.textTheme.bodyMedium?.fontFamily, contains('Manrope'));

      expect(theme.textTheme.titleLarge?.fontFamily, contains('Manrope'));
    });

    test('registers the SofaWatch extension', () {
      final ThemeData theme = AppTheme.dark;

      final SofaWatchThemeExtension? extension = theme
          .extension<SofaWatchThemeExtension>();

      expect(extension, isNotNull);

      expect(extension!.cardSurface, AppColors.surfaceLow);

      expect(extension.cardSurfaceHover, AppColors.surfaceHigh);

      expect(extension.glassSurface, AppColors.glassSurface);

      expect(extension.glassBlur, 20);
    });

    test('uses matching Material and Cupertino brand colors', () {
      final ThemeData theme = AppTheme.dark;

      expect(theme.colorScheme.primary, AppColors.primary);

      expect(theme.cupertinoOverrideTheme?.primaryColor, AppColors.primary);

      expect(theme.cupertinoOverrideTheme?.brightness, Brightness.dark);

      expect(
        theme.cupertinoOverrideTheme?.scaffoldBackgroundColor,
        AppColors.background,
      );
    });
  });

  testWidgets('provides the custom theme through BuildContext', (
    WidgetTester tester,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (BuildContext context) {
            capturedContext = context;

            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final SofaWatchThemeExtension extension = capturedContext.sofaWatchTheme;

    expect(extension.progressValue, AppColors.primary);

    expect(extension.modalBarrier, AppColors.modalBarrier);
  });

  testWidgets('applies consistent styling to Material and Cupertino widgets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              FilledButton(onPressed: null, child: Text('Material action')),
              CupertinoButton(onPressed: null, child: Text('Cupertino action')),
              CupertinoActivityIndicator(),
            ],
          ),
        ),
      ),
    );

    final BuildContext materialContext = tester.element(
      find.text('Material action'),
    );

    final BuildContext cupertinoContext = tester.element(
      find.text('Cupertino action'),
    );

    expect(Theme.of(materialContext).brightness, Brightness.dark);

    expect(CupertinoTheme.of(cupertinoContext).brightness, Brightness.dark);

    expect(CupertinoTheme.of(cupertinoContext).primaryColor, AppColors.primary);
  });
}
