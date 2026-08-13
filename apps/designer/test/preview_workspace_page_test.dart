import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/design_system.dart';
import 'package:report_designer/pages/esc_pos_preview_panel.dart';
import 'package:report_designer/pages/preview_workspace_page.dart';

void main() {
  Future<void> pumpPreview(
    WidgetTester tester, {
    SystemPrintAction? onSystemPrint,
    List<int> escPosBytes = const [0x1B, 0x40, 0x48, 0x69],
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: DesignerTheme.light(),
        home: PreviewWorkspacePage(
          pdfBytes: Uint8List.fromList(const [1, 2, 3, 4]),
          escPosBytes: escPosBytes,
          paper: const {
            'type': 'thermal',
            'widthMm': 80.0,
            'heightMm': 200.0,
            'autoHeight': true,
          },
          title: 'Receipt Preview',
          previewBuilder: (_) => const ColoredBox(
            key: ValueKey('preview-content-stub'),
            color: Colors.white,
          ),
          onSystemPrint: onSystemPrint,
        ),
      ),
    );
  }

  testWidgets('renders unified preview shell with actual paper metadata',
      (tester) async {
    await pumpPreview(tester);

    expect(find.byType(DesignerAppShell), findsOneWidget);
    expect(find.text('Receipt Preview'), findsOneWidget);
    expect(find.text('Preview Settings'), findsOneWidget);
    expect(find.text('PDF / System Print'), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-content-stub')), findsOneWidget);
    expect(
        find.textContaining('THERMAL · 80.0 mm · auto height'), findsWidgets);
    expect(find.byTooltip('System Print'), findsOneWidget);
  });

  testWidgets('switches from PDF to rendered ESC/POS bytes', (tester) async {
    await pumpPreview(tester);

    await tester.tap(find.text('ESC/POS'));
    await tester.pump();

    expect(find.byType(EscPosPreviewPanel), findsOneWidget);
    expect(find.text('ESC/POS / Rendered bytes'), findsOneWidget);
    expect(find.text('4 bytes rendered by report_engine'), findsOneWidget);
    expect(find.textContaining('1B 40 48 69'), findsOneWidget);
    expect(find.byTooltip('System Print'), findsNothing);
    expect(
        find.text('ESC/POS preview · transport not selected'), findsOneWidget);
  });

  testWidgets('hides ESC/POS mode when no rendered bytes are available',
      (tester) async {
    await pumpPreview(tester, escPosBytes: const []);

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('ESC/POS'), findsNothing);
    expect(find.byTooltip('System Print'), findsOneWidget);
    expect(find.byType(EscPosPreviewPanel), findsNothing);
  });

  testWidgets('routes system print through the injected platform action',
      (tester) async {
    var printCount = 0;
    await pumpPreview(
      tester,
      onSystemPrint: (_) async => printCount++,
    );

    await tester.tap(find.byKey(const ValueKey('preview-system-print-button')));
    await tester.pump();

    expect(printCount, 1);
    expect(find.byKey(const ValueKey('preview-print-error')), findsNothing);
  });

  testWidgets('surfaces platform print failures with InlineAlert',
      (tester) async {
    await pumpPreview(
      tester,
      onSystemPrint: (_) async => throw StateError('printer unavailable'),
    );

    await tester.tap(find.byKey(const ValueKey('preview-system-print-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('preview-print-error')), findsOneWidget);
    expect(find.textContaining('printer unavailable'), findsOneWidget);
  });
}
