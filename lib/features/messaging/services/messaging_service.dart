import 'package:talent/core/models/models.dart';

abstract class MessagingService {
  /// Fetches all conversations for a user
  Future<List<Conversation>> fetchConversations(String userId);

  /// Fetches messages for a specific conversation
  Future<List<Message>> fetchMessages(String conversationId);

  /// Sends a new message in a conversation
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? attachmentUrl,
  });

  /// Creates a new conversation
  Future<Conversation> createConversation({
    required String initiatorId,
    required String recipientId,
    String? initialMessage,
  });

  /// Marks messages as read in a conversation
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  });

  /// Fetches notifications for a user. Some backends require a business context.
  Future<List<AppNotification>> fetchNotifications(
    String userId, {
    String? businessId,
  });

  /// Marks notifications as read
  Future<void> markNotificationsAsRead({
    required String userId,
    List<String>? notificationIds,
  });

  /// Updates notification preferences
  Future<void> updateNotificationPreferences({
    required String userId,
    required Map<NotificationType, bool> preferences,
  });
}
