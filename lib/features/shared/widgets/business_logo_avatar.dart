import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:talent/core/utils/image_url_optimizer.dart';
import 'cached_network_image_widget.dart';

class BusinessLogoAvatar extends StatelessWidget {
  const BusinessLogoAvatar({
    super.key,
    required this.name,
    this.logoUrl,
    this.size = 44,
    this.imageContext = ImageContext.jobList,
  });

  final String name;
  final String? logoUrl;
  final double size;
  final ImageContext imageContext;

  @override
  Widget build(BuildContext context) {
    final fallbackInitial = _resolveInitial(name);
    final radius = size / 2;

    if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
      final trimmed = logoUrl!.trim();
      final memoryImage = _tryDecodeDataUri(trimmed);
      if (memoryImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            memoryImage,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _fallbackAvatar(radius, fallbackInitial),
          ),
        );
      }

      // Optimize the URL based on the context
      final optimizedUrl =
          ImageUrlOptimizer.optimizeUrl(trimmed, imageContext) ?? trimmed;

      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImageWidget(
          imageUrl: optimizedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _fallbackAvatar(radius, fallbackInitial),
          placeholder: Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    }

    return _fallbackAvatar(radius, fallbackInitial);
  }

  static Widget _fallbackAvatar(double radius, String text) {
    return CircleAvatar(
      radius: radius,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  static String _resolveInitial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final firstRune = trimmed.runes.first;
    return String.fromCharCode(firstRune).toUpperCase();
  }

  static Uint8List? _tryDecodeDataUri(String value) {
    if (!value.startsWith('data:image')) {
      return null;
    }

    final commaIndex = value.indexOf(',');
    if (commaIndex == -1 || commaIndex >= value.length - 1) {
      return null;
    }

    final dataPart = value.substring(commaIndex + 1);
    try {
      return base64Decode(dataPart);
    } catch (_) {
      return null;
    }
  }
}
