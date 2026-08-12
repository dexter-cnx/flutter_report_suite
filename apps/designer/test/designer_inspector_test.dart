import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/design_system.dart';

void main() {
  Widget buildInspector({Map<String, dynamic>? element}) {
    return MaterialApp(
      theme: DesignerTheme.light(),
      home: Scaffold(
        body: SizedBox(
          width: DesignerLayout.inspectorWidth,
          child: DesignerInspector(
            element: element,
            onContentSubmitted: (_) {},
            onGeometrySubmitted: (_, __) {},
            onFontSizeSubmitted: (_) {},
            onBoldChanged: (_) {},
            onAlignmentChanged: (_) {},
            onDelete: () {},
            tableColumns: element?['type'] == 'table'
                ? List<Map<String, dynamic>>.from(
                    (element?['columns'] as List<dynamic>).map(
                      (value) => Map<String, dynamic>.from(value as Map),
                    ),
                  )
                : const [],
          ),
        ),
      ),
    );
  }

  testWidgets('shows empty inspector state without a selection', (tester) async {
    await tester.pumpWidget(buildInspector());

    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Select an element to edit'), findsOneWidget);
  });

  testWidgets('groups supported fields into normalized sections', (tester) async {
    final element = <String, dynamic>{
      'id': 'text-1',
      'type': 'text',
      'key': 'Sample text',
      'x': 5.0,
      'y': 10.0,
      'w': 60.0,
      'h': 10.0,
      'style': <String, dynamic>{
        'fontSize': 12.0,
        'bold': true,
        'align': 'center',
      },
    };

    await tester.pumpWidget(buildInspector(element: element));

    expect(find.byKey(const ValueKey('inspector-section-content')), findsOneWidget);
    expect(find.byKey(const ValueKey('inspector-section-geometry')), findsOneWidget);
    expect(find.byKey(const ValueKey('inspector-section-typography')), findsOneWidget);
    expect(find.text('Key / Text'), findsOneWidget);
    expect(find.text('Font Size'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);
    expect(find.text('Alignment'), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-element-button')), findsOneWidget);
  });

  testWidgets('shows table column section only for table elements', (tester) async {
    final element = <String, dynamic>{
      'id': 'table-1',
      'type': 'table',
      'key': '{{items}}',
      'x': 5.0,
      'y': 10.0,
      'w': 60.0,
      'h': 35.0,
      'style': <String, dynamic>{
        'fontSize': 10.0,
        'bold': false,
        'align': 'left',
      },
      'columns': <Map<String, dynamic>>[
        {
          'key': 'name',
          'label': 'Item',
          'width': 2.0,
          'alignment': 'left',
        },
      ],
    };

    await tester.pumpWidget(buildInspector(element: element));

    expect(
      find.byKey(const ValueKey('inspector-section-table-columns')),
      findsOneWidget,
    );
    expect(find.text('TABLE COLUMNS'), findsOneWidget);
    expect(find.text('Item'), findsOneWidget);
  });
}
