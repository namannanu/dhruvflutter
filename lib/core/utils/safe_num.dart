import 'dart:math' as math;

/// Utility class to safely handle numeric values and prevent NaN/Infinity from reaching UI components
class SafeNum {
  SafeNum._();

  /// Safely converts a value to double, ensuring no NaN or Infinity values
  static double toSafeDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;

    double result;
    if (value is double) {
      result = value;
    } else if (value is int) {
      result = value.toDouble();
    } else if (value is num) {
      result = value.toDouble();
    } else if (value is String) {
      result = double.tryParse(value) ?? fallback;
    } else {
      return fallback;
    }

    // Check for NaN, Infinity, or negative infinity
    if (result.isNaN || result.isInfinite) {
      return fallback;
    }

    return result;
  }

  /// Safely converts a value to int, ensuring no NaN or Infinity values
  static int toSafeInt(dynamic value, {int fallback = 0}) {
    final doubleValue = toSafeDouble(value, fallback: fallback.toDouble());
    return doubleValue.round();
  }

  /// Clamps a double value between min and max, ensuring no NaN/Infinity
  static double clampSafe(double value, double min, double max,
      {double fallback = 0.0}) {
    final safeValue = toSafeDouble(value, fallback: fallback);
    return math.max(min, math.min(max, safeValue));
  }

  /// Safely performs division to prevent division by zero resulting in NaN/Infinity
  static double safeDivide(double numerator, double denominator,
      {double fallback = 0.0}) {
    final safeNumerator = toSafeDouble(numerator, fallback: fallback);
    final safeDenominator = toSafeDouble(denominator, fallback: 1.0);

    if (safeDenominator == 0.0) {
      return fallback;
    }

    final result = safeNumerator / safeDenominator;
    return toSafeDouble(result, fallback: fallback);
  }

  /// Safely calculates percentage, preventing NaN from division by zero
  static double safePercentage(double value, double total,
      {double fallback = 0.0}) {
    return safeDivide(value * 100, total, fallback: fallback);
  }
}

/// Extension methods for safer numeric operations
extension SafeNumExtension on num? {
  /// Safely converts to double with fallback
  double toSafeDouble([double fallback = 0.0]) {
    return SafeNum.toSafeDouble(this, fallback: fallback);
  }

  /// Safely converts to int with fallback
  int toSafeInt([int fallback = 0]) {
    return SafeNum.toSafeInt(this, fallback: fallback);
  }
}

extension SafeStringNumExtension on String? {
  /// Safely parses string to double with fallback
  double toSafeDouble([double fallback = 0.0]) {
    return SafeNum.toSafeDouble(this, fallback: fallback);
  }

  /// Safely parses string to int with fallback
  int toSafeInt([int fallback = 0]) {
    return SafeNum.toSafeInt(this, fallback: fallback);
  }
}
