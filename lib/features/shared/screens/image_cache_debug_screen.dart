import 'package:flutter/material.dart';
import '../../../core/services/image_cache_service.dart';

class ImageCacheDebugScreen extends StatefulWidget {
  const ImageCacheDebugScreen({super.key});

  @override
  State<ImageCacheDebugScreen> createState() => _ImageCacheDebugScreenState();
}

class _ImageCacheDebugScreenState extends State<ImageCacheDebugScreen> {
  final ImageCacheService _cacheService = ImageCacheService();
  Map<String, dynamic> _cacheStats = {};

  @override
  void initState() {
    super.initState();
    _updateStats();
  }

  void _updateStats() {
    setState(() {
      _cacheStats = _cacheService.getCacheStats();
    });
  }

  void _clearCache() {
    _cacheService.clearCache();
    _updateStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image cache cleared successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Cache Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateStats,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cache Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                        'Cached Images', '${_cacheStats['cachedImages'] ?? 0}'),
                    _buildStatRow('Loading Images',
                        '${_cacheStats['loadingImages'] ?? 0}'),
                    _buildStatRow('Max Cache Size',
                        '${_cacheStats['maxCacheSize'] ?? 0}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_cacheStats['cacheUrls'] != null &&
                (_cacheStats['cacheUrls'] as List).isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Cached URLs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_cacheStats['cacheUrls'] as List).map(
                        (url) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            url.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _clearCache,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Cache'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
