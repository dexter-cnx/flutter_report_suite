import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:report_designer/design_system/design_system.dart';

void main() {
  testWidgets('renders model-backed columns and routes actions',
      (tester) async {
    var addCount = 0;
    int? removed;
    (int, int)? moved;

    await tester.pumpWidget(
      MaterialApp(
        theme: DesignerTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: TableColumnEditor(
              columns: const [
                {
                  'key': 'name',
                  'label': 'Name',
                  'width': 2.0,
                  'alignment': 'left',
                },
                {
                  'key': 'qty',
                  'label': 'Qty',
                  'width': 1.0,
                  'alignment': 'right',
                },
              ],
              onAdd: () => addCount++,
              onMove: (from, to) => moved = (from, to),
              onRemove: (index) => removed = index,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2 columns · widths are relative'), findsOneWidget);
    expect(find.byType(TableColumnCard), findsNWidgets(2));
    expect(find.text('Width weight'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('table-add-column-button')));
    expect(addCount, 1);

    await tester.tap(find.byKey(const ValueKey('table-column-move-down-0')));
    expect(moved, (0, 1));

    await tester.tap(find.byKey(const ValueKey('table-column-remove-1')));
    expect(removed, 1);
  });

  testWidgets('renders an explicit empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DesignerTheme.light(),
        home: const Scaffold(
          body: TableColumnEditor(columns: []),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('table-columns-empty-state')),
        findsOneWidget);
    expect(find.text('No columns configured'), findsOneWidget);
  });
}
