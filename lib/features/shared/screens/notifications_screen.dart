// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/communication.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/screens/notification_preferences_screen.dart';
import 'package:talent/features/shared/screens/message_notification_test_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationType? _selectedFilter;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final appState = Provider.of<AppState>(context, listen: false);
              switch (value) {
                case 'mark_all_read':
                  await appState.markNotificationsAsRead();
                  break;
                case 'refresh':
                  await appState.loadNotifications();
                  break;
                case 'preferences':
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationPreferencesScreen(),
                    ),
                  );
                  break;
                case 'test_messaging':
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const MessageNotificationTestScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'preferences',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Preferences'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_messaging',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Test Messaging'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<NotificationType?>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by type',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<NotificationType?>(
                        value: null,
                        child: Text('All notifications'),
                      ),
                      ...NotificationType.values.map(
                        (type) => DropdownMenuItem<NotificationType?>(
                          value: type,
                          child: Text(_getTypeDisplayName(type)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Unread only'),
                  selected: _showUnreadOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showUnreadOnly = selected;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Notifications list
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                List<AppNotification> notifications = appState.notifications;

                // Apply filters
                if (_selectedFilter != null) {
                  notifications = notifications
                      .where((n) => n.type == _selectedFilter)
                      .toList();
                }

                if (_showUnreadOnly) {
                  notifications =
                      notifications.where((n) => !n.isRead).toList();
                }

                // Sort by date (newest first)
                notifications
                    .sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showUnreadOnly
                              ? 'No unread notifications'
                              : _selectedFilter != null
                                  ? 'No ${_getTypeDisplayName(_selectedFilter!).toLowerCase()} notifications'
                                  : 'No notifications yet',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'New notifications will appear here',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => appState.loadNotifications(),
                  child: ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationTile(
                        notification: notification,
                        onTap: () =>
                            _handleNotificationTap(context, notification),
                        onMarkAsRead: () => _markAsRead(context, notification),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.application:
        return 'Applications';
      case NotificationType.hire:
        return 'Hires';
      case NotificationType.payment:
        return 'Payments';
      case NotificationType.schedule:
        return 'Schedule';
      case NotificationType.attendance:
        return 'Attendance';
      case NotificationType.message:
        return 'Messages';
      case NotificationType.system:
        return 'System';
    }
  }

  void _handleNotificationTap(
      BuildContext context, AppNotification notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      _markAsRead(context, notification);
    }

    // Handle action URL if present
    if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
      _launchUrl(notification.actionUrl!);
    } else {
      // Handle navigation based on notification type
      _navigateBasedOnType(context, notification);
    }
  }

  void _markAsRead(BuildContext context, AppNotification notification) {
    if (!notification.isRead) {
      Provider.of<AppState>(context, listen: false)
          .markNotificationsAsRead(notificationIds: [notification.id]);
    }
  }

  void _navigateBasedOnType(
      BuildContext context, AppNotification notification) {
    switch (notification.type) {
      case NotificationType.application:
        // Navigate to applications screen
        Navigator.of(context).pushNamed('/applications');
        break;
      case NotificationType.hire:
        // Navigate to team or jobs screen
        Navigator.of(context).pushNamed('/jobs');
        break;
      case NotificationType.message:
        // Navigate to messages
        Navigator.of(context).pushNamed('/messages');
        break;
      case NotificationType.schedule:
      case NotificationType.attendance:
        // Navigate to attendance/schedule
        Navigator.of(context).pushNamed('/attendance');
        break;
      case NotificationType.payment:
      case NotificationType.system:
        // Show details in a dialog or bottom sheet
        _showNotificationDetails(context, notification);
        break;
    }
  }

  void _showNotificationDetails(
      BuildContext context, AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    // For now, just show the URL in a dialog
    // In a real app, you would use url_launcher package
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('External Link'),
        content: Text('Open: $url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTypeColor(notification.type).withOpacity(0.1),
        child: Icon(
          _getTypeIcon(notification.type),
          color: _getTypeColor(notification.type),
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: notification.isRead ? Colors.grey[600] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.done, size: 16),
                  onPressed: onMarkAsRead,
                  tooltip: 'Mark as read',
                ),
              ],
            ),
      onTap: onTap,
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.application:
        return Colors.blue;
      case NotificationType.hire:
        return Colors.green;
      case NotificationType.payment:
        return Colors.orange;
      case NotificationType.schedule:
        return Colors.purple;
      case NotificationType.attendance:
        return Colors.indigo;
      case NotificationType.message:
        return Colors.teal;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.application:
        return Icons.assignment;
      case NotificationType.hire:
        return Icons.person_add;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.schedule:
        return Icons.schedule;
      case NotificationType.attendance:
        return Icons.access_time;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.system:
        return Icons.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
