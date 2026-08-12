import 'package:flutter_test/flutter_test.dart';
import 'package:report_engine/report_engine.dart';

void main() {
  const resolver = ReportValueResolver();
  const data = <String, dynamic>{
    'shop': {
      'name': 'Dexter Coffee',
      'address': {
        'city': 'Chiang Mai',
      },
    },
    'items': [
      {'name': 'Latte', 'qty': 2},
      {'name': 'Croissant', 'qty': 1},
    ],
    'total': 215,
    'paid': true,
    'note': null,
  };

  test('resolves nested template expression', () {
    expect(resolver.resolve('{{shop.name}}', data), 'Dexter Coffee');
  });

  test('resolves plain nested path', () {
    expect(resolver.resolve('shop.name', data), 'Dexter Coffee');
  });

  test('resolves list index path', () {
    expect(resolver.resolve('{{items.0.name}}', data), 'Latte');
    expect(resolver.resolve('{{items.1.qty}}', data), 1);
  });

  test('resolves deeper nested path', () {
    expect(resolver.resolve('{{shop.address.city}}', data), 'Chiang Mai');
  });

  test('returns empty string for missing path', () {
    expect(resolver.resolve('{{shop.missing}}', data), '');
  });

  test('returns empty string for null value', () {
    expect(resolver.resolve('{{note}}', data), '');
  });

  test('returns empty string for invalid list index', () {
    expect(resolver.resolve('{{items.bad.name}}', data), '');
    expect(resolver.resolve('{{items.-1.name}}', data), '');
    expect(resolver.resolve('{{items.99.name}}', data), '');
  });

  test('preserves numeric and boolean values', () {
    expect(resolver.resolve('{{total}}', data), 215);
    expect(resolver.resolve('{{paid}}', data), isTrue);
  });

  test('resolveText stringifies resolved values', () {
    expect(resolver.resolveText('{{total}}', data), '215');
    expect(resolver.resolveText('{{paid}}', data), 'true');
  });
}
