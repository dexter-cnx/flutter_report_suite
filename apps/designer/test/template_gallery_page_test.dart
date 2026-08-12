import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/pages/template_gallery_page.dart';

void main() {
  testWidgets('shows blank and four built-in templates', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TemplateGalleryPage()));

    expect(find.text('Report Templates'), findsOneWidget);
    expect(find.text('Blank Template'), findsOneWidget);
    expect(find.text('80mm Receipt'), findsOneWidget);
    expect(find.text('58mm Receipt'), findsOneWidget);
    expect(find.text('A4 Invoice'), findsOneWidget);
    expect(find.text('4x6 Sticker'), findsOneWidget);
  });

  testWidgets('built-in template opens as an editable working copy',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TemplateGalleryPage()));
    await tester.tap(find.text('80mm Receipt'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Report Designer'), findsOneWidget);
    expect(find.textContaining('-copy'), findsOneWidget);

    // 1200 px uses the medium workspace, where Elements is collapsed by
    // default so the canvas keeps priority. Confirm the panel remains
    // available through the toolbar toggle.
    final toggle = find.byTooltip('Toggle Elements');
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(find.text('Elements'), findsOneWidget);
  });
}
