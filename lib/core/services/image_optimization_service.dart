import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageOptimizationService {
  static const int _maxImageSize =
      400; // Max width/height in pixels (reduced from 512)
  static const int _jpegQuality =
      70; // JPEG compression quality (reduced from 85)
  static const int _maxDataUrlLength =
      40000; // Max data URL length in chars (reduced from 50000)

  /// Optimizes an image data URL by compressing and resizing
  /// Returns null if the input is not a valid data URL
  static String? optimizeDataUrl(String? dataUrl) {
    if (dataUrl == null || !dataUrl.startsWith('data:image/')) {
      return dataUrl; // Return as-is for regular URLs
    }

    try {
      // If already small enough, return as-is
      if (dataUrl.length <= _maxDataUrlLength) {
        return dataUrl;
      }

      // Extract base64 data
      final parts = dataUrl.split(',');
      if (parts.length != 2) return dataUrl;

      final base64Data = parts[1];
      final imageBytes = base64Decode(base64Data);

      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return dataUrl;

      // Resize if too large
      img.Image resized = image;
      if (image.width > _maxImageSize || image.height > _maxImageSize) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? _maxImageSize : null,
          height: image.height > image.width ? _maxImageSize : null,
        );
      }

      // Compress as JPEG
      final compressedBytes = img.encodeJpg(resized, quality: _jpegQuality);
      final compressedBase64 = base64Encode(compressedBytes);

      // Return optimized data URL
      final optimizedUrl = 'data:image/jpeg;base64,$compressedBase64';

      if (kDebugMode) {
        print(
            '📸 Image optimization: ${dataUrl.length} -> ${optimizedUrl.length} chars '
            '(${((1 - optimizedUrl.length / dataUrl.length) * 100).toStringAsFixed(1)}% reduction)');
      }

      return optimizedUrl;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Image optimization failed: $e');
      }
      return dataUrl; // Return original on error
    }
  }

  /// Optimizes multiple image URLs in parallel
  static Future<Map<String, String?>> optimizeMultipleDataUrls(
    List<String?> dataUrls,
  ) async {
    final results = <String, String?>{};

    await Future.wait(
      dataUrls.where((url) => url != null).map((url) async {
        final optimized = await compute(_optimizeInIsolate, url!);
        results[url] = optimized;
      }),
    );

    return results;
  }

  /// Optimizes a profile picture with more aggressive compression
  /// for smaller file sizes (suitable for avatars)
  static String? optimizeProfilePictureDataUrl(String? dataUrl) {
    if (dataUrl == null || !dataUrl.startsWith('data:image/')) {
      return dataUrl; // Return as-is for regular URLs
    }

    try {
      // Extract base64 data
      final parts = dataUrl.split(',');
      if (parts.length != 2) return dataUrl;

      final base64Data = parts[1];
      final imageBytes = base64Decode(base64Data);

      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return dataUrl;

      // More aggressive resizing for profile pictures (256x256 max)
      const maxProfileSize = 256;
      img.Image resized = image;
      if (image.width > maxProfileSize || image.height > maxProfileSize) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? maxProfileSize : null,
          height: image.height > image.width ? maxProfileSize : null,
        );
      }

      // More aggressive compression for profile pictures (quality 60)
      final compressedBytes = img.encodeJpg(resized, quality: 60);
      final compressedBase64 = base64Encode(compressedBytes);

      // Return optimized data URL
      final optimizedUrl = 'data:image/jpeg;base64,$compressedBase64';

      if (kDebugMode) {
        print(
            '👤 Profile picture optimization: ${dataUrl.length} -> ${optimizedUrl.length} chars '
            '(${((1 - optimizedUrl.length / dataUrl.length) * 100).toStringAsFixed(1)}% reduction)');
      }

      return optimizedUrl;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Profile picture optimization failed: $e');
      }
      return optimizeDataUrl(dataUrl); // Fallback to standard optimization
    }
  }

  /// Runs image optimization in an isolate to prevent blocking the UI
  static String? _optimizeInIsolate(String dataUrl) {
    return optimizeDataUrl(dataUrl);
  }

  /// Estimates if a data URL is likely too large and should be optimized
  static bool shouldOptimize(String? url) {
    if (url == null || !url.startsWith('data:image/')) return false;
    return url.length > _maxDataUrlLength;
  }

  /// Truncates a data URL for logging to prevent console spam
  static String truncateForLog(String? url, {int maxLength = 100}) {
    if (url == null) return 'null';
    if (url.length <= maxLength) return url;

    if (url.startsWith('data:image/')) {
      final headerEnd = url.indexOf(',');
      if (headerEnd > 0) {
        final header = url.substring(0, headerEnd + 1);
        return '$header...[${url.length} chars total]';
      }
    }

    return '${url.substring(0, maxLength)}...[${url.length} chars total]';
  }
}
