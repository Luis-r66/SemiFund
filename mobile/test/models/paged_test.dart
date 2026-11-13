import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/paged.dart';

void main() {
  test('lee el sobre paginado del API', () {
    final Paged<int> page = Paged<int>.fromJson(<String, dynamic>{
      'items': <int>[1, 2],
      'total': 45,
      'page': 2,
      'limit': 20,
      'pages': 3,
    }, (dynamic item) => item as int);

    expect(page.items, <int>[1, 2]);
    expect(page.total, 45);
    expect(page.page, 2);
    expect(page.pages, 3);
    expect(page.hasMore, isTrue);
  });

  test('normaliza valores ausentes para no romper la UI', () {
    final Paged<int> page = Paged<int>.fromJson(
      <String, dynamic>{},
      (dynamic item) => item as int,
    );

    expect(page.items, isEmpty);
    expect(page.total, 0);
    expect(page.page, 1);
    expect(page.limit, 20);
    expect(page.pages, 1);
    expect(page.hasMore, isFalse);
  });
}
