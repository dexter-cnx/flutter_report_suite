import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine_example/main.dart';

void main() {
  testWidgets('renders report engine example actions', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('report_engine Example'), findsOneWidget);
    expect(find.text('Thermal 80 mm receipt'), findsOneWidget);
    expect(find.text('Thermal 58 mm receipt'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('A4 invoice with page breaking'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('A4 invoice with page breaking'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Thai PDF preview / share'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Thai PDF preview / share'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Generate legacy ESC/POS quick receipt'),
      200,
      scrollable: scrollable,
    );
    expect(
      find.text('Generate legacy ESC/POS quick receipt'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Generate Thai raster ESC/POS receipt'),
      200,
      scrollable: scrollable,
    );
    expect(
      find.text('Generate Thai raster ESC/POS receipt'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Export A4 template JSON to clipboard'),
      200,
      scrollable: scrollable,
    );
    expect(
      find.text('Export A4 template JSON to clipboard'),
      findsOneWidget,
    );
  });
}
