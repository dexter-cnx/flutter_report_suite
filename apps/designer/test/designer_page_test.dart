import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/pages/designer_page.dart';

void main() {
  Widget buildSubject() => const MaterialApp(home: DesignerPage());

  Future<void> pumpDesktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
  }

  testWidgets('boots designer with lifecycle and precision controls', (tester) async {
    await pumpDesktop(tester);

    expect(find.text('Report Designer'), findsOneWidget);
    expect(find.text('Add Element'), findsOneWidget);
    expect(find.text('Dynamic {{field}}'), findsOneWidget);
    expect(find.text('Table {{items}}'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Redo'), findsOneWidget);
    expect(find.byTooltip('Preview PDF'), findsOneWidget);
    expect(find.byTooltip('Template actions'), findsOneWidget);
    expect(find.textContaining('Zoom'), findsOneWidget);
    expect(find.textContaining('5 mm snap grid'), findsOneWidget);
  });

  testWidgets('adding text selects it and exposes editable properties', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Text'));
    await tester.pump();

    expect(find.text('Sample text'), findsWidgets);
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Key / Text'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);

    final undoButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.undo),
    );
    expect(undoButton.onPressed, isNotNull);
  });

  testWidgets('table selection exposes the column editor', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Table {{items}}'));
    await tester.pump();

    expect(find.text('{{items}}'), findsWidgets);
    expect(find.text('Table Columns'), findsOneWidget);
    expect(find.byTooltip('Add column'), findsOneWidget);
    expect(find.byTooltip('Remove column'), findsWidgets);
  });

  testWidgets('view JSON action contains current template schema', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Dynamic {{field}}'));
    await tester.pump();
    await tester.tap(find.byTooltip('Template actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View JSON'));
    await tester.pumpAndSettle();

    expect(find.text('Template JSON'), findsOneWidget);
    final jsonFinder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(SelectableText),
    );
    final jsonText = tester.widget<SelectableText>(jsonFinder).data ?? '';
    expect(jsonText, contains('"version": 1'));
    expect(jsonText, contains('"type": "dynamic_text"'));
    expect(jsonText, contains('{{shop.name}}'));
  });
}
