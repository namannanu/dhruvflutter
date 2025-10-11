import 'package:flutter/material.dart';

/// A reusable notification badge widget that displays an unread count indicator
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int? unreadCount;
  final Color badgeColor;
  final Color textColor;
  final double badgeSize;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    this.unreadCount,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.badgeSize = 16.0,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = unreadCount ?? 0;
    final shouldShowBadge = showZero ? count >= 0 : count > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (shouldShowBadge)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: badgeSize * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Notification icon with badge for use in navigation bars
class NotificationIconWithBadge extends StatelessWidget {
  final int? unreadCount;
  final VoidCallback? onTap;
  final IconData icon;
  final Color? iconColor;
  final double iconSize;

  const NotificationIconWithBadge({
    super.key,
    this.unreadCount,
    this.onTap,
    this.icon = Icons.notifications_outlined,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NotificationBadge(
        unreadCount: unreadCount,
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).iconTheme.color,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Navigation destination with notification badge
class NotificationNavigationDestination extends StatelessWidget {
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final int? unreadCount;

  const NotificationNavigationDestination({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: NotificationBadge(
        unreadCount: unreadCount,
        child: icon,
      ),
      selectedIcon: NotificationBadge(
        unreadCount: unreadCount,
        child: selectedIcon,
      ),
      label: label,
    );
  }
}
