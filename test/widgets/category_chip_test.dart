import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/color_tokens.dart';
import 'package:kolabing_app/widgets/category_chip.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        extensions: <ThemeExtension<dynamic>>[
          if (brightness == Brightness.dark)
            KolabingColorTokens.night
          else
            KolabingColorTokens.light,
        ],
      ),
      home: Scaffold(body: Center(child: child)),
    );

Color _chipFill(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(CategoryChip),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('known category renders its semantic pastel style', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const CategoryChip(label: 'Sports')));

    expect(find.text('Sports'), findsOneWidget);
    expect(_chipFill(tester), KolabingColorTokens.light.categoryChipSportsBg);

    final text = tester.widget<Text>(find.text('Sports'));
    expect(text.style?.color, KolabingColorTokens.light.categoryChipSportsText);
  });

  testWidgets('label spelling variants share one style', (tester) async {
    await tester.pumpWidget(_host(const CategoryChip(label: 'food_and_drink')));
    final a = _chipFill(tester);

    await tester.pumpWidget(_host(const CategoryChip(label: 'Food & Drink')));
    final b = _chipFill(tester);

    expect(a, b);
    expect(a, KolabingColorTokens.light.categoryChipFoodBg);
  });

  testWidgets('display label is preserved verbatim', (tester) async {
    const raw = 'Food & Drink';
    await tester.pumpWidget(_host(const CategoryChip(label: raw)));
    expect(find.text(raw), findsOneWidget);
  });

  testWidgets('unknown category renders without error, neutral fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const CategoryChip(label: 'Quantum Basket Weaving')),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Quantum Basket Weaving'), findsOneWidget);
    expect(_chipFill(tester), KolabingColorTokens.light.categoryChipNeutralBg);
  });

  testWidgets('optional leading icon renders only when supplied', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const CategoryChip(label: 'Sports')));
    expect(find.byIcon(Icons.star), findsNothing);

    await tester.pumpWidget(
      _host(
        const CategoryChip(
          label: 'Sports',
          leading: Icon(Icons.star, size: 14),
        ),
      ),
    );
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('Sports'), findsOneWidget);
  });

  testWidgets('dark mode resolves the night token set', (tester) async {
    await tester.pumpWidget(
      _host(const CategoryChip(label: 'Wellness'), brightness: Brightness.dark),
    );

    expect(_chipFill(tester), KolabingColorTokens.night.categoryChipWellnessBg);
  });
}
