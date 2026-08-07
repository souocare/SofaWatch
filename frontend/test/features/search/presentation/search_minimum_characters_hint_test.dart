import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_minimum_characters_hint.dart';

void main() {
  group('SearchMinimumCharactersHint', () {
    testWidgets('shows the singular message for one remaining character', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchMinimumCharactersHint(remainingCharacters: 1),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('search-minimum-characters-hint')),
        findsOneWidget,
      );

      expect(find.text('Type 1 more character to search.'), findsOneWidget);
    });

    testWidgets('shows the plural message for multiple remaining characters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchMinimumCharactersHint(remainingCharacters: 3),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('search-minimum-characters-hint')),
        findsOneWidget,
      );

      expect(find.text('Type 3 more characters to search.'), findsOneWidget);
    });

    testWidgets('centers the guidance message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchMinimumCharactersHint(remainingCharacters: 1),
          ),
        ),
      );

      final Text text = tester.widget<Text>(
        find.byKey(const ValueKey<String>('search-minimum-characters-hint')),
      );

      expect(text.textAlign, TextAlign.center);
    });
  });
}
