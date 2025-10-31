import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A simple in-memory cache for business logo images
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Cache map: URL -> cached image data
  final Map<String, Uint8List> _cache = {};
  
  // Loading state map: URL -> Future to prevent duplicate requests
  final Map<String, Future<Uint8List?>> _loadingFutures = {};
  
  // Maximum cache size (number of images)
  static const int _maxCacheSize = 100;
  
  // Maximum age for cached images (24 hours)
  static const Duration _maxAge = Duration(hours: 24);
  
  // Cache timestamps to implement expiry
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Get cached image data for a URL
  Uint8List? getCachedImage(String url) {
    final cleanUrl = url.trim();
    
    // Check if image is cached and not expired
    if (_cache.containsKey(cleanUrl)) {
      final timestamp = _cacheTimestamps[cleanUrl];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _maxAge) {
        debugPrint('📸 ImageCache: Cache HIT for $cleanUrl');
        return _cache[cleanUrl];
      } else {
        // Remove expired entry
        _removeFromCache(cleanUrl);
        debugPrint('📸 ImageCache: Cache EXPIRED for $cleanUrl');
      }
    }
    
    debugPrint('📸 ImageCache: Cache MISS for $cleanUrl');
    return null;
  }

  /// Load and cache image from URL
  Future<Uint8List?> loadAndCacheImage(String url) async {
    final cleanUrl = url.trim();
    
    // Check if already cached
    final cached = getCachedImage(cleanUrl);
    if (cached != null) {
      return cached;
    }
    
    // Check if already loading
    if (_loadingFutures.containsKey(cleanUrl)) {
      debugPrint('📸 ImageCache: Already loading $cleanUrl');
      return await _loadingFutures[cleanUrl];
    }
    
    // Start loading
    final loadingFuture = _downloadImage(cleanUrl);
    _loadingFutures[cleanUrl] = loadingFuture;
    
    try {
      final imageData = await loadingFuture;
      if (imageData != null) {
        _addToCache(cleanUrl, imageData);
        debugPrint('📸 ImageCache: Cached new image for $cleanUrl (${imageData.length} bytes)');
      }
      return imageData;
    } finally {
      await _loadingFutures.remove(cleanUrl);
    }
  }

  /// Download image from URL
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      debugPrint('📸 ImageCache: Downloading $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Talent App/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          return response.bodyBytes;
        } else {
          debugPrint('📸 ImageCache: Invalid content type: $contentType');
          return null;
        }
      } else {
        debugPrint('📸 ImageCache: HTTP ${response.statusCode} for $url');
        return null;
      }
    } catch (e) {
      debugPrint('📸 ImageCache: Error downloading $url: $e');
      return null;
    }
  }

  /// Add image to cache with LRU eviction
  void _addToCache(String url, Uint8List imageData) {
    // Remove oldest entries if cache is full
    while (_cache.length >= _maxCacheSize) {
      final oldestEntry = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b);
      _removeFromCache(oldestEntry.key);
      debugPrint('📸 ImageCache: Evicted old entry ${oldestEntry.key}');
    }
    
    _cache[url] = imageData;
    _cacheTimestamps[url] = DateTime.now();
  }

  /// Remove entry from cache
  void _removeFromCache(String url) {
    _cache.remove(url);
    _cacheTimestamps.remove(url);
  }

  /// Clear all cached images
  void clearCache() {
    final count = _cache.length;
    _cache.clear();
    _cacheTimestamps.clear();
    _loadingFutures.clear();
    debugPrint('📸 ImageCache: Cleared $count cached images');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedImages': _cache.length,
      'loadingImages': _loadingFutures.length,
      'maxCacheSize': _maxCacheSize,
      'cacheUrls': _cache.keys.take(5).toList(), // First 5 URLs for debugging
    };
  }
}