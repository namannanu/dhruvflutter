// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/business_access_context.dart';

/// Small tag widget to show when user is managing data "on behalf of" someone else
class AccessTag extends StatelessWidget {
  const AccessTag({
    super.key,
    required this.accessInfo,
    this.size = AccessTagSize.small,
  });

  final BusinessAccessInfo accessInfo;
  final AccessTagSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = size == AccessTagSize.small;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6.0 : 8.0,
        vertical: isSmall ? 2.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(isSmall ? 8.0 : 12.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business_center_outlined,
            size: isSmall ? 10.0 : 12.0,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: isSmall ? 3.0 : 4.0),
          Text(
            accessInfo.displayText,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: isSmall ? 9.0 : 10.0,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Positioned wrapper to place AccessTag at top-right of a container
class AccessTagPositioned extends StatelessWidget {
  const AccessTagPositioned({
    super.key,
    required this.accessInfo,
    required this.child,
    this.top = 8.0,
    this.right = 8.0,
    this.size = AccessTagSize.small,
  });

  final BusinessAccessInfo? accessInfo;
  final Widget child;
  final double top;
  final double right;
  final AccessTagSize size;

  @override
  Widget build(BuildContext context) {
    if (accessInfo == null) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top,
          right: right,
          child: AccessTag(
            accessInfo: accessInfo!,
            size: size,
          ),
        ),
      ],
    );
  }
}

enum AccessTagSize { small, medium }

/// Utility function to get access context info for UI
class AccessTagHelper {
  static BusinessAccessInfo? getAccessInfo({
    required BuildContext context,
    String? employerEmail,
    String? employerName,
    String? businessName,
  }) {
    // This would typically get from providers, but for now return null
    // In real implementation, you would:
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    // return BusinessAccessContext().getAccessContext(...)

    return null; // Placeholder for now
  }
}
