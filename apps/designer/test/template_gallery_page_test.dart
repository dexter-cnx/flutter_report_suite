import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/design_system.dart';
import 'package:report_designer/pages/template_gallery_page.dart';

void main() {
  Widget buildSubject() => MaterialApp(
        theme: DesignerTheme.light(),
        home: const TemplateGalleryPage(),
      );

  Future<void> pumpAtWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
  }

  testWidgets('shows blank and four built-in templates in shared shell',
      (tester) async {
    await pumpAtWidth(tester, 1200);

    expect(find.text('Report Templates'), findsOneWidget);
    expect(find.text('Blank Template'), findsOneWidget);
    expect(find.text('80mm Receipt'), findsOneWidget);
    expect(find.text('58mm Receipt'), findsOneWidget);
    expect(find.text('A4 Invoice'), findsOneWidget);
    expect(find.text('4x6 Sticker'), findsOneWidget);
    expect(find.byType(DesignerAppShell), findsOneWidget);
    expect(find.byType(TemplateCard), findsNWidgets(5));
    expect(find.byKey(const ValueKey('template-gallery-grid-4')), findsOneWidget);
  });

  testWidgets('gallery uses 4, 2, and 1 responsive columns', (tester) async {
    await pumpAtWidth(tester, 1200);
    expect(find.byKey(const ValueKey('template-gallery-grid-4')), findsOneWidget);

    tester.view.physicalSize = const Size(900, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('template-gallery-grid-2')), findsOneWidget);

    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('template-gallery-grid-1')), findsOneWidget);
  });

  testWidgets('blank template opens a new unsaved designer', (tester) async {
    await pumpAtWidth(tester, 1200);

    await tester.tap(find.byKey(const ValueKey('template-card-blank')));
    await tester.pumpAndSettle();

    expect(find.text('Report Designer'), findsOneWidget);
    expect(find.textContaining('-copy'), findsNothing);
  });

  testWidgets('built-in template opens as an editable working copy',
      (tester) async {
    await pumpAtWidth(tester, 1200);

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
