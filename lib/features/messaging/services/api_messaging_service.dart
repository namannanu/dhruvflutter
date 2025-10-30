// ignore_for_file: avoid_print, directives_ordering

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/messaging/services/messaging_service.dart';
import 'package:talent/core/services/base/base_api_service.dart';

class ApiMessagingService extends BaseApiService implements MessagingService {
  ApiMessagingService({
    required super.baseUrl,
    super.enableLogging,
  });

  /// Always fetch the latest token from ServiceLocator
  String? get _authToken => ServiceLocator.instance.authToken;

  /// Get business_id from the current user's selectedBusinessId
  /// This eliminates the need to pass businessId as parameter for every API call
  String? get _currentUserBusinessId =>
      ServiceLocator.instance.currentUserBusinessId;

  @override
  Future<List<Conversation>> fetchConversations(String userId) async {
    try {
      const endpoint = 'api/conversations';
      final requestHeaders = headers(authToken: _authToken);

      logApiCall('GET', endpoint, headers: requestHeaders);

      final response = await client.get(
        resolve(endpoint),
        headers: requestHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load conversations: ${response.body}');
      }

      // Parse real API response
      final data = jsonDecode(response.body);
      final conversationsData = data['data'] as List? ?? [];

      return conversationsData
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  @override
  Future<List<Message>> fetchMessages(String conversationId) async {
    try {
      final endpoint = 'api/conversations/$conversationId/messages';
      final requestHeaders = headers(authToken: _authToken);

      logApiCall('GET', endpoint, headers: requestHeaders);

      final response = await client.get(
        resolve(endpoint),
        headers: requestHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load messages: ${response.body}');
      }

      // Parse real API response
      final data = jsonDecode(response.body);
      final messagesData = data['data'] as List? ?? [];

      return messagesData
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? attachmentUrl,
  }) async {
    try {
      final endpoint = 'api/conversations/$conversationId/messages';
      final requestHeaders = headers(authToken: _authToken);
      final body = {
        'body': content, // Backend expects 'body' not 'content'
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      };

      logApiCall('POST', endpoint, requestBody: body, headers: requestHeaders);

      final response = await client.post(
        resolve(endpoint),
        headers: requestHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to send message: ${response.body}');
      }

      // Parse real API response
      final data = jsonDecode(response.body);
      final messageData = data['data'] as Map<String, dynamic>;

      return Message.fromJson(messageData);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  @override
  Future<Conversation> createConversation({
    required String initiatorId,
    required String recipientId,
    String? initialMessage,
  }) async {
    try {
      const endpoint = 'api/conversations';
      final requestHeaders = headers(authToken: _authToken);
      final body = {
        'participants': [
          recipientId
        ], // Backend will add current user automatically
        if (initialMessage != null) 'initialMessage': initialMessage,
      };

      logApiCall('POST', endpoint, requestBody: body, headers: requestHeaders);

      final response = await client.post(
        resolve(endpoint),
        headers: requestHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to create conversation: ${response.body}');
      }

      // Parse real API response
      final data = jsonDecode(response.body);
      final conversationData = data['data'] as Map<String, dynamic>;

      return Conversation.fromJson(conversationData);
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  @override
  Future<List<AppNotification>> fetchNotifications(
    String userId, {
    String? businessId,
  }) async {
    try {
      const endpoint = 'api/notifications';
      final requestHeaders = headers(authToken: _authToken);

      // Auto-extract business_id from current user if not provided
      final resolvedBusinessId = businessId ?? _currentUserBusinessId;

      final query = <String, dynamic>{
        'userId': userId,
        if (resolvedBusinessId != null && resolvedBusinessId.isNotEmpty)
          'businessId': resolvedBusinessId,
      };

      logApiCall(
        'GET',
        endpoint,
        headers: requestHeaders,
        requestBody: query.isEmpty ? null : query,
      );

      final response = await client.get(
        resolveWithQuery(
          endpoint,
          query: query.isEmpty ? null : query,
        ),
        headers: requestHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load notifications: ${response.body}');
      }

      // Parse real API response
      final data = jsonDecode(response.body);
      final notificationsData = data['data'] as List? ?? [];

      return notificationsData
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  @override
  Future<void> markMessagesAsRead(
      {required String conversationId, required String userId}) async {
    try {
      final endpoint = 'api/conversations/$conversationId/read';
      final requestHeaders = headers(authToken: _authToken);
      final body = {'userId': userId};

      logApiCall('POST', endpoint, requestBody: body, headers: requestHeaders);

      final response = await client.post(
        resolve(endpoint),
        headers: requestHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markNotificationsAsRead(
      {required String userId, List<String>? notificationIds}) async {
    try {
      List<String> idsToMarkAsRead = [];

      // If no specific notification IDs are provided, get all unread notifications
      if (notificationIds == null || notificationIds.isEmpty) {
        debugPrint(
            'No notification IDs provided, fetching all unread notifications');

        // Get all notifications for the user
        const endpoint = 'api/notifications';
        final requestHeaders = headers(authToken: _authToken);

        final response = await client.get(
          resolve(endpoint),
          headers: requestHeaders,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final notifications = data['data'] as List<dynamic>? ?? [];

          // Filter for unread notifications (those without readAt field)
          idsToMarkAsRead = notifications
              .where((notif) => notif['readAt'] == null)
              .map((notif) => notif['_id'] as String)
              .toList();

          debugPrint(
              'Found ${idsToMarkAsRead.length} unread notifications to mark as read');
        } else {
          debugPrint('Failed to fetch notifications: ${response.statusCode}');
          return;
        }
      } else {
        idsToMarkAsRead = notificationIds;
      }

      // Mark each notification individually since the backend API requires
      // PATCH /api/notifications/:notificationId/read format
      int successCount = 0;
      int failureCount = 0;

      for (final notificationId in idsToMarkAsRead) {
        final endpoint = 'api/notifications/$notificationId/read';
        final requestHeaders = headers(authToken: _authToken);

        logApiCall('PATCH', endpoint, headers: requestHeaders);

        final response = await client.patch(
          resolve(endpoint),
          headers: requestHeaders,
        );

        if (response.statusCode != 200) {
          debugPrint(
              'Failed to mark notification $notificationId as read: ${response.body}');
          failureCount++;
        } else {
          debugPrint(
              'Successfully marked notification $notificationId as read');
          successCount++;
        }
      }

      debugPrint(
          'Notification marking summary: $successCount success, $failureCount failures out of ${idsToMarkAsRead.length} total');
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      // Don't rethrow to avoid breaking the app flow
    }
  }

  @override
  Future<void> updateNotificationPreferences(
      {required String userId,
      required Map<NotificationType, bool> preferences}) async {
    try {
      const endpoint = 'api/notifications/preferences';
      final requestHeaders = headers(authToken: _authToken);

      // Convert enum keys to strings for API
      final preferencesMap = <String, bool>{};
      preferences.forEach((type, enabled) {
        preferencesMap[type.toString().split('.').last] = enabled;
      });

      final body = {
        'userId': userId,
        'preferences': preferencesMap,
      };

      logApiCall('PUT', endpoint, requestBody: body, headers: requestHeaders);

      final response = await client.put(
        resolve(endpoint),
        headers: requestHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update notification preferences: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      rethrow;
    }
  }
}
