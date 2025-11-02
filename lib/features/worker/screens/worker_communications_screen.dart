import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/widgets/section_header.dart';

class WorkerCommunicationsScreen extends StatefulWidget {
  const WorkerCommunicationsScreen({super.key});

  @override
  State<WorkerCommunicationsScreen> createState() =>
      _WorkerCommunicationsScreenState();
}

class _WorkerCommunicationsScreenState
    extends State<WorkerCommunicationsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final notifications = appState.notifications;
    final conversations = appState.conversations;

    return RefreshIndicator(
      onRefresh: () async {
        final state = context.read<AppState>();
        await state.loadNotifications();
        await state.loadConversations();
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Notifications',
            subtitle:
                'System alerts, application updates, and schedule changes', style: TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 16),
          if (notifications.isEmpty)
            const Text('No notifications right now.')
          else
            ...notifications.map(
              (notification) => _NotificationTile(notification: notification),
            ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Inbox',
            subtitle: 'Keep conversations going with employers', style: TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 16),
          if (conversations.isEmpty)
            const Text(
              'No conversations yet. Apply to jobs to open chat threads.',
            )
          else
            ...conversations.map(
              (conversation) => Card(
                child: ListTile(
                  title: Text(conversation.title),
                  subtitle: Text(conversation.lastMessagePreview),
                  trailing: conversation.unreadCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        )
                      : null,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Attach to GET /conversations/{id}/messages to open chat.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d · HH:mm');

    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.application:
        icon = Icons.assignment_turned_in_outlined;
        color = theme.colorScheme.primary;
        break;
      case NotificationType.hire:
        icon = Icons.celebration_outlined;
        color = theme.colorScheme.secondary;
        break;
      case NotificationType.payment:
        icon = Icons.credit_card;
        color = theme.colorScheme.tertiary;
        break;
      case NotificationType.schedule:
        icon = Icons.schedule;
        color = theme.colorScheme.primary;
        break;
      case NotificationType.message:
        icon = Icons.mail_outline;
        color = theme.colorScheme.secondary;
        break;
      case NotificationType.system:
        icon = Icons.notifications_active_outlined;
        color = theme.colorScheme.secondaryContainer;
        break;
      case NotificationType.attendance:
        icon = Icons.access_time;
        color = theme.colorScheme.primaryContainer;
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(notification.title, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              formatter.format(notification.createdAt),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
