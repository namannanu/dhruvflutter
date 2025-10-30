// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/communication.dart';
import 'package:talent/core/state/app_state.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  Map<NotificationType, bool> _preferences = {};
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  void _initializePreferences() {
    // Initialize with default preferences (all enabled)
    _preferences = {
      for (NotificationType type in NotificationType.values) type: true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _savePreferences,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage your notification preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which types of notifications you want to receive. Changes will be saved automatically.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPreferenceSection(),
                const SizedBox(height: 24),
                _buildAdditionalSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Types',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select which types of notifications you want to receive',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...NotificationType.values.map(
            (type) => _buildPreferenceTile(type),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(NotificationType type) {
    final isEnabled = _preferences[type] ?? true;
    final info = _getNotificationTypeInfo(type);

    return SwitchListTile(
      title: Text(info['title'] as String),
      subtitle: Text(info['description'] as String),
      value: isEnabled,
      onChanged: (value) {
        setState(() {
          _preferences[type] = value;
          _hasChanges = true;
        });
      },
      secondary: CircleAvatar(
        backgroundColor: (info['color'] as Color).withOpacity(0.1),
        child: Icon(
          info['icon'] as IconData,
          color: info['color'] as Color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildAdditionalSettings() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'General notification settings and controls',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.delete_sweep, color: Colors.white, size: 20),
            ),
            title: const Text('Clear all notifications'),
            subtitle: const Text('Remove all current notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearAllNotifications,
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            title: const Text('Refresh notifications'),
            subtitle: const Text('Check for new notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _refreshNotifications,
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.done_all, color: Colors.white, size: 20),
            ),
            title: const Text('Mark all as read'),
            subtitle: const Text('Mark all current notifications as read'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _markAllAsRead,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getNotificationTypeInfo(NotificationType type) {
    switch (type) {
      case NotificationType.application:
        return {
          'title': 'Job Applications',
          'description': 'New applications, status updates, and responses',
          'icon': Icons.assignment,
          'color': Colors.blue,
        };
      case NotificationType.hire:
        return {
          'title': 'Hiring & Team',
          'description': 'Team invitations, approvals, and hiring updates',
          'icon': Icons.person_add,
          'color': Colors.green,
        };
      case NotificationType.payment:
        return {
          'title': 'Payments',
          'description':
              'Payment confirmations, invoices, and financial updates',
          'icon': Icons.payment,
          'color': Colors.orange,
        };
      case NotificationType.schedule:
        return {
          'title': 'Schedule & Attendance',
          'description':
              'Shift updates, attendance reminders, and schedule changes',
          'icon': Icons.schedule,
          'color': Colors.purple,
        };
      case NotificationType.attendance:
        return {
          'title': 'Attendance',
          'description':
              'Clock-in/out confirmations, late arrivals, and attendance tracking',
          'icon': Icons.access_time,
          'color': Colors.indigo,
        };
      case NotificationType.message:
        return {
          'title': 'Messages',
          'description': 'New messages and conversation updates',
          'icon': Icons.message,
          'color': Colors.teal,
        };
      case NotificationType.system:
        return {
          'title': 'System Updates',
          'description':
              'App updates, maintenance, and important announcements',
          'icon': Icons.info,
          'color': Colors.grey,
        };
    }
  }

  Future<void> _savePreferences() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would save to the backend
      // For now, we'll just show a success message
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Clear notifications locally (in a real app, this would clear on backend too)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _refreshNotifications() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications refreshed'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _markAllAsRead() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.markNotificationsAsRead();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
