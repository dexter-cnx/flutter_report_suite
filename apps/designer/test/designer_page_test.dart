import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/design_system.dart';
import 'package:report_designer/pages/designer_page.dart';

void main() {
  Widget buildSubject() => MaterialApp(
        theme: DesignerTheme.light(),
        home: const DesignerPage(),
      );

  Future<void> pumpDesktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
  }

  testWidgets('boots designer on the canonical shell and canvas',
      (tester) async {
    await pumpDesktop(tester);

    expect(find.text('Report Designer'), findsOneWidget);
    expect(find.text('Elements'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Dynamic {{field}}'), findsOneWidget);
    expect(find.text('Table {{items}}'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Redo'), findsOneWidget);
    expect(find.byTooltip('Preview PDF'), findsOneWidget);
    expect(find.byTooltip('Template actions'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.textContaining('5 mm snap grid'), findsOneWidget);
    expect(find.byType(DesignerAppShell), findsOneWidget);
    expect(find.byType(CanvasViewport), findsOneWidget);
    expect(find.byType(CanvasPage), findsOneWidget);
    expect(find.byType(CanvasRuler), findsNWidgets(2));
  });

  testWidgets('desktop shell applies the normalized panel dimensions',
      (tester) async {
    await pumpDesktop(tester);

    final shell = find.byType(DesignerAppShell);
    expect(shell, findsOneWidget);

    final elementsHeader = find.widgetWithText(PanelHeader, 'Elements');
    final inspectorHeader = find.widgetWithText(PanelHeader, 'Inspector');
    expect(elementsHeader, findsOneWidget);
    expect(inspectorHeader, findsOneWidget);

    expect(
      tester.getSize(elementsHeader).width,
      DesignerLayout.leftPanelWidth,
    );
    expect(
      tester.getSize(inspectorHeader).width,
      DesignerLayout.rightInspectorWidth,
    );
  });

  testWidgets('adding text selects it and exposes editable properties',
      (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Text'));
    await tester.pump();

    expect(find.text('Sample text'), findsWidgets);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Key / Text'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);
    expect(find.byType(CanvasSelectionOverlay), findsWidgets);

    final selectedOverlay = tester.widgetList<CanvasSelectionOverlay>(
      find.byType(CanvasSelectionOverlay),
    );
    expect(selectedOverlay.any((overlay) => overlay.selected), isTrue);

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

  testWidgets('view JSON action contains current template schema',
      (tester) async {
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
