import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  const resolver = ReportValueResolver();
  const data = <String, dynamic>{
    'shop': {'name': 'Dexter Coffee'},
    'total': 215,
  };

  test('resolves nested template expression', () {
    expect(resolver.resolve('{{shop.name}}', data), 'Dexter Coffee');
  });

  test('resolves plain nested path', () {
    expect(resolver.resolve('shop.name', data), 'Dexter Coffee');
  });

  test('returns empty string for missing path', () {
    expect(resolver.resolve('{{shop.missing}}', data), '');
  });
}
