import 'package:flutter/foundation.dart';

class CacheService {
  static final _cache = <String, _CacheEntry>{};
  static const _defaultDuration = Duration(minutes: 5);
  
  // Get cached value
  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check if expired
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T?;
  }
  
  // Set cached value
  static void set(String key, dynamic value, {Duration? duration}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(duration ?? _defaultDuration),
    );
  }
  
  // Clear specific key
  static void clear(String key) {
    _cache.remove(key);
  }
  
  // Clear all cache
  static void clearAll() {
    _cache.clear();
  }
  
  // Clear expired entries
  static void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiry));
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiry;
  
  _CacheEntry({required this.value, required this.expiry});
}
