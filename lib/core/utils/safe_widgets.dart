import 'package:flutter/material.dart';
import 'safe_num.dart';

/// Safe wrappers for Flutter widgets that prevent NaN values from reaching CoreGraphics
class SafeWidgets {
  SafeWidgets._();

  /// Safe Container that ensures width and height are never NaN or Infinity
  static Widget safeContainer({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Widget? child,
    Clip clipBehavior = Clip.none,
  }) {
    return Container(
      key: key,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width != null ? SafeNum.toSafeDouble(width) : null,
      height: height != null ? SafeNum.toSafeDouble(height) : null,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Safe SizedBox that ensures width and height are never NaN or Infinity
  static Widget safeSizedBox({
    Key? key,
    double? width,
    double? height,
    Widget? child,
  }) {
    return SizedBox(
      key: key,
      width: width != null ? SafeNum.toSafeDouble(width) : null,
      height: height != null ? SafeNum.toSafeDouble(height) : null,
      child: child,
    );
  }

  /// Safe Positioned widget for Stack children
  static Widget safePositioned({
    Key? key,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
    required Widget child,
  }) {
    return Positioned(
      key: key,
      left: left != null ? SafeNum.toSafeDouble(left) : null,
      top: top != null ? SafeNum.toSafeDouble(top) : null,
      right: right != null ? SafeNum.toSafeDouble(right) : null,
      bottom: bottom != null ? SafeNum.toSafeDouble(bottom) : null,
      width: width != null ? SafeNum.toSafeDouble(width) : null,
      height: height != null ? SafeNum.toSafeDouble(height) : null,
      child: child,
    );
  }

  /// Safe Padding widget
  static Widget safePadding({
    Key? key,
    required EdgeInsetsGeometry padding,
    Widget? child,
  }) {
    // EdgeInsets can also contain NaN values, so we need to validate them
    if (padding is EdgeInsets) {
      final safePadding = EdgeInsets.only(
        left: SafeNum.toSafeDouble(padding.left),
        top: SafeNum.toSafeDouble(padding.top),
        right: SafeNum.toSafeDouble(padding.right),
        bottom: SafeNum.toSafeDouble(padding.bottom),
      );
      return Padding(
        key: key,
        padding: safePadding,
        child: child,
      );
    }
    return Padding(
      key: key,
      padding: padding,
      child: child,
    );
  }
}
