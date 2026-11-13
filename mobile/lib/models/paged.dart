import '../core/utils/json_utils.dart';

/// Respuesta paginada del API: `{ items, total, page, limit, pages }`.
class Paged<T> {
  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  bool get hasMore => page < pages;

  factory Paged.fromJson(dynamic json, T Function(dynamic item) parse) {
    final Map<String, dynamic> map = asMap(json);
    final int page = asInt(map['page']);
    final int limit = asInt(map['limit']);
    final int pages = asInt(map['pages']);
    return Paged<T>(
      items: asList(map['items']).map(parse).toList(),
      total: asInt(map['total']),
      page: page < 1 ? 1 : page,
      limit: limit < 1 ? 20 : limit,
      pages: pages < 1 ? 1 : pages,
    );
  }
}
