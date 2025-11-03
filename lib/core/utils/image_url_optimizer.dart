import 'package:flutter/foundation.dart';

enum ImageContext {
  jobList,
  jobDetail,
  employerAvatar,
  workerAvatar,
  employerProfile,
  workerProfile,
  companyLogoSmall,
  companyLogoLarge,
  portfolioThumbnail,
  portfolioPreview,
  notification
}

class ImageUrlOptimizer {
  static const Map<ImageContext, _ImageConfig> _configurations = {
    ImageContext.jobList: _ImageConfig(width: 50, height: 50, quality: 70),
    ImageContext.jobDetail: _ImageConfig(width: 100, height: 100, quality: 75),
    ImageContext.employerAvatar:
        _ImageConfig(width: 60, height: 60, quality: 75),
    ImageContext.workerAvatar: _ImageConfig(width: 60, height: 60, quality: 75),
    ImageContext.employerProfile:
        _ImageConfig(width: 120, height: 120, quality: 80),
    ImageContext.workerProfile:
        _ImageConfig(width: 120, height: 120, quality: 80),
    ImageContext.companyLogoSmall:
        _ImageConfig(width: 80, height: 80, quality: 70),
    ImageContext.companyLogoLarge:
        _ImageConfig(width: 200, height: 200, quality: 85),
    ImageContext.portfolioThumbnail:
        _ImageConfig(width: 150, height: 150, quality: 75),
    ImageContext.portfolioPreview:
        _ImageConfig(width: 300, height: 300, quality: 80),
    ImageContext.notification: _ImageConfig(width: 24, height: 24, quality: 60),
  };

  static String? optimizeUrl(String? originalUrl, ImageContext context) {
    if (originalUrl == null || originalUrl.isEmpty) return null;

    final config = _configurations[context]!;

    try {
      final uri = Uri.parse(originalUrl);

      // Handle different image hosting services
      if (originalUrl.contains('cloudinary.com')) {
        return _optimizeCloudinaryUrl(uri, config);
      } else if (originalUrl.contains('amazonaws.com')) {
        return _optimizeS3Url(uri, config);
      } else if (originalUrl.contains('firebasestorage.googleapis.com')) {
        return _optimizeFirebaseUrl(uri, config);
      } else {
        // Generic URL optimization (if supported by your backend)
        return _optimizeGenericUrl(uri, config);
      }
    } catch (e) {
      debugPrint('Error optimizing image URL: \$e');
      return originalUrl;
    }
  }

  static String _optimizeCloudinaryUrl(Uri uri, _ImageConfig config) {
    final pathSegments = uri.pathSegments.toList();
    final uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex != -1) {
      pathSegments.insert(uploadIndex + 1,
          'w_\${config.width},h_\${config.height},q_\${config.quality},f_webp,c_fill');
    }
    return uri.replace(pathSegments: pathSegments).toString();
  }

  static String _optimizeS3Url(Uri uri, _ImageConfig config) {
    final queryParams = Map<String, String>.from(uri.queryParameters)
      ..addAll({
        'w': config.width.toString(),
        'h': config.height.toString(),
        'q': config.quality.toString(),
      });
    return uri.replace(queryParameters: queryParams).toString();
  }

  static String _optimizeFirebaseUrl(Uri uri, _ImageConfig config) {
    // Firebase Storage doesn't support direct image manipulation
    // You might need to implement this through a Cloud Function or your backend
    return uri.toString();
  }

  static String _optimizeGenericUrl(Uri uri, _ImageConfig config) {
    final queryParams = Map<String, String>.from(uri.queryParameters)
      ..addAll({
        'width': config.width.toString(),
        'height': config.height.toString(),
        'quality': config.quality.toString(),
        'format': 'webp',
      });
    return uri.replace(queryParameters: queryParams).toString();
  }
}

class _ImageConfig {
  final int width;
  final int height;
  final int quality;

  const _ImageConfig({
    required this.width,
    required this.height,
    required this.quality,
  });
}
