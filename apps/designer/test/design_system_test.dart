import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/designer_colors.dart';
import 'package:report_designer/design_system/designer_controls.dart';
import 'package:report_designer/design_system/designer_layout.dart';
import 'package:report_designer/design_system/designer_theme.dart';

void main() {
  Widget subject(Widget child) => MaterialApp(
        theme: DesignerTheme.light(),
        home: Scaffold(body: Center(child: child)),
      );

  test('canonical layout and color tokens match handoff', () {
    expect(DesignerLayout.topToolbarHeight, 56);
    expect(DesignerLayout.leftPanelWidth, 264);
    expect(DesignerLayout.rightInspectorWidth, 320);
    expect(DesignerLayout.statusBarHeight, 32);
    expect(DesignerLayout.selectionHandleSize, 8);
    expect(DesignerColors.primary, const Color(0xFF6366F1));
  });

  testWidgets('ToolbarButton owns canonical 32px control size', (tester) async {
    await tester.pumpWidget(
      subject(
        const ToolbarButton(
          icon: Icons.undo,
          tooltip: 'Undo',
        ),
      ),
    );

    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(tester.getSize(find.byType(IconButton)), const Size(32, 32));
  });

  testWidgets('InspectorSection expands and collapses', (tester) async {
    await tester.pumpWidget(
      subject(
        const SizedBox(
          width: 320,
          child: InspectorSection(
            title: 'Transform',
            child: Text('Transform content'),
          ),
        ),
      ),
    );

    expect(find.text('TRANSFORM'), findsOneWidget);
    expect(find.text('Transform content'), findsOneWidget);

    await tester.tap(find.text('TRANSFORM'));
    await tester.pump();

    expect(find.text('Transform content'), findsNothing);
  });

  testWidgets('ZoomControl disables buttons at bounds', (tester) async {
    double? changed;
    await tester.pumpWidget(
      subject(
        ZoomControl(
          value: 0.5,
          onChanged: (value) => changed = value,
        ),
      ),
    );

    expect(find.text('50%'), findsOneWidget);
    final minus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(minus.onPressed, isNull);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    expect(changed, closeTo(0.6, 0.0001));
  });

  testWidgets('InlineAlert communicates severity with icon and text',
      (tester) async {
    await tester.pumpWidget(
      subject(
        const InlineAlert(
          message: 'Field no longer exists',
          severity: InlineAlertSeverity.warning,
        ),
      ),
    );

    expect(find.text('Field no longer exists'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });
}
