import 'dart:convert';

/// Lightweight helper to decode JWT payloads without external dependencies.
class JwtPayload {
  JwtPayload(this.claims);

  /// Raw claims decoded from the JWT payload.
  final Map<String, dynamic> claims;

  /// Safe accessor using bracket notation.
  dynamic operator [](String key) => claims[key];

  /// Attempt to parse a JWT token string.
  /// Returns null if the token is invalid or cannot be decoded.
  static JwtPayload? tryParse(String? token) {
    if (token == null || token.trim().isEmpty) return null;

    final segments = token.split('.');
    if (segments.length < 2) return null;

    try {
      final payloadSegment = segments[1];
      final normalized = _normalizeBase64(payloadSegment);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return JwtPayload(json);
      }
    } catch (_) {
      // ignore decoding errors
    }
    return null;
  }

  /// Convenience accessor that coerces the claim into a string, if possible.
  String? stringClaim(String key) {
    final value = claims[key];
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }

  /// Convenience accessor that returns a nested Map claim, if available.
  Map<String, dynamic>? mapClaim(String key) {
    final value = claims[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  static String _normalizeBase64(String input) {
    final normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    final padding = normalized.length % 4;
    if (padding == 0) return normalized;
    return normalized.padRight(normalized.length + (4 - padding), '=');
  }
}
