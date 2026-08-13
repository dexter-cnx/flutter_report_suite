import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/design_system.dart';

void main() {
  testWidgets('DesignerLeftPanel switches between the three mode slots',
      (tester) async {
    var mode = DesignerLeftPanelMode.elements;

    Widget subject() => MaterialApp(
          theme: DesignerTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: DesignerLayout.leftPanelWidth,
              height: 500,
              child: DesignerLeftPanel(
                mode: mode,
                onModeChanged: (value) => setState(() => mode = value),
                elements: const Text('elements-content'),
                layers: const Text('layers-content'),
                data: const Text('data-content'),
              ),
            ),
          ),
        );

    await tester.pumpWidget(subject());

    expect(find.text('elements-content'), findsOneWidget);
    expect(find.text('layers-content'), findsNothing);
    expect(find.text('data-content'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('left-panel-tab-layers')));
    await tester.pump();
    expect(find.text('elements-content'), findsNothing);
    expect(find.text('layers-content'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('left-panel-tab-data')));
    await tester.pump();
    expect(find.text('layers-content'), findsNothing);
    expect(find.text('data-content'), findsOneWidget);
  });

  testWidgets('ToolPanelItem exposes canonical add affordance and callback',
      (tester) async {
    var presses = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: DesignerTheme.light(),
        home: Center(
          child: SizedBox(
            width: DesignerLayout.leftPanelWidth,
            child: ToolPanelItem(
              label: 'Text',
              icon: Icons.text_fields,
              onPressed: () => presses += 1,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ToolPanelItem)).height, greaterThanOrEqualTo(40));
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byType(ToolPanelItem));
    expect(presses, 1);
  });
}
