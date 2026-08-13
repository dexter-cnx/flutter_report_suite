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
    expect(find.text('Layers'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
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
    expect(find.byType(DesignerLeftPanel), findsOneWidget);
    expect(find.byType(CanvasViewport), findsOneWidget);
    expect(find.byType(CanvasPage), findsOneWidget);
    expect(find.byType(CanvasRuler), findsNWidgets(2));
    expect(find.byType(DesignerInspector), findsOneWidget);
  });

  testWidgets('medium layout collapses Elements and preserves safe area',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());

    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byType(DesignerAppShell), findsOneWidget);
    expect(find.byType(CanvasViewport), findsOneWidget);
    expect(find.text('Elements'), findsNothing);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.byTooltip('Toggle Elements'), findsOneWidget);

    await tester.tap(find.byTooltip('Toggle Elements'));
    await tester.pump();

    expect(find.text('Elements'), findsOneWidget);
    expect(find.byType(DesignerLeftPanel), findsOneWidget);
  });

  testWidgets('desktop shell applies the normalized panel dimensions',
      (tester) async {
    await pumpDesktop(tester);

    final shell = find.byType(DesignerAppShell);
    expect(shell, findsOneWidget);

    final leftPanel = find.byType(DesignerLeftPanel);
    final inspectorHeader = find.widgetWithText(PanelHeader, 'Inspector');
    expect(leftPanel, findsOneWidget);
    expect(inspectorHeader, findsOneWidget);

    expect(
      tester.getSize(leftPanel).width,
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
    expect(find.byType(DesignerInspector), findsOneWidget);
    expect(find.byKey(const ValueKey('inspector-section-content')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('inspector-section-geometry')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('inspector-section-typography')),
        findsOneWidget);
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

  testWidgets('all current element types remain addable through ToolPanelItem',
      (tester) async {
    await pumpDesktop(tester);

    const types = [
      'text',
      'dynamic_text',
      'line',
      'table',
      'qrcode',
      'barcode',
    ];

    for (final type in types) {
      final tool = find.byKey(ValueKey('tool-$type'));
      expect(tool, findsOneWidget);
      expect(tester.widget<ToolPanelItem>(tool), isA<ToolPanelItem>());
      await tester.tap(tool);
      await tester.pump();
    }

    await tester.tap(find.byTooltip('Template actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View JSON'));
    await tester.pumpAndSettle();

    final jsonFinder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(SelectableText),
    );
    final jsonText = tester.widget<SelectableText>(jsonFinder).data ?? '';
    for (final type in types) {
      expect(jsonText, contains('"type": "$type"'));
    }
  });

  testWidgets('Layers shell reflects current elements and preserves selection',
      (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.byKey(const ValueKey('tool-text')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('left-panel-tab-layers')));
    await tester.pump();

    expect(find.byKey(const ValueKey('left-panel-layers-content')),
        findsOneWidget);
    expect(find.widgetWithText(PanelHeader, 'Layers'), findsOneWidget);
    expect(find.text('Sample text'), findsWidgets);
    expect(find.text('Add Element'), findsNothing);
  });

  testWidgets('Data shell exposes a capability-appropriate state only',
      (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.byKey(const ValueKey('left-panel-tab-data')));
    await tester.pump();

    expect(find.text('Data explorer is not available yet'), findsOneWidget);
    expect(find.byType(ToolPanelItem), findsNothing);
    expect(find.text('Add Element'), findsNothing);
  });

  testWidgets('table selection exposes the normalized column editor',
      (tester) async {
    await pumpDesktop(tester);

    await tester.tap(find.text('Table {{items}}'));
    await tester.pump();

    expect(find.text('{{items}}'), findsWidgets);
    expect(find.byKey(const ValueKey('inspector-section-table-columns')),
        findsOneWidget);
    expect(find.text('TABLE COLUMNS'), findsOneWidget);
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
