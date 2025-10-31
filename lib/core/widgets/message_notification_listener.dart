// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/screens/messaging_screen.dart';

class MessageNotificationListener extends StatefulWidget {
  final Widget child;

  const MessageNotificationListener({
    super.key,
    required this.child,
  });

  @override
  State<MessageNotificationListener> createState() =>
      _MessageNotificationListenerState();
}

class _MessageNotificationListenerState
    extends State<MessageNotificationListener> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Check for pending message notifications
        if (appState.pendingMessageNotification != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMessageNotificationDialog(
                context, appState.pendingMessageNotification!);
            appState.clearPendingMessageNotification();
          });
        }

        return widget.child;
      },
    );
  }

  void _showMessageNotificationDialog(
      BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.message,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (notification['title'] as String?) ?? 'New Message',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'From ${(notification['senderName'] as String?) ?? 'Someone'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    (notification['body'] as String?) ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Dismiss'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Navigate to messaging screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MessagingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Reply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
