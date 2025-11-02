// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:hive/hive.dart';

class CacheEntry {
  CacheEntry(this.data, this.savedAtMillis, {this.ttlMillis});
  final String data; // JSON string
  final int savedAtMillis;
  final int? ttlMillis;

  bool get isExpired {
    if (ttlMillis == null) return false;
    return DateTime.now().millisecondsSinceEpoch - savedAtMillis > ttlMillis!;
  }

  Map<String, dynamic> toMap() => {
        'data': data,
        'savedAt': savedAtMillis,
        'ttl': ttlMillis,
      };

  static CacheEntry fromMap(Map map) => CacheEntry(
        map['data'] as String,
        (map['savedAt'] as num).toInt(),
        ttlMillis: (map['ttl'] as num?)?.toInt(),
      );
}

class CacheService {
  CacheService._(this._box);
  final Box _box;

  static Future<CacheService> open(String boxName) async {
    final box = await Hive.openBox(boxName);
    return CacheService._(box);
  }

  Future<void> putJson(String key, Object value, {Duration? ttl}) async {
    final entry = CacheEntry(
      jsonEncode(value),
      DateTime.now().millisecondsSinceEpoch,
      ttlMillis: ttl?.inMilliseconds,
    );
    await _box.put(key, entry.toMap());
  }

  /// Returns decoded JSON (Map/List) or null if not present/expired.
  T? getJson<T>(String key) {
    final raw = _box.get(key);
    if (raw is! Map) return null;
    final entry = CacheEntry.fromMap(raw.cast());
    if (entry.isExpired) return null;
    final decoded = jsonDecode(entry.data);
    return decoded as T;
  }

  Future<void> remove(String key) => _box.delete(key);
  Future<void> clear() => _box.clear();
}
