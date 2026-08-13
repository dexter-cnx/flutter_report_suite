import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/design_system.dart';

void main() {
  Widget buildInspector({
    Map<String, dynamic>? element,
    ValueChanged<double>? onFontSizeSubmitted,
  }) {
    return MaterialApp(
      theme: DesignerTheme.light(),
      home: Scaffold(
        body: SizedBox(
          width: DesignerLayout.rightInspectorWidth,
          child: DesignerInspector(
            element: element,
            onContentSubmitted: (_) {},
            onGeometrySubmitted: (_, __) {},
            onFontSizeSubmitted: onFontSizeSubmitted ?? (_) {},
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

  Map<String, dynamic> textElement({
    required String id,
    String key = 'Sample text',
    double fontSize = 12,
  }) =>
      <String, dynamic>{
        'id': id,
        'type': 'text',
        'key': key,
        'x': 5.0,
        'y': 10.0,
        'w': 60.0,
        'h': 10.0,
        'style': <String, dynamic>{
          'fontSize': fontSize,
          'bold': true,
          'align': 'center',
        },
      };

  testWidgets('shows empty inspector state without a selection',
      (tester) async {
    await tester.pumpWidget(buildInspector());

    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Select an element to edit'), findsOneWidget);
  });

  testWidgets('groups supported fields into normalized sections',
      (tester) async {
    final element = textElement(id: 'text-1');

    await tester.pumpWidget(buildInspector(element: element));

    expect(find.byKey(const ValueKey('inspector-section-content')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('inspector-section-geometry')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('inspector-section-typography')),
        findsOneWidget);
    expect(find.text('Key / Text'), findsOneWidget);
    expect(find.text('Font Size'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);
    expect(find.text('Alignment'), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-element-button')), findsOneWidget);
  });

  testWidgets('keys the editable inspector subtree by selected element id',
      (tester) async {
    await tester.pumpWidget(
      buildInspector(element: textElement(id: 'text-1')),
    );

    expect(
      find.byKey(const ValueKey('designer-inspector-text-1')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      buildInspector(element: textElement(id: 'text-2')),
    );

    expect(
      find.byKey(const ValueKey('designer-inspector-text-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('designer-inspector-text-2')),
      findsOneWidget,
    );
  });

  testWidgets('accepts only finite font sizes within the supported range',
      (tester) async {
    final submitted = <double>[];
    await tester.pumpWidget(
      buildInspector(
        element: textElement(id: 'text-1'),
        onFontSizeSubmitted: submitted.add,
      ),
    );

    final fontSizeInput = tester
        .widgetList<NumberPropertyInput>(find.byType(NumberPropertyInput))
        .singleWhere((input) => input.label == 'Font Size');

    fontSizeInput.onSubmitted(double.nan);
    fontSizeInput.onSubmitted(double.infinity);
    fontSizeInput.onSubmitted(-1);
    fontSizeInput.onSubmitted(5.9);
    fontSizeInput.onSubmitted(30.1);
    fontSizeInput.onSubmitted(6);
    fontSizeInput.onSubmitted(30);

    expect(submitted, <double>[6, 30]);
  });

  testWidgets('shows table column section only for table elements',
      (tester) async {
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
