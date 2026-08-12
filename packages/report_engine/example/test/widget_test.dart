import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine_example/main.dart';

void main() {
  testWidgets('renders report engine example actions', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('report_engine Example'), findsOneWidget);
    expect(find.text('Thermal 80 mm receipt'), findsOneWidget);
    expect(find.text('Thermal 58 mm receipt'), findsOneWidget);
    expect(find.text('A4 invoice'), findsOneWidget);
  });
}
