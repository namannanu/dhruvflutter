/// Global NaN and Infinity guards to prevent CoreGraphics runtime warnings.
///
/// These utilities ensure no invalid numeric values reach Flutter's rendering engine,
/// which would cause iOS CoreGraphics to log "Invalid numeric value (NaN)" warnings.
// ignore_for_file: deprecated_member_use

library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

class NaNGuard {
  /// Sanitize any numeric value to ensure it's safe for UI rendering
  static double sanitizeDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;

    double result;
    if (value is double) {
      result = value;
    } else if (value is int) {
      result = value.toDouble();
    } else if (value is String) {
      result = double.tryParse(value) ?? fallback;
    } else {
      return fallback;
    }

    // Check for NaN, Infinity, or unreasonable values
    if (result.isNaN || result.isInfinite) {
      return fallback;
    }

    // Clamp extremely large values that could cause rendering issues
    if (result.abs() > 1e6) {
      return fallback;
    }

    return result;
  }

  /// Sanitize integer values
  static int sanitizeInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;

    if (value is int) {
      return value;
    } else if (value is double) {
      if (value.isNaN || value.isInfinite) return fallback;
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  /// Safe division to prevent NaN/Infinity
  static double safeDivide(double numerator, double denominator,
      {double fallback = 0.0}) {
    if (denominator == 0.0 || denominator.isNaN || denominator.isInfinite) {
      return fallback;
    }

    if (numerator.isNaN || numerator.isInfinite) {
      return fallback;
    }

    final result = numerator / denominator;
    return sanitizeDouble(result, fallback: fallback);
  }

  /// Safe percentage calculation
  static double safePercentage(double value, double total,
      {double fallback = 0.0}) {
    if (total == 0.0 || total.isNaN || total.isInfinite) {
      return fallback;
    }

    return safeDivide(value * 100, total, fallback: fallback);
  }

  /// Safe square root
  static double safeSqrt(double value, {double fallback = 0.0}) {
    if (value < 0.0 || value.isNaN || value.isInfinite) {
      return fallback;
    }

    return math.sqrt(value);
  }

  /// Safe logarithm
  static double safeLog(double value, {double fallback = 0.0}) {
    if (value <= 0.0 || value.isNaN || value.isInfinite) {
      return fallback;
    }

    return math.log(value);
  }
}

/// Extensions to make safe operations more convenient
extension SafeDouble on double {
  /// Check if this double is safe for UI rendering
  bool get isSafeForUI => isFinite && !isNaN && abs() < 1e6;

  /// Get a safe version of this double for UI rendering
  double get safeForUI => isSafeForUI ? this : 0.0;

  /// Safe division
  double safeDivideBy(double divisor, {double fallback = 0.0}) {
    return NaNGuard.safeDivide(this, divisor, fallback: fallback);
  }
}

extension SafeNum on num {
  /// Convert any num to a safe double
  double get safeDouble => NaNGuard.sanitizeDouble(this);

  /// Convert any num to a safe int
  int get safeInt => NaNGuard.sanitizeInt(this);
}

/// Safe widget wrappers that prevent NaN values from reaching Flutter widgets
class SafeContainer extends StatelessWidget {
  const SafeContainer({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.child,
    this.clipBehavior = Clip.none,
  });

  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Widget? child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width?.safeForUI,
      height: height?.safeForUI,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

class SafeSizedBox extends StatelessWidget {
  const SafeSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  final double? width;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width?.safeForUI,
      height: height?.safeForUI,
      child: child,
    );
  }
}

class SafePositioned extends StatelessWidget {
  const SafePositioned({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left?.safeForUI,
      top: top?.safeForUI,
      right: right?.safeForUI,
      bottom: bottom?.safeForUI,
      width: width?.safeForUI,
      height: height?.safeForUI,
      child: child,
    );
  }
}

class SafePadding extends StatelessWidget {
  const SafePadding({
    super.key,
    required this.padding,
    this.child,
  });

  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Extract values and sanitize them
    if (padding is EdgeInsets) {
      final p = padding as EdgeInsets;
      return Padding(
        padding: EdgeInsets.only(
          left: p.left.safeForUI,
          top: p.top.safeForUI,
          right: p.right.safeForUI,
          bottom: p.bottom.safeForUI,
        ),
        child: child,
      );
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Global error widget builder that handles NaN-related errors gracefully
class SafeErrorWidget extends StatelessWidget {
  const SafeErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            'Rendering Error',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            error.toString(),
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 10,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Initialize global NaN guards and error handling
void initializeNaNGuards() {
  // Override Flutter's error widget builder
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Log the error for debugging
    debugPrint('🚨 Flutter Error: ${details.exception}');
    if (details.stack != null) {
      debugPrint('Stack trace: ${details.stack}');
    }

    // Return a safe error widget that won't cause further rendering issues
    return SafeErrorWidget(
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Log that NaN guards are active
  debugPrint(
      '✅ NaN Guards initialized - CoreGraphics warnings should be reduced');
}
