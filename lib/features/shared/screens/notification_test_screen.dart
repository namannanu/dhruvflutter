import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'attendance';
  String _selectedPriority = 'medium';

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Test Notification';
    _messageController.text = 'This is a test notification to verify the system works.';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Test Notification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Message',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                              DropdownMenuItem(value: 'team_update', child: Text('Team Update')),
                              DropdownMenuItem(value: 'system', child: Text('System')),
                              DropdownMenuItem(value: 'application', child: Text('Application')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _sendTestNotification,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Test Notification'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Tests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildQuickTestButton(
                      'Clock-in Notification',
                      'You clocked in at 9:00 AM for Marketing Assistant',
                      'attendance',
                      'low',
                      Icons.access_time,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildQuickTestButton(
                      'Late Clock-in',
                      'You clocked in late at 9:15 AM. Please be on time for future shifts.',
                      'attendance',
                      'medium',
                      Icons.schedule_outlined,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildQuickTestButton(
                      'Team Invitation',
                      'John Smith invited you to join ABC Company as Manager.',
                      'team_update',
                      'medium',
                      Icons.group_add,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildQuickTestButton(
                      'Push Notification Test',
                      null,
                      null,
                      null,
                      Icons.notifications_active,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButton(
    String title,
    String? message,
    String? type,
    String? priority,
    IconData icon,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        if (message != null) {
          _sendQuickNotification(title, message, type!, priority!);
        } else {
          _sendPushNotificationTest();
        }
      },
      icon: Icon(icon, color: color),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // For now, just simulate a notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent: ${_titleController.text}'),
          backgroundColor: Colors.green,
        ),
      );

      // Trigger notification refresh
      await appState.loadNotifications();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendQuickNotification(String title, String message, String type, String priority) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick test sent: $title'),
          backgroundColor: Colors.green,
        ),
      );

      // Trigger notification refresh
      await appState.loadNotifications();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send quick notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendPushNotificationTest() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Send a test push notification
      await appState.sendTestNotification();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Push notification test sent!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send push notification test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}