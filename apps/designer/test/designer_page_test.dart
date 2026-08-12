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

  testWidgets('boots the designer with the main authoring controls', (tester) async {
    await pumpDesktop(tester);

    expect(find.text('Report Designer'), findsOneWidget);
    expect(find.text('Add Element'), findsOneWidget);
    expect(find.text('Text'), findsOneWidget);
    expect(find.text('Dynamic {{field}}'), findsOneWidget);
    expect(find.text('Table {{items}}'), findsOneWidget);
    expect(find.byTooltip('Preview PDF'), findsOneWidget);
    expect(find.byTooltip('Export JSON'), findsOneWidget);
  });

  testWidgets('adding text selects it and exposes editable properties', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Text'));
    await tester.pump();

    expect(find.text('Sample text'), findsOneWidget);
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Key / Text'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);
  });

  testWidgets('table elements use the items expression by default', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Table {{items}}'));
    await tester.pump();

    expect(find.text('{{items}}'), findsOneWidget);
    expect(find.text('Properties'), findsOneWidget);
  });

  testWidgets('export dialog contains the current template JSON', (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Dynamic {{field}}'));
    await tester.pump();
    await tester.tap(find.byTooltip('Export JSON'));
    await tester.pumpAndSettle();

    expect(find.text('Template JSON'), findsOneWidget);
    expect(find.textContaining('"type": "dynamic_text"'), findsOneWidget);
    expect(find.textContaining('{{shop.name}}'), findsOneWidget);
  });
}
