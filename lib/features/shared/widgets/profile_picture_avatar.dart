import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:talent/core/utils/image_url_optimizer.dart';
import 'cached_network_image_widget.dart';

class ProfilePictureAvatar extends StatelessWidget {
  const ProfilePictureAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    this.size = 44,
    this.imageContext = ImageContext.workerAvatar,
  });

  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final double size;
  final ImageContext imageContext;

  @override
  Widget build(BuildContext context) {
    final fallbackInitials = _resolveInitials(firstName, lastName);
    final radius = size / 2;

    if (profilePictureUrl != null && profilePictureUrl!.trim().isNotEmpty) {
      final trimmed = profilePictureUrl!.trim();
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
                _fallbackAvatar(radius, fallbackInitials),
          ),
        );
      }

      // Optimize URL based on the context
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
              _fallbackAvatar(radius, fallbackInitials),
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

    return _fallbackAvatar(radius, fallbackInitials);
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

  static String _resolveInitials(String firstName, String lastName) {
    final firstInitial = firstName.trim().isNotEmpty
        ? firstName.trim().substring(0, 1).toUpperCase()
        : '';
    final lastInitial = lastName.trim().isNotEmpty
        ? lastName.trim().substring(0, 1).toUpperCase()
        : '';

    if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
      return firstInitial + lastInitial;
    } else if (firstInitial.isNotEmpty) {
      return firstInitial;
    } else if (lastInitial.isNotEmpty) {
      return lastInitial;
    } else {
      return '?';
    }
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
