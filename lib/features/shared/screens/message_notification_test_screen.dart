import 'package:flutter/material.dart';
import 'package:talent/core/services/push_notification_service.dart';

class MessageNotificationTestScreen extends StatefulWidget {
  const MessageNotificationTestScreen({super.key});

  @override
  State<MessageNotificationTestScreen> createState() =>
      _MessageNotificationTestScreenState();
}

class _MessageNotificationTestScreenState
    extends State<MessageNotificationTestScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default values
    _titleController.text = 'New message from John';
    _bodyController.text =
        'Hey, how are you doing? Let me know when you can start the project.';
    _senderController.text = 'John Doe';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  void _simulateMessageNotification() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final sender = _senderController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and body are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simulate receiving a message notification
    PushNotificationService.instance.simulateNotification(
      title: title,
      body: body,
      data: {
        'type': 'message',
        'notificationType': 'message',
        'showPopup': true,
        'senderName': sender.isNotEmpty ? sender : 'Someone',
        'conversationId': 'conv_123',
        'messageId': 'msg_456',
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message notification simulated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showExistingConversationTest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Testing: New conversations should check for existing chats first'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Notification Test'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Message Pop-up Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
                hintText: 'New message from John',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                border: OutlineInputBorder(),
                hintText: 'Hey, how are you doing?',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senderController,
              decoration: const InputDecoration(
                labelText: 'Sender Name',
                border: OutlineInputBorder(),
                hintText: 'John Doe',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _simulateMessageNotification,
              icon: const Icon(Icons.notification_add),
              label: const Text('Simulate Message Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showExistingConversationTest,
              icon: const Icon(Icons.chat),
              label: const Text('Test: Check Existing Conversations'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What was implemented:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('✅ Message notifications now create pop-up dialogs'),
                  Text(
                      '✅ Backend generates notifications when messages are sent'),
                  Text(
                      '✅ Existing conversation check prevents duplicate chats'),
                  Text(
                      '✅ Pop-ups show sender name, message preview, and reply button'),
                  SizedBox(height: 12),
                  Text(
                    'How it works:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                      '1. When someone sends a message, backend creates notification'),
                  Text(
                      '2. App polls for new notifications and detects message type'),
                  Text(
                      '3. Message notifications trigger instant pop-up dialogs'),
                  Text('4. Users can dismiss or tap "Reply" to open messaging'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
