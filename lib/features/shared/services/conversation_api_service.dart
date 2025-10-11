import 'dart:convert';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/http_service.dart';

class ConversationApiService {
  final HttpService _httpService = HttpService();

  // Get all conversations for the current user
  Future<List<Conversation>> getConversations({String? jobId}) async {
    try {
      final queryParams = jobId != null ? {'jobId': jobId} : null;
      final response = await _httpService.get('/api/conversations', queryParams: queryParams);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversations = data['data'];
        
        if (conversations is List) {
          return conversations.map((json) => Conversation.fromJson(json as Map<String, dynamic>)).toList();
        }
        
        return <Conversation>[];
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error loading conversations: $error');
    }
  }

  // Create a new conversation
  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? jobId,
  }) async {
    try {
      final response = await _httpService.post(
        '/api/conversations',
        body: {
          'participants': participantIds,
          if (jobId != null) 'job': jobId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Conversation.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create conversation');
      }
    } catch (error) {
      throw Exception('Error creating conversation: $error');
    }
  }

  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _httpService.get('/api/conversations/$conversationId/messages');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['data'];
        
        if (messages is List) {
          return messages.map((json) => Message.fromJson(json as Map<String, dynamic>)).toList();
        }
        
        return <Message>[];
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error loading messages: $error');
    }
  }

  // Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    try {
      final response = await _httpService.post(
        '/api/conversations/$conversationId/messages',
        body: {
          'body': body,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send message');
      }
    } catch (error) {
      throw Exception('Error sending message: $error');
    }
  }

  // Mark conversation as read
  Future<void> markConversationRead(String conversationId) async {
    try {
      final response = await _httpService.patch('/api/conversations/$conversationId/read');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to mark conversation as read');
      }
    } catch (error) {
      throw Exception('Error marking conversation as read: $error');
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      final conversations = await getConversations();
      int totalUnread = 0;
      
      for (final conversation in conversations) {
        totalUnread += conversation.unreadCount;
      }
      
      return totalUnread;
    } catch (error) {
      throw Exception('Error getting unread message count: $error');
    }
  }
}