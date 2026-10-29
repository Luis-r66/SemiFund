Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic val) => MapEntry(key.toString(), val),
    );
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

String asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final String text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? asNullableString(dynamic value) {
  if (value == null) return null;
  final String text = value.toString();
  return text.isEmpty ? null : text;
}

double asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final String normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

DateTime? asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
