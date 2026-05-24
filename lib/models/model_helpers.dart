DateTime? dateFromValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final dynamic timestamp = value;
  return timestamp.toDate() as DateTime?;
}

String stringFromValue(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}

String? nullableStringFromValue(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int intFromValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool boolFromValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

List<String> stringListFromValue(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

Map<String, int> intMapFromValue(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) {
    return MapEntry(key.toString(), intFromValue(item));
  });
}

Map<String, dynamic> cleanMap(Map<String, dynamic> map) {
  return Map.fromEntries(map.entries.where((entry) => entry.value != null));
}
