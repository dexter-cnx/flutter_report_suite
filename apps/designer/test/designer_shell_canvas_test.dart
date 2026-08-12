import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/canvas_primitives.dart';
import 'package:report_designer/design_system/designer_layout.dart';
import 'package:report_designer/design_system/designer_shell.dart';
import 'package:report_designer/design_system/designer_theme.dart';

void main() {
  Widget subject(Widget child) => MaterialApp(
        theme: DesignerTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets('DesignerAppShell applies canonical desktop dimensions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      subject(
        const DesignerAppShell(
          toolbar: SizedBox(key: Key('toolbar')),
          leftPanel: SizedBox(key: Key('left')),
          workspace: SizedBox(key: Key('workspace')),
          rightPanel: SizedBox(key: Key('right')),
          statusBar: SizedBox(key: Key('status')),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('toolbar'))).height,
      DesignerLayout.topToolbarHeight,
    );
    expect(
      tester.getSize(find.byKey(const Key('left'))).width,
      DesignerLayout.leftPanelWidth,
    );
    expect(
      tester.getSize(find.byKey(const Key('right'))).width,
      DesignerLayout.rightInspectorWidth,
    );
    expect(
      tester.getSize(find.byKey(const Key('status'))).height,
      DesignerLayout.statusBarHeight,
    );
  });

  testWidgets('CanvasPage preserves requested printable dimensions',
      (tester) async {
    await tester.pumpWidget(
      subject(
        const Center(
          child: CanvasPage(
            width: 240,
            height: 600,
            child: SizedBox(),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(CanvasPage)), const Size(240, 600));
  });

  testWidgets('CanvasRuler renders millimeter marks', (tester) async {
    await tester.pumpWidget(
      subject(
        const CanvasRuler(
          axis: CanvasRulerAxis.horizontal,
          lengthMm: 80,
          scale: 3,
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('CanvasSelectionOverlay exposes four resize handles',
      (tester) async {
    await tester.pumpWidget(
      subject(
        const Center(
          child: SizedBox(
            width: 120,
            height: 48,
            child: CanvasSelectionOverlay(
              child: Text('Selected'),
            ),
          ),
        ),
      ),
    );

    final containers = tester.widgetList<Container>(find.byType(Container));
    final handleCount = containers.where((container) {
      return container.constraints == null &&
          container.width == DesignerLayout.selectionHandleSize &&
          container.height == DesignerLayout.selectionHandleSize;
    }).length;

    expect(handleCount, 4);
  });
}
