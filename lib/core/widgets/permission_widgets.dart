import 'package:flutter/material.dart';
import 'package:talent/core/services/permission_service.dart';

/// Widget that conditionally shows its child based on user permissions
class PermissionGuard extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final Widget child;
  final Widget? fallback;
  final bool Function()? customCheck;

  const PermissionGuard({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    required this.child,
    this.fallback,
    this.customCheck,
  }) : assert(
          (permission != null && permissions == null) ||
              (permission == null && permissions != null) ||
              (customCheck != null),
          'Provide either permission, permissions list, or customCheck',
        );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    bool hasAccess = false;

    if (customCheck != null) {
      hasAccess = customCheck!();
    } else if (permission != null) {
      hasAccess = permissionService.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? permissionService.hasAllPermissions(permissions!)
          : permissionService.hasAnyPermission(permissions!);
    }

    if (hasAccess) {
      return child;
    } else {
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// Widget that conditionally renders different content based on permissions
class ConditionalWidget extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final Widget? granted;
  final Widget? denied;
  final bool Function()? customCheck;

  const ConditionalWidget({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    this.granted,
    this.denied,
    this.customCheck,
  }) : assert(
          (permission != null && permissions == null) ||
              (permission == null && permissions != null) ||
              (customCheck != null),
          'Provide either permission, permissions list, or customCheck',
        );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    bool hasAccess = false;

    if (customCheck != null) {
      hasAccess = customCheck!();
    } else if (permission != null) {
      hasAccess = permissionService.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? permissionService.hasAllPermissions(permissions!)
          : permissionService.hasAnyPermission(permissions!);
    }

    if (hasAccess) {
      return granted ?? const SizedBox.shrink();
    } else {
      return denied ?? const SizedBox.shrink();
    }
  }
}

/// Button that is automatically disabled based on permissions
class PermissionAwareButton extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final String? tooltip;
  final bool Function()? customCheck;

  const PermissionAwareButton({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    required this.onPressed,
    required this.child,
    this.style,
    this.tooltip,
    this.customCheck,
  }) : assert(
          (permission != null && permissions == null) ||
              (permission == null && permissions != null) ||
              (customCheck != null) ||
              (permission == null &&
                  permissions == null &&
                  customCheck == null),
          'Provide either permission, permissions list, customCheck, or none for always enabled',
        );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    bool hasAccess = true;

    if (customCheck != null) {
      hasAccess = customCheck!();
    } else if (permission != null) {
      hasAccess = permissionService.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? permissionService.hasAllPermissions(permissions!)
          : permissionService.hasAnyPermission(permissions!);
    }

    final button = ElevatedButton(
      onPressed: hasAccess ? onPressed : null,
      style: style,
      child: child,
    );

    if (tooltip != null) {
      return Tooltip(
        message:
            hasAccess ? tooltip! : 'You don\'t have permission for this action',
        child: button,
      );
    }

    return button;
  }
}

/// IconButton that is automatically disabled based on permissions
class PermissionAwareIconButton extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final VoidCallback? onPressed;
  final Icon icon;
  final String? tooltip;
  final bool Function()? customCheck;

  const PermissionAwareIconButton({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.customCheck,
  }) : assert(
          (permission != null && permissions == null) ||
              (permission == null && permissions != null) ||
              (customCheck != null) ||
              (permission == null &&
                  permissions == null &&
                  customCheck == null),
          'Provide either permission, permissions list, customCheck, or none for always enabled',
        );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    bool hasAccess = true;

    if (customCheck != null) {
      hasAccess = customCheck!();
    } else if (permission != null) {
      hasAccess = permissionService.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? permissionService.hasAllPermissions(permissions!)
          : permissionService.hasAnyPermission(permissions!);
    }

    return IconButton(
      onPressed: hasAccess ? onPressed : null,
      icon: icon,
      tooltip:
          hasAccess ? tooltip : 'You don\'t have permission for this action',
    );
  }
}

/// FloatingActionButton that is conditionally shown based on permissions
class PermissionAwareFAB extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;
  final bool Function()? customCheck;

  const PermissionAwareFAB({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.customCheck,
  }) : assert(
          (permission != null && permissions == null) ||
              (permission == null && permissions != null) ||
              (customCheck != null),
          'Provide either permission, permissions list, or customCheck',
        );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    bool hasAccess = false;

    if (customCheck != null) {
      hasAccess = customCheck!();
    } else if (permission != null) {
      hasAccess = permissionService.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? permissionService.hasAllPermissions(permissions!)
          : permissionService.hasAnyPermission(permissions!);
    }

    if (!hasAccess) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      tooltip: tooltip,
      child: child,
    );
  }
}

/// Menu item that is conditionally shown based on permissions
class PermissionAwareMenuItem extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final VoidCallback? onTap;
  final Widget child;
  final bool Function()? customCheck;

  const PermissionAwareMenuItem({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    this.onTap,
    required this.child,
    this.customCheck,
  }) : assert(
          (permission != null && permissions == null) ||
              (permission == null && permissions != null) ||
              (customCheck != null),
          'Provide either permission, permissions list, or customCheck',
        );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    bool hasAccess = false;

    if (customCheck != null) {
      hasAccess = customCheck!();
    } else if (permission != null) {
      hasAccess = permissionService.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? permissionService.hasAllPermissions(permissions!)
          : permissionService.hasAnyPermission(permissions!);
    }

    if (!hasAccess) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      child: child,
    );
  }
}

/// PopupMenuItem that is conditionally shown based on permissions
class PermissionAwarePopupMenuItem<T> extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool requireAll;
  final T value;
  final Widget child;
  final bool Function()? customCheck;

  const PermissionAwarePopupMenuItem({
    super.key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    required this.value,
    required this.child,
    this.customCheck,
  }) : assert(
          (permission != null && permissions == null) ||
              (permission == null && permissions != null) ||
              (customCheck != null),
          'Provide either permission, permissions list, or customCheck',
        );

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService(context: context);
    bool hasAccess = false;

    if (customCheck != null) {
      hasAccess = customCheck!();
    } else if (permission != null) {
      hasAccess = permissionService.hasPermission(permission!);
    } else if (permissions != null) {
      hasAccess = requireAll
          ? permissionService.hasAllPermissions(permissions!)
          : permissionService.hasAnyPermission(permissions!);
    }

    if (!hasAccess) return const SizedBox.shrink();

    return PopupMenuItem<T>(
      value: value,
      child: child,
    );
  }
}

/// Helper function to check permissions outside of widgets
bool checkPermission(BuildContext context, String permission) {
  final permissionService = PermissionService(context: context);
  return permissionService.hasPermission(permission);
}

/// Helper function to check multiple permissions outside of widgets
bool checkPermissions(
  BuildContext context,
  List<String> permissions, {
  bool requireAll = false,
}) {
  final permissionService = PermissionService(context: context);
  return requireAll
      ? permissionService.hasAllPermissions(permissions)
      : permissionService.hasAnyPermission(permissions);
}
